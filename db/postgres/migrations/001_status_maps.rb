Sequel.migration do
  up do
    puts('Creating table STATUS_MAPS')
    create_table(:status_maps) do
      primary_key :id
      String :category,   size: 32, null: false
      String :event_type, size: 32, null: false
    end
  end

  down do
    puts('Dropping table STATUS_MAPS')
    drop_table(:status_maps)
  end
end