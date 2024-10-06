#! ruby
# frozen_string_literal: true

class SimpleBuilder < BasicObject
  def initialize
    @indent = 0
  end

  def __indent_puts__(string)
    ::Kernel.puts "#{' ' * @indent} #{string}"
  end

  def __indent_print__(string)
    ::Kernel.print "#{' ' * @indent} #{string}"
  end

  def respond_to_missing
    true
  end

  def method_missing(name, *args, &block)
    if block
      __indent_puts__("<#{name}>")
      
      #unless args.empty?
      #  ::Kernel.print(' ', args.join)
      #end
      #::Kernel.print("\n")
      
      @indent += 2
      __indent_puts__(args.join) unless args.empty?
      yield
      @indent -= 2
      
      __indent_puts__("</#{name}>")
    else
      __indent_puts__("<#{name} />")
    end
  end
end

