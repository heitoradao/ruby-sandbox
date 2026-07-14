#! ruby

@cache = []

def fibonacci(n)
  return 1 if n <= 1
  @cache[n] ||= fibonacci(n-1) + fibonacci(n-2)
end

puts fibonacci(10)
