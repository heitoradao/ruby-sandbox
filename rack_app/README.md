# Rack app

Minimal Rack application plus a custom middleware.

    rackup config.ru -p 9292     # or: puma config.ru
    curl -i localhost:9292/time
    curl -d hello localhost:9292/echo
