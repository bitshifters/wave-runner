# Wave Runner Source Code
This demo started out in August 2018 as a few snippets of code thrown together to help learn 6502 coding,
developed into a few effects that used 'stable raster' techniques, and then evolved further (with much collaboration!)
to eventually become Wave Runner.

# Build BSNova19.ssd

Build on Windows or OS X. (It should work on inux too, but Mono wouldn't run the
.NET EXEs when I tried, for reasons not entirely clear...)

## Windows dependencies

Requirements:

* Python 2.x
* [BeebAsm](https://github.com/stardot/beebasm) on PATH

All additional dependencies are included.

## OS X dependencies

* Python 2.x
* [Exomizer v2.0.9](https://github.com/bitshifters/exomizer) - run
  `make` in `exomizer2/src` folder to build the appropriate version.
  Makefile assumes it's on the PATH and called `exomizer2`
* [Exomizer v3.0.2](https://bitbucket.org/magli143/exomizer/wiki/Home) -
  grab the 3.0.2 zip and build. Makefile assumes it's on the PATH and
  called `exomizer`
* [BeebAsm](https://github.com/stardot/beebasm) - follow repo
  instructions to build. Makefile assumes it's on the PATH and called
  `beebasm`
* [Mono](https://www.mono-project.com/) and
  [libgdiplus](https://www.mono-project.com/docs/gui/libgdiplus/) -
  MacPorts has suitable versions
* GNU Make

## Build process

Type `make`, producing `BSNova19.ssd`.

Set variables on the command line to manually specify paths to
executables:

* `PYTHON=` for Python (default: `python`)
* `BEEBASM` for BeebAsm (default: `beebasm`)
* (OS X) `EXOMIZER3` for Exomizer v3 (default: `exomizer`)
* (OS X) `EXOMIZER2` for Exomizer v2 (default: `exomizer2`)
* (OS X) `MONO` for Mono (default: `mono`)

For example:

    make BEEBASM=~/beebasm/beebasm EXOMIZER=~/exomizer-3.0.2/src/exomizer

Type `make clean` to remove intermediate files, forcing a full build
next time.

# Build tools

Build on Windows.

## Windows dependencies

* Visual Studio 2017

## Build process

Load `tools\Tools.sln` into Visual Studio.

Build.

Commit new EXEs/DLLs after changing - they are part of the repo.
