Sequel.migration do
  up do
    puts('Creating table HOLIDAY_RULES')
    create_table(:holiday_rules) do
      primary_key :id
      String     :location,     size: 32, null: false
      String     :name,         size: 32, null: false
      Integer    :hol_month,    null: false
      Integer    :hol_date
      String     :hol_day,      size: 12
      Integer    :occur
      String     :roll,         size: 10
      String     :hol_function,  size: 30
    end

    run <<~SQL
      insert into holiday_rules(id, location, name, hol_month, hol_date, hol_day, occur, roll)
      select seq_holiday_rules_id.nextval, 'USA', name, hol_month, hol_date, hol_day, occur, roll
      from (
        select 'New Year' name, 1 hol_month, 1 hol_date, null hol_day, null occur, 'FM' roll from dual union all
        select 'Martin Luther King', 1, null, 'Monday', 3, null from dual union all
        select 'Washington',   2,  null, 'Monday',   3,    null from dual union all
        select 'Memorial',     5,  null, 'Monday',   -1,   null from dual union all
        select 'Independence', 7,  4,    null,       null, 'FM' from dual union all
        select 'Labor',        9,  null, 'Monday',   1,    null from dual union all
        select 'Colombus',     10, null, 'Monday',   2,    null from dual union all
        select 'Veterans',     11, 11,   null,       null, 'FM' from dual union all
        select 'Thanksgiving', 11, null, 'Thursday', 4,    null from dual union all
        select 'Christmas',    12, 25,   null,       null, 'FM' from dual
      )
    SQL
  end

  down do
    puts('Dropping table HOLIDAY_RULES')
    drop_table(:holiday_rules)
  end
end
