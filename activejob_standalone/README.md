Prova de conceito de job assincrono.

Precisa ter o redis instalado para o sidekiq funcionar.

Com o redis instalado e rodando, pode rodar o sidekiq com o comando:

```sh
sidekiq -r ./do_sleep_worker.rb
```

Para testar, abra um outro terminal.
Abra o `irb` num outro terminal e digite:

```ruby
require_relative 'do_sleep_worker.rb'
Foo.perform_later
```
Observe que neste terminal, vai aparecer dados como identificador do job.
No terminal do sidekiq é que vai aparecer dados do perform do job.

