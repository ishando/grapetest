require 'sequel'
require 'grape-entity'

module GrapeTest
  class EventStatusLog < Sequel::Model
    require_valid_table = false

    dataset_module do
      def incomplete
        with_sql(<<~SQL)
          with applications as
            (select e1.customer_uuid, e1.application_id, sum(e1.elapsed_time) elapsed_time, max(e1.event_ts) event_ts
             from event_status_logs e1
             where not exists
               (select 1 from event_status_logs e0
                inner join status_maps m0 on m0.event_type = e0.event_type and m0.category = 'completed'
                where e0.application_id = e1.application_id)
             group by e1.customer_uuid, e1.application_id)
          select a1.customer_uuid, a1.application_id, m2.category as status, max(e2.event_ts) as event_ts, a1.elapsed_time
          from applications a1
          left outer join event_status_logs e2
            inner join status_maps m2 on m2.event_type = e2.event_type
            on e2.customer_uuid = a1.customer_uuid and e2.application_id = a1.application_id
          group by a1.customer_uuid, a1.application_id, m2.category, a1.elapsed_time
          order by 5 desc, 1, 2, 4
        SQL
      end

      def complete
        with_sql(<<~SQL)
          select e1.customer_uuid, e1.application_id,
                 max(e1.event_type) keep (dense_rank last order by e1.event_ts) as status,
                 max(e1.event_ts) as event_ts,
                 sum(e1.elapsed_time) as elapsed_time,
                 max(case when e1.event_type = 'submitted' then disposition else '0' end) as request_amt,
                 max(case when e1.event_type = 'approved' then disposition else '0' end) as approve_amt
          from event_status_logs e1
          where exists
            (select 1
             from event_status_logs e0
             inner join status_maps m0 on m0.event_type = e0.event_type and m0.category = 'completed'
             where e0.application_id = e1.application_id)
          group by e1.customer_uuid, e1.application_id
        SQL
      end
    end

    attr_accessor :request_amt
    attr_accessor :approve_amt
    attr_accessor :statuses

    def entity
      Entity.new(self)
    end

    class Entity < Grape::Entity
      expose :customer_uuid, :application_id, :status, documentation: { type: String }
      expose :event_ts, documentation: { type: Date }
      expose :elapsed_time, documentation: { type: String }
    end

    class Completed < GrapeTest::EventStatusLog::Entity
      expose :request_amt, :approve_amt, documentation: { type: String }
    end

    class Status < Grape::Entity
      expose :status, documentation: { type: String }
      expose :event_ts, documentation: { type: Date }
      expose :elapsed_time, documentation: { type: String }
    end

    class Incomplete < Grape::Entity
      expose :customer_uuid, :application_id, documentation: { type: String }
      present_collection true, :statuses
      expose :statuses, using: GrapeTest::EventStatusLog::Status #, documentation: { type: Array }
    end

  end

end


#[<GrapeTest::EventStatusLog @values={
# :customer_uuid=>"Cust0001",
# :application_id=>"1",
# :elapsed_time=>0.8e0,
# :status=>"completed",
# :event_ts=>2017-10-16 07:04:11 +1100,
# :request_amt=>"20000",
# :approve_amt=>"10000"}>,

#<GrapeTest::EventStatusLog @values={
# :customer_uuid=>"Cust0002",
# :application_id=>"2",
# :elapsed_time=>0.6e0,
# :status=>"completed",
# :event_ts=>2017-10-17 02:16:11 +1100,
# :request_amt=>"30000",
# :approve_amt=>"0"}>,

#<GrapeTest::EventStatusLog @values={
# :customer_uuid=>"Cust0003",
# :application_id=>"3",
# :elapsed_time=>0.4e0,
# :status=>"completed",
# :event_ts=>2017-10-17 04:40:11 +1100,
# :request_amt=>"20000",
# :approve_amt=>"0"}>]
