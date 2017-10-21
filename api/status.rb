require 'grape'
require 'grape-entity'
require_relative '../models/statuses'

module GrapeTest

  class GetStatus < Grape::API
    format :json

    get '/incomplete' do
      statuses = EventStatusLog.incomplete.all
      applications = []
      statuses.each do |st|
        applications << {
          customer_uuid: st.values[:customer_uuid],
          application_id: st.values[:application_id],
          statuses: []
        } if applications.empty? || applications[-1][:application_id] != st.values[:application_id]

        applications[-1][:statuses] << {
          status: st.values[:status],
          event_ts: st.values[:event_ts],
          elapsed_time: st.values[:elapsed_time] }
      end
p applications

      # present applications, with: GrapeTest::EventStatusLog::Incomplete
      present statuses
    end

    get '/complete' do
      statuses = EventStatusLog.complete.all
      applications = statuses.map { |st| st.values}
p applications
      present applications, with: GrapeTest::EventStatusLog::Completed
    end
  end
end

# [
#   {:customer_uuid=>"Cust0001", :application_id=>"1", :status=>"approved", :event_ts=>2017-10-16 07:04:11 +1100, :elapsed_time=>0.8e0, :request_amt=>"20000", :approve_amt=>"10000"},
#   {:customer_uuid=>"Cust0002", :application_id=>"2", :status=>"withdrawn", :event_ts=>2017-10-17 02:16:11 +1100, :elapsed_time=>0.6e0, :request_amt=>"30000", :approve_amt=>"0"},
#   {:customer_uuid=>"Cust0003", :application_id=>"3", :status=>"denied", :event_ts=>2017-10-17 04:40:11 +1100, :elapsed_time=>0.4e0, :request_amt=>"20000", :approve_amt=>"0"}
# ]



# [
#   {
#     :customer_uuid=>"Cust0004",
#     :application_id=>"4",
#     :statuses=>[
#       {:status=>"submitted", :event_ts=>2017-10-17 11:52:11 +1100, :elapsed_time=>0.6e0},
#       {:status=>"validating", :event_ts=>2017-10-17 19:04:11 +1100, :elapsed_time=>0.6e0},
#       {:status=>"reviewing", :event_ts=>2017-10-18 02:16:11 +1100, :elapsed_time=>0.6e0}
#     ]
#   },
#   {
#     :customer_uuid=>"Cust0005",
#     :application_id=>"5",
#     :statuses=>[
#       {:status=>"submitted", :event_ts=>2017-10-18 11:52:11 +1100, :elapsed_time=>0.3e0},
#       {:status=>"validating", :event_ts=>2017-10-18 19:04:11 +1100, :elapsed_time=>0.3e0}
#     ]
#   },
#   {
#     :customer_uuid=>"Cust0006",
#     :application_id=>"6",
#     :statuses=>[
#       {:status=>"submitted", :event_ts=>2017-10-18 23:52:11 +1100, :elapsed_time=>0.1e0},
#       {:status=>"validating", :event_ts=>2017-10-19 02:16:11 +1100, :elapsed_time=>0.1e0}
#     ]
#   },
#   {
#     :customer_uuid=>"Cust0002",
#     :application_id=>"7",
#     :statuses=>[
#       {:status=>"submitted", :event_ts=>2017-10-19 16:40:11 +1100, :elapsed_time=>0.0}
#     ]
#   }
# ]
