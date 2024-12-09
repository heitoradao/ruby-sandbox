# libcobc bindings!

With this bindings, it's possible to call cobol programs from your ruby programs.

For doing so, the cobol program must be compiled as a dynamic module.
There must be a file called `say.so`.

There is a shell script called `build.sh` wich is configured to call the compiler with correct parameter.

Function `cob_init()` must be called before calling any other cobol callings.

