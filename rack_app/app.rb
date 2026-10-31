# frozen_string_literal: true

require 'json'
require 'rack'

class App
  def call(env)
    req = Rack::Request.new(env)
    case [req.request_method, req.path_info]
    in ['GET', '/']
      respond(200, 'text/plain', "Hello from Rack\n")
    in ['GET', '/time']
      respond(200, 'application/json', { time: Time.now.utc.iso8601 }.to_json)
    in ['POST', '/echo']
      respond(200, 'application/json', { echo: req.body.read }.to_json)
    else
      respond(404, 'text/plain', "Not found\n")
    end
  end

  private

  def respond(status, type, body)
    [status, { 'content-type' => type }, [body]]
  end
end

# Middleware: adds an X-Runtime header
class RequestTimer
  def initialize(app) = @app = app

  def call(env)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, body = @app.call(env)
    headers['x-runtime'] = format('%.6f', Process.clock_gettime(Process::CLOCK_MONOTONIC) - start)
    [status, headers, body]
  end
end
