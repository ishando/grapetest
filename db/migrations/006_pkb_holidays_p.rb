Sequel.migration do
  up do
    puts('Creating package body HOLIDAYS_P')
    run(<<~SQL)
      create or replace package body holidays_p
      as
        -----------------------------------------
        procedure div_parts(i_num in pls_integer, i_div in pls_integer, o_int out pls_integer, o_mod out pls_integer)
        is
        begin
          o_int := floor(i_num / i_div);
          o_mod := mod(i_num, i_div);
        end div_parts;

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
          div_parts(l_year, 100, l_b, l_c);
          div_parts(l_b, 4, l_d, l_e);
          l_f := floor((l_b + 8) / 25);
          l_g := floor((l_b - l_f + 1) / 3);
          l_h := mod(19 * l_a + l_b - l_d - l_g + 15, 30);
          div_parts(l_c, 4, l_i, l_k);
          l_l := mod(32 + 2 * l_e + 2 * l_i - l_h - l_k, 7);
          l_m := floor((l_a + 11 * l_h + 22 * l_l)/451);
          div_parts(l_h + l_l - 7 * l_m + 114, 31, l_n, l_p);

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
      end holidays_p;
    SQL
  end

  down do
    puts('Dropping package body HOLIDAYS_P')
    run('drop package body holidays_p')
  end
end
