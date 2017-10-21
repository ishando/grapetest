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

      present applications, with: GrapeTest::EventStatusLog::Incomplete
    end

    get '/complete' do
      statuses = EventStatusLog.complete.all
      present statuses, with: GrapeTest::EventStatusLog::Completed
    end
  end
end
