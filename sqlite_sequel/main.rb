#! /usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'sequel'
  gem 'sqlite3'
end

require 'sequel'

DB = Sequel.sqlite # in-memory

DB.create_table :authors do
  primary_key :id
  String :name, null: false, unique: true
end

DB.create_table :books do
  primary_key :id
  foreign_key :author_id, :authors
  String :title, null: false
  Integer :year
end

class Author < Sequel::Model
  one_to_many :books
end

class Book < Sequel::Model
  many_to_one :author
end

machado = Author.create(name: 'Machado de Assis')
machado.add_book(title: 'Dom Casmurro', year: 1899)
machado.add_book(title: 'Quincas Borba', year: 1891)

puts Book.order(:year).map { |b| "#{b.year} #{b.title} (#{b.author.name})" }
puts DB[:books].where { year < 1895 }.sql
