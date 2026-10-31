#! /usr/bin/env ruby
# frozen_string_literal: true

# method_missing + respond_to_missing?: proxy that logs every call
class LoggingProxy < BasicObject
  def initialize(target)
    @target = target
  end

  def method_missing(name, *args, &block)
    if @target.respond_to?(name)
      ::Kernel.puts "-> #{name}(#{args.join(', ')})"
      @target.public_send(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    @target.respond_to?(name, include_private)
  end
end

proxy = LoggingProxy.new([3, 1, 2])
p proxy.sort
p proxy.push(4).size

# define_method: generate predicates from a list
class Light
  STATES = %i[red yellow green].freeze

  STATES.each do |state|
    define_method(:"#{state}?") { @state == state }
    define_method(:"#{state}!") { @state = state; self }
  end
end

light = Light.new.green!
p [light.green?, light.red?]

# instance_eval: tiny configuration DSL
class Config
  def self.build(&block)
    new.tap { |c| c.instance_eval(&block) }
  end

  def set(key, value)
    (@values ||= {})[key] = value
  end

  def to_h = @values
end

p Config.build { set :host, 'localhost'; set :port, 8080 }.to_h

# class_eval + Module#prepend: wrap an existing method
module Timing
  def slow_add(a, b)
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    super.tap { puts format('slow_add took %.2fs', Process.clock_gettime(Process::CLOCK_MONOTONIC) - t) }
  end
end

class Calc
  def slow_add(a, b)
    sleep 0.1
    a + b
  end
  prepend Timing
end

p Calc.new.slow_add(1, 2)
