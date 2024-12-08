#! /usr/bin/env ruby
# Heitor Jr

require 'fiddle'

# Ubuntu 24.4
libm = Fiddle.dlopen('/lib/x86_64-linux-gnu/libm.so.6')

floor = Fiddle::Function.new(
  libm['floor'],
  [Fiddle::TYPE_DOUBLE],
  Fiddle::TYPE_DOUBLE
)

print 'floor(3.14159) == '
puts floor.call(3.14159)

pow = Fiddle::Function.new(
  libm['pow'],
  [Fiddle::TYPE_DOUBLE, Fiddle::TYPE_DOUBLE],
  Fiddle::TYPE_DOUBLE
)

print 'pow(2, 3) == '
# syntatic suggar
puts pow.(2,3)  # => 8.0

=begin
class MathH
  def floor(*args)
    floor.(*args)
  end
end
=end




