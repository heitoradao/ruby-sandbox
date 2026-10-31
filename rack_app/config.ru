# frozen_string_literal: true

require_relative 'app'

use RequestTimer
run App.new
