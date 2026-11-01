# rails_engine_full

`Rails::Engine` (`blog_engine/`) exporting a model, controller, views, layout, helper,
migration, routes and a host-configurable option, mounted at `/blog` in a host app.

    ruby main.rb              # engine views
    OVERRIDE=1 ruby main.rb   # host view (host_views/) overrides the engine's show.html.erb

Needs `rails` and `sqlite3` gems. Demonstrates:

- `isolate_namespace` (tables prefixed `blog_engine_`, namespaced routes)
- `config.blog_engine.title` set by the host
- engine migrations appended to the host's `db/migrate` path
- view override by the host via `app/views` path precedence
