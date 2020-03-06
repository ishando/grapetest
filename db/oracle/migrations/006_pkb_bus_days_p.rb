Sequel.migration do
  up do
    puts('Creating package body BUS_DAYS_P')
    run(<<~SQL)
      create or replace package body bus_days_p
      as
        type   t_hols_tab is table of boolean index by varchar2(8);
        type   t_loc_tab is table of t_hols_tab index by varchar2(10);
        g_hols t_loc_tab;

        -----------------------------------------
        procedure div_mod(i_num in pls_integer, i_div in pls_integer, o_int out pls_integer, o_mod out pls_integer)
        is
        begin
          o_int := floor(i_num / i_div);
          o_mod := mod(i_num, i_div);
        end div_mod;

        -----------------------------------------
        function get_easter(i_year in integer)
          return date
        as
          l_year  pls_integer := i_year;
          l_a pls_integer;
          l_b pls_integer;
          l_c pls_integer;
          l_d pls_integer;
          l_e pls_integer;
          l_f pls_integer;
          l_g pls_integer;
          l_h pls_integer;
          l_i pls_integer;
          l_k pls_integer;
          l_l pls_integer;
          l_m pls_integer;
          l_n pls_integer;
          l_p pls_integer;
        begin
          if l_year < 100 then
            l_year := l_year + 2000;
          end if;
          if l_year < 1538 then
            raise_application_error(-20001, 'Cannot calculate easter date prior to 1538 with this function');
          end if;

          l_a := mod(l_year, 19);
          div_mod(l_year, 100, l_b, l_c);
          div_mod(l_b, 4, l_d, l_e);
          l_f := floor((l_b + 8) / 25);
          l_g := floor((l_b - l_f + 1) / 3);
          l_h := mod(19 * l_a + l_b - l_d - l_g + 15, 30);
          div_mod(l_c, 4, l_i, l_k);
          l_l := mod(32 + 2 * l_e + 2 * l_i - l_h - l_k, 7);
          l_m := floor((l_a + 11 * l_h + 22 * l_l)/451);
          div_mod(l_h + l_l - 7 * l_m + 114, 31, l_n, l_p);

          return to_date(to_char(l_year,'9999') || to_char(l_n,'09') || to_char(l_p + 1,'09'),'yyyymmdd');
        end get_easter;

        -----------------------------------------
        function is_holiday(i_date in date)
          return boolean
        is
          l_count pls_integer := 0;
        begin
          select count(0) into l_count
          from holidays
          where holiday = i_date;

          if l_count = 0 then
            return false;
          else
            return true;
          end if;
        end is_holiday;

        function is_holiday(i_date in date, i_location in varchar2)
          return boolean
        is
          l_indx  varchar2(8) := to_char(i_date,'yyyymmdd');
        begin
          if g_hols.exists(i_location) and g_hols(i_location).exists(l_indx) then
            return g_hols(i_location)(l_indx);
          else
            set_holidays(i_date, i_location);
            return g_hols(i_location)(l_indx);
          end if;
        end is_holiday;

        -----------------------------------------
        function roll_hol(i_date in date, i_roll in varchar2)
          return date
        is
          l_day pls_integer := to_number(to_char(i_date,'d'));
          l_date date := i_date;
        begin
          if l_day < 6 then -- its a week day, so no need to roll --
            return l_date;
          elsif i_roll = 'FM' then  -- Sat->Fri, Sun->Mon --
            return l_date + sign(l_day - 6.5);
          elsif i_roll = 'M' then -- both Sat and Sun -> Mon --
            l_date := l_date + (8 - l_day);
            -- need to check here for rolling consecutive holidays (christmas and boxing day, to move boxing day on an extra day)
            if is_holiday(l_date) then
              return l_date + 1;
            else
              return l_date;
            end if;
          elsif i_roll = 'SO' then -- Only sunday rolls --
            return l_date + (l_day - 6);
          else
            raise_application_error(-20004, 'Unknown roll option');
          end if;
        end roll_hol;

        function roll_hol(i_date in date, i_roll in varchar2, i_location in varchar2)
          return date
        is
          l_day pls_integer := to_number(to_char(i_date,'d'));
          l_date date := i_date;
        begin
          if i_roll is null then  -- no roll rule set so just return given date --
            return l_date;
          elsif l_day < 6 then -- its a week day, so no need to roll --
            return l_date;
          elsif i_roll = 'BF' then  -- roll Sat back to Fri, and Sun forwards Mon --
            return l_date + sign(l_day - 6.5);
          elsif i_roll = 'F' then -- roll both Sat and Sun forward to Mon --
            l_date := l_date + (8 - l_day);
            -- need to check here for rolling consecutive holidays (e.g. christmas and boxing day, to move boxing day on an extra day)
            if is_holiday(l_date, i_location) then
              return l_date + 1;
            else
              return l_date;
            end if;
          elsif i_roll = 'SO' then -- Only roll Sunday forwards --
            return l_date + (l_day - 6);
          else
            raise_application_error(-20004, 'Unknown roll option');
          end if;
        end roll_hol;

        -----------------------------------------
        procedure set_holidays(i_date in date, i_location in varchar2)
        is
          l_date  date;
          l_year  pls_integer := extract(year from i_date);
          l_range pls_integer := 5;
          l_indx  varchar2(8);
          -- check for holidays around the date of interest to account for rolling holidays
          m1 pls_integer := extract(month from i_date - 7);
          m2 pls_integer := extract(month from i_date + 7);

          cursor cHols is
            select * from holiday_rules
            where location = i_location
            and hol_month in (m1, m2);

          cursor cDts is
            select i_date - l_range + level - 1 as test_dt from dual connect by level <= l_range * 2 + 1;
        begin
          for cd in cDts loop
            l_indx := to_char(cd.test_dt,'yyyymmdd');
            if g_hols.exists(i_location) and g_hols(i_location).exists(l_indx) then
              continue;
            end if;
            g_hols(i_location)(l_indx) := false;
          end loop;

          for c1 in cHols loop
            if c1.hol_month = m2 and m2 < m1 then
              l_year := extract(year from i_date) + 1;
            else
              l_year := extract(year from i_date);
            end if;

            if c1.hol_date is not null then
              l_date := to_date(to_char(l_year) || to_char(c1.hol_month,'09') || to_char(c1.hol_date,'09'),'yyyymmdd');
              l_date := roll_hol(l_date, c1.roll, i_location);
            elsif c1.occur > 0 then
              l_date := to_date(to_char(l_year) || to_char(c1.hol_month,'09') || '01','yyyymmdd') - 1; -- get last day of prev month
              l_date := next_day(l_date, c1.hol_day) + (c1.occur - 1) * 7;                             -- get first occur of day, then add additional weeks to get nth occur
            elsif c1.occur < 0 then
              l_date := last_day(to_date(to_char(l_year) || to_char(c1.hol_month,'09') || '01','yyyymmdd')); -- get last day of month
              l_date := next_day(l_date, c1.hol_day) + c1.occur * 7;                                         -- get first occur of day in next month, then subtract weeks to get -nth occurence
            elsif c1.hol_function is not null then
              execute immediate(c1.hol_function) into l_date using l_year;
            else
              raise_application_error(-20003, 'invalid holiday rule');
            end if;

            l_indx := to_char(l_date,'yyyymmdd');
            g_hols(i_location)(l_indx) := true;
          end loop;
        end set_holidays;

        -----------------------------------------
        procedure generate_holidays(i_year in pls_integer, i_location in varchar2 default null)
        is
          cursor cHolRules is
            select * from holiday_rules hr
            where not exists (
              select 1 from holidays h
              where h.location = hr.location and h.name = hr.name and h.year = i_year
            )
            and (hr.location = i_location or i_location is null);
          l_date date;
          l_year pls_integer := i_year;
        begin
          if i_year < 100 then
            l_year := i_year + 2000;
          end if;
          if l_year < to_number(to_char(sysdate,'yyyy')) - 10 or l_year > to_number(to_char(sysdate,'yyyy')) + 10 then
            raise_application_error(-20002, 'Unexpected year given');
          end if;

          for c1 in cHolRules loop
            if c1.hol_date is not null then
              l_date := to_date(to_char(l_year) || to_char(c1.hol_month,'09') || to_char(c1.hol_date,'09'),'yyyymmdd');
              l_date := roll_hol(l_date, c1.roll);
            elsif c1.occur > 0 then
              l_date := to_date(to_char(l_year) || to_char(c1.hol_month,'09') || '01','yyyymmdd') - 1; -- get last day of prev month
              l_date := next_day(l_date, c1.hol_day) + (c1.occur - 1) * 7;                             -- get first occur of day, then add additional weeks to get nth occur
            elsif c1.occur < 0 then
              l_date := last_day(to_date(to_char(i_year) || to_char(c1.hol_month,'09') || '01','yyyymmdd')); -- get last day of month
              l_date := next_day(l_date, c1.hol_day) + c1.occur * 7;                                         -- get first occur of day in next month, then subtract weeks to get -nth occurence
            elsif c1.hol_function is not null then
              execute immediate(c1.hol_function) into l_date using l_year;
            else
              raise_application_error(-20003, 'invalid holiday rule');
            end if;
            insert into holidays(id, location, name, year, holiday)
            values (seq_holidays_id.nextval, c1.location, c1.name, l_year, l_date);
          end loop;
          commit;
        exception
          when others then
            rollback;
            raise;
        end generate_holidays;

        function is_weekend(i_date in date)
          return boolean
        is
        begin
          -- days 1-5 = M-F, 6-7 = Sat-Sun --
          if to_number(to_char(i_date,'d')) < 6 then
            return false;
          else
            return true;
          end if;
        end is_weekend;

        -----------------------------------------
        function get_day_hours(i_start_ts in date, i_end_ts in date)
          return number
        is
          k_bus_start number :=  9/24;
          k_bus_end   number := 17/24;
        begin
          return least(i_end_ts, trunc(i_end_ts) + k_bus_end) - greatest(i_start_ts, trunc(i_start_ts) + k_bus_start);
        end get_day_hours;

        -----------------------------------------
        function get_elapsed_time(i_date in date, i_time in number default null)
          return number
        is
          l_time number := 0;
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

      end bus_days_p;
    SQL
  end

  down do
    puts('Dropping package body BUS_DAYS_P')
    run('drop package body bus_days_p')
  end
end
