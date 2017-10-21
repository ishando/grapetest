Sequel.migration do
  up do
    puts('Creating package HOLIDAYS_P')
    run(<<~SQL)
      create or replace package holidays_p
      as
        function get_easter(i_year in integer) return date;
        function is_holiday(i_date in date) return boolean;

        procedure generate_holidays(i_year in pls_integer, i_location in varchar2 default null);
      end holidays_p;
    SQL
  end

  down do
    puts('Dropping package HOLIDAYS_P')
    run('drop package holidays_p')
  end
end
