Sequel.migration do
  up do
    puts('Creating package body BUS_DAYS_P')
    run(<<~SQL)
      create or replace function div_mod(i_num in integer, i_div in integer, o_quotient out integer, o_remainder out integer) returns void as $$
      declare
        o_quotient integer;
        o_remainder integer;
      begin
        o_quotient := floor(i_num / i_div);
        o_remainder := mod(i_num, i_div);
      end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function get_easter(i_year in integer) returns date as $$
      declare
        l_year integer := case when i_year < 100 then i_year + 2000 else i_year end;
        l_a integer := mod(l_year, 19);
        l_b integer := floor(l_year / 100);
        l_c integer := mod(l_year, 100);
        l_d integer := floor(l_b / 4);
        l_e integer := mod(l_b, 4);
        l_f integer := floor((l_b + 8) / 25);
        l_g integer := floor((l_b - l_f + 1) / 3);
        l_h integer := mod(19 * l_a + l_b - l_d - l_g + 15, 30);
        l_i integer := floor(l_c / 4);
        l_k integer := mod(l_c, 4);
        l_l integer := mod(32 + 2 * l_e + 2 * l_i - l_h - l_k, 7);
        l_m integer := floor((l_a + 11 * l_h + 22 * l_l)/451);
        l_o integer := l_h + l_l - 7 * l_m + 114;
        l_n integer := floor(l_o / 31);
        l_p integer := mod(l_o, 31);
      begin
        if l_year < 1538 then
          raise error 'Cannot calculate easter date prior to 1538 with this function';
        end if;

        return to_date(to_char(l_year,'9999') || to_char(l_n,'09') || to_char(l_p + 1,'09'),'yyyymmdd');
      end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function is_holiday(i_date in date, i_location in varchar) returns boolean as $$
      declare
        l_count integer := 0;
      begin
        select count(0) into l_count
        from holidays
        where holiday = i_date
        and location = i_location;

        case l_count when 0 then return false; else return true; end case;
      end;
      $$ language plpgsql;
    SQL

    run(<<~SQL)
      create or replace function roll_hol(i_date in date, i_roll in varchar, i_location in varchar) returns date as $$
      declare
        l_day integer := to_number(to_char(i_date,'id'),'9');
        l_date date := i_date;
      begin
        case
        -- its a week day, so no need to roll --
        when l_day < 6 then return l_date;
        -- Sat->Fri, Sun->Mon --
        when i_roll = 'FM' then return l_date + sign(l_day - 6.5);
        -- both Sat and Sun -> Mon --
        when i_roll = 'M' then
          l_date := l_date + (8 - l_day);
          -- need to check here for rolling consecutive holidays (christmas and boxing day, to move boxing day on an extra day)
          case when is_holiday(l_date, i_location) then return l_date + 1; else return l_date; end case;
        -- Only sunday rolls --
        when i_roll = 'SO' then return l_date + (l_day - 6);
        else
          raise exception 'Unknown roll option';
        end case;
      end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function next_day(i_date in date, i_day in varchar) returns date as $$
      declare
        l_dow integer := extract(dow from i_date);
        n_dow integer := select array_position(array['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'], i_day);
      begin
        case
        when l_dow = n_dow then return i_date + 7;
        when l_dow < n_dow then return i_date + 7 - (l_dow - n_dow);
        else return i_date + (n_dow - l_dow);
        end case;
      end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function generate_holidays(i_year in integer, i_location in varchar) returns void as $$
      declare
        l_date  date;
        l_year  integer := i_year;

        cHols cursor for
          select * from holiday_rules
          where location = i_location;
      begin
        for c1 in cHols loop

          l_date := to_date(to_char(l_year,'9999') || to_char(c1.hol_month,'09') || to_char(coalesce(c1.hol_date,1),'09'),'yyyymmdd');
          case
            when c1.hol_date is not null then
              l_date := roll_hol(l_date, c1.roll, i_location);
            when c1.occur > 0 then
              l_date := l_date - 1; -- get last day of prev month
              l_date := next_day(l_date, c1.hol_day) + (c1.occur - 1) * 7;                          -- get first occur of day, then add additional weeks to get nth occur
            when c1.occur < 0 then
              l_date := to_date(to_char(l_year,'9999') || to_char(c1.hol_month,'09') || '01','yyyymmdd');  -- get last day of month
              l_date := next_day(l_date, c1.hol_day) + c1.occur * 7;                                -- get first occur of day in next month, then subtract weeks to get -nth occurence
            when c1.hol_function is not null then
              execute immediate(c1.hol_function) into l_date using l_year;
            else
              raise exception 'invalid holiday rule';
          end case;

          insert into holidays(location, name, year, holiday)
          select c1.location, c1.name, l_year, l_date
          where (c1.location, c1.name, l_year) not in (select location, name, year from holidays);
        end loop;
      end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function is_weekend(i_date in date) returns boolean as $$
        begin
          -- days 1-5 = M-F, 6-7 = Sat-Sun --
          if to_number(to_char(i_date,'id')) < 6 then
            return false;
          else
            return true;
          end if;
        end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function get_day_hours(i_start_ts in date, i_end_ts in date) returns numeric as $$
      declare
        k_bus_start numeric :=  9/24;
        k_bus_end   numeric := 17/24;
      begin
        return least(i_end_ts, trunc(i_end_ts) + k_bus_end) - greatest(i_start_ts, trunc(i_start_ts) + k_bus_start);
      end;
      $$ language plpgsql
    SQL

    run(<<~SQL)
      create or replace function get_elapsed_time(i_date in date, i_time in numeric default null) returns numeric as $$
          l_time numeric := 0;
          l_end_ts date := trunc(i_date) + 1 - 1/86400; -- set to 23:59:59 --
          l_start_ts date := i_date;
        begin
          -- if elapsed time is already calculated then just return it --
          if i_time is not null then
            return i_time;
          end if;

          for i in 1 .. ceil(sysdate - trunc(i_date)) loop
            if not (is_weekend(l_start_ts) or is_holiday(l_start_ts)) then
              l_time := l_time + get_day_hours(l_start_ts, l_end_ts);
            end if;
            -- set start and end times from the next day --
            l_start_ts := trunc(l_start_ts) + 1;
            l_end_ts := least(sysdate, l_end_ts + 1);
          end loop;

          return l_time;
        end get_elapsed_time;

      end;
      $$ language plpgsql
    SQL
  end

  down do
    puts('Dropping functions')
    run('drop function div_mod')
    run('drop function get_easter')
    run('drop function is_holiday')
    run('drop function roll_hol')
    run('drop function next_day')
    run('drop function generate_holidays')
    run('drop function is_weekend')
    run('drop function get_day_hours')
    run('drop function get_elapsed_time')
  end
end
