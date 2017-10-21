#/ -p 9292

require 'rack'
require 'oci8'
require 'sequel'

DB = Sequel.connect(adapter: 'oracle', host: '0.0.0.0:6601/xe', user: 'scentre', password: 'scentre')

#require_relative 'app/grape_test'
require_relative 'app/api'

RACK_ENV = ENV['RACK_ENV'] || 'development'

run GrapeTest::API
