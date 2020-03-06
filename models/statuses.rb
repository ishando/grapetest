require 'sequel'
require 'grape-entity'

module Formatter
  extend Grape::API::Helpers

  Grape::Entity.format_with(:day_fraction) do |days|
    wholedays, hours, minutes = [1, 24, 60].map do |fraction|
      days *= fraction
      ret, days = days.divmod(1)
      ret
    end

    return [
      ("#{wholedays}d " if wholedays > 0),
      ("#{hours}h "     if hours > 0    ),
      ("#{minutes}m"                    ),
    ].join
  end
end

module GrapeTest
  class EventStatusLog < Sequel::Model
    require_valid_table = false
    plugin :after_initialize

    def after_initialize
      if !defined? @@generated
        values.each do |column, val|
          self.class.send :define_method, column do
            values[column]
          end
        end

        @@generated = 1
      end
    end

    dataset_module do
      def incomplete
        with_sql(<<~SQL)
          with applications as
            (select e1.customer_uuid, e1.application_id,
                    justify_interval(sum(get_elapsed_time(e1.event_type, e1.event_ts, e1.elapsed_time))) elapsed_time, max(e1.event_ts) event_ts
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
          with lastEvent as (
            select e1.customer_uuid, e1.application_id,
                   max(e1.event_ts) as event_ts,
                   justify_interval(sum(e1.elapsed_time)) as elapsed_time,
                   max(case when e1.event_type = 'submitted' then disposition else '0' end) as request_amt,
                   max(case when e1.event_type = 'approved' then disposition else '0' end) as approve_amt
            from event_status_logs e1
            where exists
                (select 1
                 from event_status_logs e0
                 inner join status_maps m0 on m0.event_type = e0.event_type and m0.category = 'completed'
                 where e0.application_id = e1.application_id)
            group by e1.customer_uuid, e1.application_id
          )
          select le.customer_uuid, le.application_id, le.event_ts, e.event_type, le.elapsed_time, le.request_amt, le.approve_amt
          from lastEvent le
          inner join event_status_logs e on e.customer_uuid = le.customer_uuid
            and e.application_id = le.application_id
            and e.event_ts = le.event_ts
        SQL
      end
    end

    def request_amt
      return values[:request_amt]
    end
    def approve_amt
      return values[:approve_amt]
    end

    def entity
      Entity.new(self)
    end

    class Entity < Grape::Entity
      expose :customer_uuid, :application_id, :status, documentation: { type: String }
      expose :event_ts, documentation: { type: Date }
      # expose :elapsed_time, format_with: :day_fraction, documentation: { type: String }
      expose :elapsed_time, documentation: { type: String }
    end

    class Completed < GrapeTest::EventStatusLog::Entity
      expose :request_amt, :approve_amt, safe: true, documentation: { type: String }
    end

    class Status < Grape::Entity
      root('statuses', 'status')
      expose :status, documentation: { type: String }
      expose :event_ts, documentation: { type: Date }
      # expose :elapsed_time, format_with: :day_fraction, documentation: { type: String }
      expose :elapsed_time, documentation: { type: String }
    end

    class Incomplete < Grape::Entity
      expose :customer_uuid, :application_id, documentation: { type: String }
      expose :statuses, using: GrapeTest::EventStatusLog::Status #, documentation: { type: Array }
    end

  end

end
