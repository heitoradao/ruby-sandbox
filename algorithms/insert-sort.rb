#! ruby

def insert_sort!(a)
  for i in 1... a.size
    key = a[i]

    j = i - 1
    while j >= 0 && a[j] > key
      a[j+1] = a[j]
      j -= 1
    end
    a[j+1] = key
  end

  a
end

a = [5, 2, 4, 6, 1, 3]

puts a.inspect
insert_sort!(a)
puts a.inspect

