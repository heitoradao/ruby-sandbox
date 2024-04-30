#! /usr/bin/env ruby
# Heitor

require 'bunny'
require 'dotenv'
require 'pry'
Dotenv.load

begin
  connection = Bunny.new(hostname: 'amqp://172.17.0.1')
  # connection = Bunny.new(hostname: 'amqp://some-rabbit')
  connection.start

  binging.pry
rescue Bunny::TCPConnectionFailed => e
  puts "Connection to server failed"
end



