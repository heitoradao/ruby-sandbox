#! ruby
require 'money'
require_relative 'ethereum'

require 'irb'

Money.add_rate("USD", "BRL", 6.06)
Money.add_rate("BRL", "USD", 0.17)

puts <<TXT
Money.us_dollar(100).exchange_to("CAD")  # => Money.from_cents(124, "CAD")
Money.ca_dollar(100).exchange_to("USD")  # => Money.from_cents(80, "USD")
TXT



puts 'Vou fazer a conversão de dolar para real.'
print 'Digite um valor monetário em dolar: '
valor_dolar = gets.chomp

carteira_usd = Money.from_cents(valor_dolar.to_i, 'USD')
carteira_brl = carteira_usd.exchange_to('BRL')



puts "O valor em reais é R$ #{carteira_brl.cents}"
puts "O valor em eth = #{carteira_usd.exchange_to('ETH').cents}"

# IRB.start

