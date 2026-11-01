module BlogEngine
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    layout "blog_engine/application"
  end
end
