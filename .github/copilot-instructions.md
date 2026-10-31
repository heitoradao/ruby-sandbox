# Copilot Instructions

`ruby-sandbox` is a collection of independent Ruby proofs of concept. Each top-level directory is a standalone experiment (no shared Gemfile, no test suite, no linter, no build system). Scripts are run directly with `ruby <dir>/<file>.rb`; required gems are installed globally with `gem install` (see `gems/list.txt`, partly in Portuguese).

## Per-directory notes

- `activejob_standalone/` – ActiveJob with the Sidekiq adapter, outside Rails. Requires a running Redis. Start the worker from inside the directory with `rake start_sidekiq` or `sidekiq -r ./do_sleep_job.rb` (the leading `./` is required, otherwise Sidekiq raises `LoadError`). Enqueue from `irb`: `require_relative 'do_sleep_job'; DoSleepJob.perform_later`.
- `fiddle/` – Ruby `Fiddle` FFI examples (`libm`, and `cobc/` for calling COBOL). The COBOL module must be built first with `cobc -m say.cbl` (see `fiddle/cobc/build.sh`) to produce `say.so`; `cob_init()` must be called before any other COBOL call.
- `rabbit/` – Bunny (RabbitMQ) client; `run_docker.sh` starts a `rabbitmq:3-management` container, `main.rb` connects and drops into `pry`. Config is loaded via `dotenv` from `rabbit/.env`.
- `money/` – `money` gem usage; `test.rb` is a demo script, not a test suite (`money/README.md` is the upstream gem's README).
- `simple_builder/` – `main.rb` demos a block-based HTML builder DSL defined in `simple_builder.rb`.
- `printmd/`, `qrcode/`, `inline_image/` – small CLI scripts (extensionless executables) with their own READMEs.
- `mandelbrot/`, `prime/`, `recursion/`, `ractor/`, `trap-signal/`, `algorithms/` – single-file demos.

## Conventions

- Keep each experiment self-contained in its own directory; add a short `README.md` there when setup steps are non-obvious.
- Scripts use a `#! ruby` / `#! /usr/bin/env ruby` shebang; local files are loaded with `require_relative`.
- Target Ruby is 3.2 (system Ruby on Debian/Ubuntu).

## Additional experiments

- `metaprogramming/`, `pattern_matching/`, `optparse_cli/` – stdlib-only scripts.
- `threads_mutex/` – `producer_consumer.rb` and `thread_pool.rb`.
- `minitest_rspec/` – the only tests in the repo. Run `ruby stack_test.rb` or `rspec stack_spec.rb`; single test: `ruby stack_test.rb -n test_name` / `rspec stack_spec.rb:LINE`.
- `rack_app/` – `rackup config.ru` (middleware in `app.rb`).
- `bundler_inline/`, `sqlite_sequel/` – use `bundler/inline`, so they need network on first run; `sqlite_sequel` also needs the sqlite3 dev headers (`libsqlite3-dev`).
