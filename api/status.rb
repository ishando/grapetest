require 'grape'
require 'grape-entity'
require_relative '../models/statuses'

module GrapeTest
  class GetStatus < Grape::API
    format :json

    get '/incomplete' do
      statuses = EventStatusLog.incomplete.all
      applications = []
      app = [:customer_uuid, :application_id]
      stat = [:status, :event_ts, :elapsed_time]

      statuses.each do |st|
        # applications << {
        #   customer_uuid: st.values[:customer_uuid],
        #   application_id: st.values[:application_id],
        #   statuses: []
        # } if applications.empty? || applications[-1][:application_id] != st.values[:application_id]
        if applications.empty? || applications[-1][:application_id] != st.values[:application_id]
          applications << st.values.select { |k,v| app.include?(k) }
          applications[-1][:statuses] = []
        end

        # applications[-1][:statuses] << {
        #   status: st.values[:status],
        #   event_ts: st.values[:event_ts],
        #   elapsed_time: st.values[:elapsed_time] }
        applications[-1][:statuses] << st.values.select { |k,v| stat.include?(k) }

      end

      present applications, with: GrapeTest::EventStatusLog::Incomplete
    end

    get '/complete' do
      statuses = EventStatusLog.complete.all
      present statuses, with: GrapeTest::EventStatusLog::Completed
    end
  end
end
