#! /usr/bin/env ruby
# frozen_string_literal: true

# Unsynchronized vs Mutex-protected counter
counter = 0
mutex = Mutex.new
threads = 4.times.map do
  Thread.new { 10_000.times { mutex.synchronize { counter += 1 } } }
end
threads.each(&:join)
puts "counter with mutex: #{counter} (expected 40000)"

# Producer/consumer with a bounded SizedQueue
queue = SizedQueue.new(3)

producer = Thread.new do
  5.times do |i|
    queue << i
    puts "produced #{i}"
  end
  2.times { queue << :done }
end

consumers = 2.times.map do |id|
  Thread.new do
    while (item = queue.pop) != :done
      puts "consumer #{id} got #{item}"
      sleep 0.05
    end
  end
end

[producer, *consumers].each(&:join)

# ConditionVariable: wait until a flag is set
lock = Mutex.new
ready = ConditionVariable.new
flag = false

waiter = Thread.new do
  lock.synchronize do
    ready.wait(lock) until flag
    puts 'waiter: flag is set'
  end
end

sleep 0.1
lock.synchronize { flag = true; ready.signal }
waiter.join
