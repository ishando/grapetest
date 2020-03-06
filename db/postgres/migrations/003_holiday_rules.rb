Sequel.migration do
  up do
    puts('Creating table HOLIDAY_RULES')
    create_table(:holiday_rules) do
      primary_key :id
      String     :location,      size: 32, null: false
      String     :name,          size: 32, null: false
      Integer    :hol_month
      Integer    :hol_date
      String     :hol_day,       size: 12
      Integer    :occur
      String     :roll,          size: 10
      String     :hol_function,  size: 30
    end

    run <<~SQL
      insert into holiday_rules(location, name, hol_month, hol_date, hol_day, occur, roll)
      select 'USA', name, hol_month, hol_date, hol_day, occur, roll
      from (
        select 'New Year' as name, 1 hol_month, 1 hol_date, null hol_day, null occur, 'FM' roll union all
        select 'Martin Luther King', 1, null, 'Monday', 3, null union all
        select 'Washington',   2,  null, 'Monday',   3,    null union all
        select 'Memorial',     5,  null, 'Monday',   -1,   null union all
        select 'Independence', 7,  4,    null,       null, 'FM' union all
        select 'Labor',        9,  null, 'Monday',   1,    null union all
        select 'Colombus',     10, null, 'Monday',   2,    null union all
        select 'Veterans',     11, 11,   null,       null, 'FM' union all
        select 'Thanksgiving', 11, null, 'Thursday', 4,    null union all
        select 'Christmas',    12, 25,   null,       null, 'FM'
      ) h
    SQL

    run <<~SQL
      insert into holiday_rules(location, name, hol_month, hol_date, hol_day, occur, roll, hol_function)
      select loc, name, hol_month, hol_date, hol_day, occur, roll, hol_function
      from (
        select 'AU' loc, 'New Year' as name, 1 hol_month, 1 hol_date, null::text hol_day, null::integer occur, 'M' roll, null::text hol_function union all
        select 'AU', 'Australia Day',           1,   26, null,   null, 'FM', null union all
        select 'AU', 'Good Friday',          null, null, null,   null, null, format('get_easter(%s) - 2', extract(year from current_date)) union all
        select 'AU', 'Easter Monday',        null, null, null,   null, null, format('get_easter(%s) + 2', extract(year from current_date)) union all
        select 'AU', 'Anzac Day',               4,   25, null,   null, 'SO', null union all
        select 'AU', 'Queens Birthday',         6, null, 'Monday',  2, null, null union all
        select 'AU', 'Christmas',              12,   25, null,   null, 'FM', null union all
        select 'AU-ACT', 'Canberra Day',        3, null, 'Monday',  2, null, null union all
        select 'AU-ACT', 'Reconciliation Day',  5,   26, 'Monday',  1, null, null union all
        select 'AU-ACT', 'Queens Birthday',     6, null, 'Monday',  2, null, null union all
        select 'AU-ACT', 'Labour Day',         10, null, 'Monday',  1, null, null union all
        select 'AU-NSW', 'Anzac Day',           4,   25, null,   null, null, null union all
        select 'AU-NSW', 'Queens Birthday',     6, null, 'Monday',  2, null, null union all
        select 'AU-NSW', 'August Bank Holiday', 8, null, 'Monday',  1, null, null union all
        select 'AU-NSW', 'Labour Day',         10, null, 'Monday',  1, null, null union all
        select 'AU-NT', 'May Day',              5, null, 'Monday',  1, null, null union all
        select 'AU-NT', 'Queens Birthday',      6, null, 'Monday',  2, null, null union all
        select 'AU-NT', 'Picnic Day',           8, null, 'Monday',  1, null, null union all
        select 'AU-NT', 'New Year Eve',        12,   31, null,   null, null, null union all
        select 'AU-QLD', 'Labour Day',          5, null, 'Monday',  1, null, null union all
        select 'AU-QLD', 'Queens Birthday',    10, null, 'Monday',  1, null, null union all
        select 'AU-SA', 'Adelaide Cup Day',     3, null, 'Monday',  2, null, null union all
        select 'AU-SA', 'Queens Birthday',      6, null, 'Monday',  2, null, null union all
        select 'AU-SA', 'Labour Day',          10, null, 'Monday',  1, null, null union all
        select 'AU-SA', 'New Year Eve',        12,   31, null,   null, null, null union all
        select 'AU-TAS', 'Eight Hours Day',     3, null, 'Monday',  2, null, null union all
        select 'AU-TAS', 'Queens Birthday',     6, null, 'Monday',  2, null, null union all
        select 'AU-VIC', 'Labour Day',          3, null, 'Monday',  2, null, null union all
        select 'AU-VIC', 'Queens Birthday',     6, null, 'Monday',  2, null, null union all
        select 'AU-VIC', 'Grand Final Friday',  9, null, 'Friday', -1, null, null union all
        select 'AU-VIC', 'Melbourne Cup',      11, null, 'Tuesday', 2, null, null union all
        select 'AU-WA', 'Labour Day',           3, null, 'Monday',  2, null, null union all
        select 'AU-WA', 'Anzac Day',            4,   25, null,   null,  'M', null union all
        select 'AU-WA', 'WA Day',               6, null, 'Monday',  1, null, null union all
        select 'AU-WA', 'Queens Birthday',      9, null, 'Monday', -1, null, null
      ) h
    SQL
  end

  down do
    puts('Dropping table HOLIDAY_RULES')
    drop_table(:holiday_rules)
  end
end
