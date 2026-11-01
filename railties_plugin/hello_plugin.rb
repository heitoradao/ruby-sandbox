module HelloPlugin
  class Railtie < Rails::Railtie
    config.hello_plugin = ActiveSupport::OrderedOptions.new
    config.hello_plugin.greeting = "Hello"

    initializer "hello_plugin.configure" do |app|
      HelloPlugin.greeting = app.config.hello_plugin.greeting
    end

    rake_tasks do
      desc "Prints a greeting from HelloPlugin"
      task :hello do
        puts HelloPlugin.greet("rake")
      end
    end

    config.after_initialize do
      puts "[hello_plugin] after_initialize: #{HelloPlugin.greet('app')}"
    end
  end

  class << self
    attr_accessor :greeting

    def greet(name)
      "#{greeting}, #{name}!"
    end
  end
end
