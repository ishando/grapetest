require_relative '../api/ping'
require_relative '../api/status'

module GrapeTest
  class API < Grape::API

    format :json
    mount ::GrapeTest::Ping
    mount ::GrapeTest::GetStatus
    # add_swagger_documentation
  end
end