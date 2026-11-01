#! /usr/bin/env ruby
# Host app using BlogEngine: model, controller, views, helper, migration,
# config option and a host-side view override.
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rack/test"
require_relative "blog_engine/engine"

class DemoApp < Rails::Application
  config.eager_load = false
  config.logger = Logger.new(nil)
  config.secret_key_base = "x" * 32
  config.hosts.clear
  config.action_controller.allow_forgery_protection = false
  config.blog_engine.title = "My Blog"
  config.paths["db/migrate"] << File.expand_path("blog_engine/db/migrate", __dir__)
  config.paths.add "config/database", with: File.expand_path("database.yml", __dir__)
end

# Host views take precedence over engine views when the OVERRIDE env var is set.
if ENV["OVERRIDE"]
  DemoApp.config.paths["app/views"].unshift(File.expand_path("host_views", __dir__))
end

DemoApp.initialize!
DemoApp.routes.draw { mount BlogEngine::Engine, at: "/blog" }

ActiveRecord::MigrationContext.new(BlogEngine::Engine.root.join("db/migrate")).migrate

include Rack::Test::Methods
def app = DemoApp

BlogEngine::Post.create!(title: "First", body: "Hello from the engine model, with a long body text")

get "/blog/posts"
puts "== GET /blog/posts (#{last_response.status})", last_response.body

post "/blog/posts", post: { title: "Second", body: "Created via controller" }
puts "== POST /blog/posts (#{last_response.status}) -> #{last_response.location}"

get "/blog/posts/2"
puts "== GET /blog/posts/2 (#{last_response.status})", last_response.body
