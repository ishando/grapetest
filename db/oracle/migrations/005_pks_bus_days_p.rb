Sequel.migration do
  up do
    puts('Creating package BUS_DAYS_P')
    run(<<~SQL)
      create or replace package bus_days_p
      as
        function get_easter(i_year in integer) return date;
        function is_holiday(i_date in date) return boolean;
        function is_holiday(i_date in date, i_location in varchar2) return boolean;
        function is_weekend(i_date in date) return boolean;

        function get_elapsed_time(i_date in date, i_time in number default null) return number;

        procedure generate_holidays(i_year in pls_integer, i_location in varchar2 default null);
      end bus_days_p;
    SQL
  end

  down do
    puts('Dropping package BUS_DAYS_P')
    run('drop package bus_days_p')
  end
end
