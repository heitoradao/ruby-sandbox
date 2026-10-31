# frozen_string_literal: true

require_relative 'stack'

RSpec.describe Stack do
  subject(:stack) { described_class.new }

  it 'is LIFO' do
    stack.push(1).push(2)
    expect([stack.pop, stack.pop]).to eq [2, 1]
  end

  it 'raises when popping an empty stack' do
    expect { stack.pop }.to raise_error(IndexError, 'stack is empty')
  end

  it 'enumerates top first' do
    stack.push(1).push(2)
    expect(stack.map { _1 * 10 }).to eq [20, 10]
  end
end
