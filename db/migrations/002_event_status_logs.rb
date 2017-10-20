Sequel.migration do
  up do
    puts('Creating table EVENT_STATUS_LOGS')
    create_table(:event_status_logs) do
      primary_key :id
      String     :client_id,      size: 32, null: false
      String     :customer_uuid,  size: 32, null: false
      String     :application_id, size: 32, null: false
      String     :event_type,     size: 32, null: false
      String     :status,         size: 32, null: false
      Date       :event_ts,       null: false
      String     :disposition,    size: 100
      BigDecimal :elapsed_time,   size: [20,10]
    end
  end

  down do
    puts('Dropping table EVENT_STATUS_LOGS')
    drop_table(:event_status_logs)
  end
end