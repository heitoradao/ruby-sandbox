#! /usr/bin/env ruby
# Host app mounting a minimal Rails::Engine, exercised with Rack::MockRequest.
require "rails"
require "action_controller/railtie"
require "rack/mock"
require_relative "hello_engine"

class DemoApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "x" * 32
  config.hosts.clear
end

DemoApp.initialize!
DemoApp.routes.draw { mount HelloEngine::Engine, at: "/hello" }

res = Rack::MockRequest.new(DemoApp).get("/hello/greet/mundo")
puts "#{res.status} #{res.body}"
