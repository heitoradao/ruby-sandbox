I'll show you how to use ActiveSupport::Cache outside of Rails. Here's a complete example:

1. First, add the required gems to your Gemfile:
```ruby
gem 'activesupport'
```

2. Basic setup and usage:
```ruby
require 'active_support'
require 'active_support/cache'
require 'active_support/cache/memory_store'  # For memory store
# Or require 'active_support/cache/file_store' for file store
# Or require 'active_support/cache/redis_cache_store' for Redis

# Initialize a cache store
# Memory Store Example
cache = ActiveSupport::Cache::MemoryStore.new

# File Store Example
# cache = ActiveSupport::Cache::FileStore.new("/path/to/cache/directory")

# Redis Store Example (requires redis gem)
# cache = ActiveSupport::Cache::RedisCacheStore.new(url: "redis://localhost:6379/0")

# Basic operations
cache.write("my_key", "my_value")
value = cache.read("my_key")
puts value  # outputs: "my_value"

# Using fetch (reads if exists, writes if doesn't)
result = cache.fetch("expensive_operation", expires_in: 1.hour) do
  # This block only executes if the cache key doesn't exist
  "expensive operation result"
end

# Delete from cache
cache.delete("my_key")

# Check if key exists
cache.exist?("my_key")  # returns false or true
```

3. More advanced usage with options:
```ruby
# With expiration time
cache.write("key", "value", expires_in: 3600)  # expires in 1 hour

# With race condition prevention
cache.fetch("key", race_condition_ttl: 10) do
  # your code here
end

# Store complex objects
user_data = { name: "John", age: 30 }
cache.write("user", user_data)

# Fetch with forced update
cache.fetch("key", force: true) { "new_value" }

# Multiple operations
cache.write_multi(
  "key1" => "value1",
  "key2" => "value2"
)

values = cache.read_multi("key1", "key2")
```

4. Error handling:
```ruby
begin
  cache.fetch("my_key") do
    # potentially failing operation
    raise "Something went wrong"
  end
rescue => e
  puts "Cache operation failed: #{e.message}"
end
```

5. Using different stores with specific configurations:

```ruby
# Memory Store with size limit
memory_cache = ActiveSupport::Cache::MemoryStore.new(size: 64.megabytes)

# File Store with specific directory
file_cache = ActiveSupport::Cache::FileStore.new("/tmp/cache")

# Redis Store with advanced configuration
redis_cache = ActiveSupport::Cache::RedisCacheStore.new(
  url: "redis://localhost:6379/0",
  connect_timeout: 30,  # Timeout for initial connect
  read_timeout: 0.2,    # Timeout for read operations
  write_timeout: 0.2,   # Timeout for write operations
  reconnect_attempts: 1 # Number of reconnect attempts
)
```

Important tips:

1. Memory management:
   - MemoryStore keeps everything in RAM, so be careful with large datasets
   - FileStore is better for larger datasets but slower
   - RedisCacheStore is good for distributed systems

2. Thread safety:
```ruby
# All built-in cache stores are thread-safe
# You can safely use them in multi-threaded environments
Thread.new do
  cache.write("thread_key", "thread_value")
end
```

3. Namespace support:
```ruby
# You can namespace your cache to avoid key conflicts
namespaced_cache = ActiveSupport::Cache::MemoryStore.new(namespace: "my_app")
namespaced_cache.write("key", "value")  # Actually stored as "my_app:key"
```

4. Compression:
```ruby
# Enable compression for large values
cache.write("big_data", large_object, compress: true)
```

Remember to handle cache invalidation appropriately and set reasonable expiration times for your cached data. Also, consider using a distributed cache store like Redis if you're running multiple application instances.

