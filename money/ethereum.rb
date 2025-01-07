#! ruby

require 'money'

eth = {
  priority: 2,
  iso_code: 'ETH',
  #iso_numeric: 333,
  name: "Ethereum",
  symbol: "ETH$",
  subunit: 'Cent',
  subunit_to_unit: 100,
  decimal_mark: '.',
  thousands_separator: '_'
}

Money::Currency.register(eth)
Money.add_rate('ETH', 'USD', 3_735.11)
Money.add_rate('USD', 'ETH', 0.00027)

