#! /usr/bin/env ruby
# Minimal host app that loads a Railtie-based plugin without a full Rails app.
require "rails"
require_relative "hello_plugin"

class DemoApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "x" * 32
  config.hello_plugin.greeting = "Olá"
end

DemoApp.initialize!

puts HelloPlugin.greet("mundo")

DemoApp.load_tasks
Rake::Task[:hello].invoke
