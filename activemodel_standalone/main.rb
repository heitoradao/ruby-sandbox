#! /usr/bin/env ruby
# frozen_string_literal: true

require_relative 'person'

# Type casting
person = Person.new(name: 'Ana', age: '30', born_on: '1995-04-10')
p person.age, person.born_on, person.attributes

# Validations
bad = Person.new(name: 'A', age: '-1', email: 'nope', born_on: Date.today + 1)
puts bad.valid?
puts bad.errors.full_messages
p bad.errors.where(:age).map(&:type)

# Dirty tracking
person.save
person.name = 'Ana Maria'
p person.changed?, person.changes
person.save
p person.changed?

# Naming / conversion / JSON
p Person.model_name.human, Person.model_name.param_key, person.to_key
puts person.to_json
puts Person.new.from_json('{"name":"Bia","age":22}').name
