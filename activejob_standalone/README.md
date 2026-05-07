Prova de conceito de job assincrono.

Precisa ter o redis instalado para o sidekiq funcionar.

Com o redis instalado e rodando, pode rodar o sidekiq com o comando:

```sh
sidekiq -r ./do_sleep_worker.rb
```
e aqui o `./` antes do nome do arquivo é importante!

Isso aqui é o que acontece quando não tem o caractér `.`
```
➜  activejob_standalone git:(main) ✗ sidekiq -r do_sleep_job.rb 
<internal:/usr/lib/ruby/vendor_ruby/rubygems/core_ext/kernel_require.rb>:86:in `require': cannot load such file -- do_sleep_job.rb (LoadError)
        from <internal:/usr/lib/ruby/vendor_ruby/rubygems/core_ext/kernel_require.rb>:86:in `require'
        from /var/lib/gems/3.2.0/gems/sidekiq-8.1.3/lib/sidekiq/cli.rb:321:in `boot_application'
        from /var/lib/gems/3.2.0/gems/sidekiq-8.1.3/lib/sidekiq/cli.rb:43:in `run'
        from /var/lib/gems/3.2.0/gems/sidekiq-8.1.3/bin/sidekiq:31:in `<top (required)>'
        from /usr/local/bin/sidekiq:25:in `load'
        from /usr/local/bin/sidekiq:25:in `<main>'
```

Já quando coloca o `./` fica assim:

```
➜  activejob_standalone git:(main) ✗ sidekiq -r ./do_sleep_job.rb


               m,
               `$b
          .ss,  $$:         .,d$
          `$$P,d$P'    .,md$P"'
           ,$$$$$b/md$$$P^'
         .d$$$$$$/$$$P'
         $$^' `"/$$$'       ____  _     _      _    _
         $:    ',$$:       / ___|(_) __| | ___| | _(_) __ _
         `b     :$$        \___ \| |/ _` |/ _ \ |/ / |/ _` |
                $$:         ___) | | (_| |  __/   <| | (_| |
                $$         |____/|_|\__,_|\___|_|\_\_|\__, |
              .d$$                                       |_|
      

Signal INFO not supported
INFO  2026-05-07T03:03:14.682Z pid=26039 tid=j0b: Running in ruby 3.2.3 (2024-01-18 revision 52bb2ac0a6) [x86_64-linux-gnu]
INFO  2026-05-07T03:03:14.682Z pid=26039 tid=j0b: See LICENSE and the LGPL-3.0 for licensing details.
INFO  2026-05-07T03:03:14.682Z pid=26039 tid=j0b: Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org
INFO  2026-05-07T03:03:14.682Z pid=26039 tid=j0b: Sidekiq 8.1.3 connecting to Redis with options {:size=>10, :pool_name=>"internal", :url=>nil}
INFO  2026-05-07T03:03:14.683Z pid=26039 tid=j0b: Sidekiq 8.1.3 connecting to Redis with options {:size=>5, :pool_name=>"default", :url=>nil}
INFO  2026-05-07T03:03:14.684Z pid=26039 tid=j0b: Starting processing, hit Ctrl-C to stop
```

### Para testar

Abra o `irb` num outro terminal e digite:

```ruby
require_relative 'do_sleep_job'
DoSleepJob.perform_later
```

Observe que neste terminal, vai aparecer dados como identificador do job.
No terminal do sidekiq é que vai aparecer dados do perform do job.

