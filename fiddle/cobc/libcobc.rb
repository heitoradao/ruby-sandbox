#! /usr/bin/env ruby
# Heitor Jr

require 'fiddle'

# Ubuntu 24.4
libcobc = Fiddle.dlopen('/usr/lib/x86_64-linux-gnu/libcob.so.4')

cob_init = Fiddle::Function.new(
  libcobc['cob_init'],
  [Fiddle::TYPE_CONST_STRING, Fiddle::TYPE_CONST_STRING],
  Fiddle::TYPE_INT
)

cob_stop_run = Fiddle::Function.new(
  libcobc['cob_stop_run'],
  [Fiddle::TYPE_INT],
  Fiddle::TYPE_INT
)

cob_call = Fiddle::Function.new(
  libcobc['cob_call'],
  [Fiddle::TYPE_CONST_STRING, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP],
  Fiddle::TYPE_INT
)

# cob_resolve
# cob_tidy

# -----------------------

libsay = Fiddle.dlopen('./say.so')

say = Fiddle::Function.new(
  libsay['say'],
  [Fiddle::TYPE_CONST_STRING, Fiddle::TYPE_CONST_STRING],
  Fiddle::TYPE_INT
)

# ------------------------


cob_init.('', '')
# cob_call.("say", 2, cob_argv);
say.('Hello, ', 'cobc! ')
cob_stop_run.(0)

