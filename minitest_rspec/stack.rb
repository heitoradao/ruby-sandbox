# frozen_string_literal: true

class Stack
  include Enumerable

  def initialize = @items = []

  def push(item)
    @items.push(item)
    self
  end

  def pop = @items.pop || raise(IndexError, 'stack is empty')
  def peek = @items.last
  def empty? = @items.empty?
  def each(&block) = @items.reverse.each(&block)
end
