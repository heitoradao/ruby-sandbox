#! /usr/bin/env ruby
# Heitor Jr

require 'fiddle'
require 'fiddle/import'

module LibM
  extend Fiddle::Importer
  dlload '/lib/x86_64-linux-gnu/libm.so.6'
  extern 'double floor(double)'
  extern 'double pow(double, double)'
end

print 'floor(3.14159) == '
puts LibM.floor(3.14159)

print 'pow(2, 3) == '
puts LibM.pow(2,3)  # => 8.0

