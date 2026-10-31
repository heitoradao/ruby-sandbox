#! /usr/bin/env ruby
# frozen_string_literal: true

# Minimal hand-made thread pool
class ThreadPool
  def initialize(size)
    @jobs = Queue.new
    @workers = Array.new(size) do
      Thread.new do
        while (job = @jobs.pop)
          job.call
        end
      end
    end
  end

  def submit(&block) = @jobs << block

  def shutdown
    @workers.size.times { @jobs << nil }
    @workers.each(&:join)
  end
end

results = Queue.new
pool = ThreadPool.new(3)
6.times { |i| pool.submit { sleep 0.1; results << [i, Thread.current.object_id] } }
pool.shutdown

puts "#{results.size} jobs done by #{Array.new(results.size) { results.pop.last }.uniq.size} threads"
