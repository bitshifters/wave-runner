# wave-runner: start here

Wave Runner, the Bitshifters demo for the BBC Master released at Nova 2019 (`BSNova19.ssd`): stable-raster
effects, a 14x14 font scroller, logo and picture sequences, with music. Demo source in beebasm, with
Python asset scripts and three small C# build tools. Committed by VectorEyes.

| | |
|---|---|
| GitHub | https://github.com/bitshifters/wave-runner (public, Bitshifters org) |
| Local path | D:\beeb\mine\wave-runner (moved from OneDrive\BEEB\Repos\wave-runner on 2026-11-22) |
| Branch | `master` (only branch) |
| Last commit | 2019-08-30: Updated the Readme (version 1.1, August 2019) |

## What's in here
- `main.6502`, `demoStartup.6502`, `Patterns*.6502`, `sinTables.6502` - the top level; `core/`, `effects/`,
  `scripting/`, `lib/`, `audio/` (music and exomizer 2), `fonts/`, `graphics/`.
- `bin/` - Python asset scripts (`png2bbc.py`, `make_blobs.py`, `shellcmd.py`, ...) and `exomizer.exe` (v3).
- `tools/` - C# sources for FontExtractor, RasterGen, ImageAnalyser (`tools\Tools.sln`, Visual Studio 2019);
  `output/` - their committed Release EXEs.
- `template.ssd` - the disc the build adds files to; `make.exe` - a GNU make copy in the repo.
- `write_up/` - the making-of write-up (text, images, GIFs); `reference_docs/`.

## Build and run
- `make`: the repo's own Makefile (`build` target) - **blocked**: its Python scripts are Python 2
  (`bin/shellcmd.py` fails at `print datetime...` on Python 3) and README asks for Python 2.x, which is not
  on this machine. Also wants `beebasm` on the PATH (set `BEEBASM=..\..\Bin\beebasm.exe`).
- Other targets: `clean`, and `tom_dist` / `b2` / `tags` (Tom Seddon's macOS helpers, not for here).
- Output: `BSNova19.ssd` (Master 128). Not built on 2026-11-22.
- To build again: port `bin/*.py` to Python 3 (mostly `print` statements), or install Python 2.7 and pass `PYTHON=`.

## Local changes
- None. Nothing new added except `START_HERE.md` (the existing Makefile was left as it is).

## Status and next steps
- Released (Nova 2019, v1.1 August 2019); three commits, no plan notes. Archive / reference.

## See also
- `README.md` (build dependencies), `write_up/Contents.txt`, `write_up/Post mortem.txt`.
