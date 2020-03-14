Sequel.migration do
  up do
    puts('Creating table DAY_IS_HOLIDAY')
    create_table(:day_is_holiday) do
      Date       :day,   null: false
      Text       :location, null: false
      Boolean    :is_hol, null: false, default: false
      index :day, unique: true
    end
  end

  down do
    puts('Dropping table DAY_IS_HOLIDAY')
    drop_table(:day_is_holiday)
  end
end
