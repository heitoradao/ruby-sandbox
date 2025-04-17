#! ruby

require 'money'

# explicitly define locales
I18n.config.available_locales = :en
Money.locale_backend = :i18n

# 10.00 USD
money = Money.from_cents(1000, "USD")
money.cents     #=> 1000
money.currency  #=> Currency.new("USD")

# Comparisons
Money.from_cents(1000, "USD") == Money.from_cents(1000, "USD")   #=> true
Money.from_cents(1000, "USD") == Money.from_cents(100, "USD")    #=> false
Money.from_cents(1000, "USD") == Money.from_cents(1000, "EUR")   #=> false
Money.from_cents(1000, "USD") != Money.from_cents(1000, "EUR")   #=> true

# Arithmetic
Money.from_cents(1000, "USD") + Money.from_cents(500, "USD") == Money.from_cents(1500, "USD")
Money.from_cents(1000, "USD") - Money.from_cents(200, "USD") == Money.from_cents(800, "USD")
Money.from_cents(1000, "USD") / 5                            == Money.from_cents(200, "USD")
Money.from_cents(1000, "USD") * 5                            == Money.from_cents(5000, "USD")

# Unit to subunit conversions
Money.from_amount(5, "USD") == Money.from_cents(500, "USD")  # 5 USD
Money.from_amount(5, "JPY") == Money.from_cents(5, "JPY")    # 5 JPY
Money.from_amount(5, "TND") == Money.from_cents(5000, "TND") # 5 TND

# Currency conversions
some_code_to_setup_exchange_rates
Money.from_cents(1000, "USD").exchange_to("EUR") == Money.from_cents(some_value, "EUR")

# Swap currency
Money.from_cents(1000, "USD").with_currency("EUR") == Money.from_cents(1000, "EUR")

# Formatting (see Formatting section for more options)
Money.from_cents(100, "USD").format #=> "$1.00"
Money.from_cents(100, "GBP").format #=> "£1.00"
Money.from_cents(100, "EUR").format #=> "€1.00"
