require 'grape'
require 'grape-entity'
require_relative '../models/statuses'

module GrapeTest

  class GetStatus < Grape::API
    format :json

    get '/incomplete' do
      statuses = EventStatusLog.incomplete.all
      present statuses #, with: GrapeTest::EventStatusLog::Entity
    end

    get '/complete' do
      statuses = EventStatusLog.complete.all
      present statuses, with: GrapeTest::Completed
    end
  end
end