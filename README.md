# package-llvm

The LLVM Project is a collection of modular and reusable compiler and toolchain technologies. Despite its name, LLVM has little to do with traditional virtual machines, though it does provide helpful libraries that can be used to build them. The name "LLVM" itself is not an acronym; it is the full name of the project. <http://llvm.org>

See <http://releases.llvm.org> for releases.

## Includes

* [LLVM](http://llvm.org)
* [Clang](http://clang.llvm.org)
* [LLDB](http://lldb.llvm.org)
* [libc++](http://libcxx.llvm.org)
* [compiler-rt](http://compiler-rt.llvm.org)
* [polly](http://polly.llvm.org)
* [lld](http://lld.llvm.org)

## Generating the RPM package

Edit the `Makefile` to ensure that you are setting the intended version, then run `make`.

```bash
make
```
