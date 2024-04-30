#! ruby
# frozen_string_literal: true

class Mandelbrot
  def initialize (bailout = 10, iterations = 100)
    @bailout, @iterations = bailout, iterations
  end

  def mandelbrot (x, y)
    c = Complex(x, y)
    z = 0
    @iterations.times do |i|
      z = z ** 2 + c
      return false if z.real > @bailout
    end
    return true
  end

  def render (x_size = 80, y_size = 24, inside_set = '*', outside_set = ' ')
    0.upto(y_size) do |y|
      0.upto(x_size) do |x|
        scaled_x = -2 + ( 3 * x / x_size.to_f)
        scaled_y =  1 + (-2 * y / y_size.to_f)
        print mandelbrot(scaled_x, scaled_y) ? inside_set : outside_set
      end
      puts
    end
  end
end

m = Mandelbrot.new
m.render
