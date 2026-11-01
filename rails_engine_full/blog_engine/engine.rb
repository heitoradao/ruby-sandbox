module BlogEngine
  class Engine < Rails::Engine
    isolate_namespace BlogEngine
    config.root = __dir__

    # Host-configurable option: config.blog_engine.title = "..."
    config.blog_engine = ActiveSupport::OrderedOptions.new
    config.blog_engine.title = "Blog Engine"

    # Expose engine migrations to the host (like `rails blog_engine:install:migrations`)
    initializer "blog_engine.migrations" do |app|
      app.config.paths["db/migrate"] << root.join("db/migrate").to_s
    end
  end
end
