ttfautohint-dll
===============
As of version 1.7.0.38-592d, [ttfautohint](https://www.freetype.org/ttfautohint) provides the
programming library _libttfautohint_ together with the executables. The library exports the function
[`TTF_autohint`](https://www.freetype.org/ttfautohint/doc/ttfautohint.html#function-ttf_autohint) which
can now be used in third-party applications. This repository contains a `Makefile` that simplifies
building a Windows DLL of libttfautohint. All dependencies from [FreeType](https://freetype.org)
and [HarfBuzz](https://www.freedesktop.org/wiki/Software/HarfBuzz) are also linked into the DLL
so that no further DLLs besides the Windows system libraries are needed.

Since the ttfautohint sources rely on [Gnulib](https://www.gnu.org/software/gnulib) which in turn requires
the [GNU build system](https://www.gnu.org/software/autoconf/manual/autoconf.html#The-GNU-Build-System)
(aka  _autotools_), the most straight-forward way to build the library for Windows is to use the
[MinGW](http://www.mingw.org) environment. The latter is available for Windows, e.g. as part of
[MSYS2](http://www.msys2.org), and as cross-compiler tools for Linux.

The provided `Makefile` downloads all required source packages and builds the ttfautohint library afterwards.

Usage
-----
* Under MinGW32 or MinGW64 on Windows  just call `make` to start the build process.
* When using a cross-compiler, the target host system must be specified via the `HOST` environment variable, e.g. `make HOST=x86_86-w64-mingw32` for a 64bit build.

Downloads
-----------
Pre-build packages can be downloaded from the [release section](https://github.com/mgieseki/ttfautohint-dll/releases).
They contain the ttfautohint DLL together with a corresponding import library and the include files.

