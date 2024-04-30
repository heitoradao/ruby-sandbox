#! /usr/bin/env ruby
r = Ractor.new do
  sleep 5
  Ractor.yield 'ok'
end

puts r.take
