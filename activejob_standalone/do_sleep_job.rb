#! ruby

require 'sidekiq'
require 'active_job'

ActiveJob::Base.queue_adapter = :sidekiq

class DoSleepWorker < ActiveJob::Base
  queue_as :default
  
  def perform(*args)
    puts 'starting to perform'
    puts "with *args = #{args.join(',')}"
    sleep 10
    puts 'finished to perform'
  end
end


#Foo.perform_later # for this to work, we need to make sidekiq service run
#Foo.perform_now
