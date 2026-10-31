#! /usr/bin/env ruby
# frozen_string_literal: true

# Dependencies declared inside the script itself; no Gemfile needed.
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rainbow'
end

puts Rainbow('bundler/inline works').green.bright
