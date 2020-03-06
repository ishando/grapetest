Sequel.migration do
  up do
    puts('Creating table HOLIDAYS')
    create_table(:holidays) do
      primary_key :id
      String     :location,  size: 32, null: false
      String     :name,      size: 32, null: false
      Integer    :year,      null: false
      Date       :holiday,   null: false
    end
  end

  down do
    puts('Dropping table HOLIDAYS')
    drop_table(:holidays)
  end
end
