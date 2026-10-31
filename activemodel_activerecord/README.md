# ActiveModel + ActiveRecord

`ActiveRecord::Base` is built on ActiveModel. This example shows:

- the ActiveModel modules ActiveRecord already includes (validations, dirty, callbacks, enum, serialization)
- a reusable `ActiveSupport::Concern`
- a form object (`ActiveModel::Model`) that reuses the record's validations

Uses an in-memory SQLite database (`sqlite3` gem).

    ruby main.rb
