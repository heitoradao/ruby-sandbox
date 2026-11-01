module HelloEngine
  class Engine < Rails::Engine
    isolate_namespace HelloEngine
    # Engine root is the directory containing app/ and config/
    config.root = File.expand_path("..", __dir__)
  end
end
