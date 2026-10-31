#! /usr/bin/env ruby
# frozen_string_literal: true

def describe(value)
  case value
  in Integer | Float => n if n.negative? then "negative number #{n}"
  in Integer => n then "integer #{n}"
  in [] then 'empty array'
  in [first, *rest] then "array starting with #{first} (+#{rest.size})"
  in { type: :user, name: String => name, roles: [*, :admin, *] } then "admin #{name}"
  in { type: :user, name: } then "user #{name}"
  in nil then 'nil'
  else 'unknown'
  end
end

[-1, 5, [], [1, 2, 3], { type: :user, name: 'Ana', roles: %i[dev admin] },
 { type: :user, name: 'Bob' }, nil, :x].each { |v| puts describe(v) }

# deconstruct / deconstruct_keys on custom classes
Point = Struct.new(:x, :y)
case Point.new(1, 2)
in [x, y] then puts "array pattern: #{x},#{y}"
end
case Point.new(1, 2)
in { x:, y: } then puts "hash pattern: #{x},#{y}"
end

class Temperature
  attr_reader :degrees, :unit

  def initialize(degrees, unit) = (@degrees, @unit = degrees, unit)
  def deconstruct_keys(_keys) = { degrees: degrees, unit: unit }
end

case Temperature.new(40, :c)
in { unit: :c, degrees: 35.. } then puts 'hot'
in { unit: :c } then puts 'ok'
end

# pin operator and one-line patterns
expected = 5
case 5
in ^expected then puts 'pinned match'
end

config = { db: { user: 'admin', port: 5432 } }
config => { db: { port: } }
puts port
matched = (config in { db: { user: String } })
puts matched
