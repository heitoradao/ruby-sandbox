Prova de conceito de job assincrono.

Precisa ter o redis instalado para o sidekiq funcionar.

Com o redis instalado e rodando, pode rodar o sidekiq com o comando:

```sh
sidekiq -r ./do_sleep_worker.rb
```
e aqui o `./` antes do nome do arquivo é importante!
<!-- incluir screenshot comparando o que acontece quando não tem esse `./` -->

Para testar, abra o `irb` num outro terminal e digite:

```ruby
require_relative 'do_sleep_job'
DoSleepJob.perform_later
```

Observe que neste terminal, vai aparecer dados como identificador do job.
No terminal do sidekiq é que vai aparecer dados do perform do job.

