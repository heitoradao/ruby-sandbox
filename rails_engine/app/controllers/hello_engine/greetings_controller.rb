module HelloEngine
  class GreetingsController < ActionController::Base
    def show
      render plain: "Hello from the engine, #{params[:name]}!"
    end
  end
end
