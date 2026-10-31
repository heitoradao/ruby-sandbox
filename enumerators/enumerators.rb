#! /usr/bin/env ruby
# frozen_string_literal: true

# Enumerator.new: infinite generator, consumed on demand
fib = Enumerator.new do |y|
  a, b = 0, 1
  loop do
    y << a
    a, b = b, a + b
  end
end

p fib.take(10)
p fib.lazy.select(&:even?).first(5)

# Lazy pipelines: only the needed elements are computed
evaluated = []
result = (1..Float::INFINITY).lazy
                             .map { |n| evaluated << n; n * n }
                             .select { |n| n % 3 == 0 }
                             .first(3)
p result, evaluated

# External iteration: next / peek / rewind / StopIteration
e = %w[a b c].each
puts e.next, e.peek, e.next, e.next
begin
  e.next
rescue StopIteration
  puts 'done'
end
e.rewind
puts e.next

# Chained enumerators
p %w[a b c].each_with_index.map { |s, i| "#{i}:#{s}" }
p %w[a b c].each.with_index(1).to_a
p (1..10).each_slice(3).to_a
p (1..5).each_cons(2).to_a

# Fiber as a generator
gen = Fiber.new do
  3.times { |i| Fiber.yield i }
  :finished
end
4.times { p gen.resume }

# Custom collection with Enumerable; each returns an enumerator without a block
class Countdown
  include Enumerable

  def initialize(from) = @from = from

  def each
    return to_enum(:each) { @from + 1 } unless block_given?

    @from.downto(0) { |n| yield n }
  end
end

c = Countdown.new(3)
p c.to_a, c.each.size, c.select(&:odd?), c.each_slice(2).to_a, c.lazy.map { _1 * 2 }.first(2)

# Enumerator::Yielder and file-like streaming
lines = Enumerator.new do |y|
  y << "one\n" << "two\n"
  y.yield "three\n"
end
p lines.map(&:chomp)

# Enumerator::Lazy#eager and zip
p (1..3).lazy.zip(4..6).to_a
p Enumerator.produce(1) { _1 * 2 }.take(6)
