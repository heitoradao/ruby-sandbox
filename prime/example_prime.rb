#! ruby

require 'prime'

puts 'The first 15 prime numbers:'
p Prime.first(15)


is_prime = Prime.prime? 53
puts "Is 53 prime? > #{is_prime}"

is_prime = Prime.prime? 57
puts "Is 57 prime? > #{is_prime}"
