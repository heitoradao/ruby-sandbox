#! /usr/bin/env ruby
# HAJ

require 'progressbar'

trap(2) do
  puts
  puts 'OUCH!'
  puts 'Someone is trying to stop-me.'
end

#trap(9) do
#  puts "trying to catch kill -9"
#end


puts "The pid of this process is #{Process.pid}"
puts 'This program will run for 10 seconds'
puts 'Try <ctrl> + c or'
puts " kill -2 #{Process.pid}"

progressbar = ProgressBar.create
100.times do |i|
  progressbar.increment
  #print progressbar
  #print '.'
  sleep 0.1
end

