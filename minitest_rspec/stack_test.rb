# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'stack'

class StackTest < Minitest::Test
  def setup = @stack = Stack.new

  def test_push_and_pop_are_lifo
    @stack.push(1).push(2)
    assert_equal 2, @stack.pop
    assert_equal 1, @stack.pop
  end

  def test_pop_on_empty_raises
    assert_raises(IndexError) { @stack.pop }
  end

  def test_enumerates_top_first
    @stack.push(1).push(2)
    assert_equal [2, 1], @stack.to_a
  end
end
