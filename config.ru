#/ -p 9292

require 'rack'
require 'pg'
require 'sequel'

DB = Sequel.connect(adapter: 'postgres', host: 'localhost', database: 'scentre', user: 'scentre', password: 'scentre')

#require_relative 'app/grape_test'
require_relative 'app/api'

RACK_ENV = ENV['RACK_ENV'] || 'development'

run GrapeTest::API
