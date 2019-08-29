@echo off
if "%PYTHON%"=="" set PYTHON=C:\Python27\python.exe

%PYTHON% bin/png2bbc.py --quiet -o build/bh_pic.dat --palette 7130 ./graphics/bh.png 1
%PYTHON% bin/png2bbc.py -o build/sgpic.dat --palette 4130 ./graphics/StarGliderTest.png 1
%PYTHON% bin/png2bbc.py --quiet -o build/scr_pic.dat --palette 4120 ./graphics/scr-beeb-winner.png 1

rem IF "%1" == "crunch" (

bin\exomizer.exe level -c -M256 build/bh_pic.dat@0x3000 -o build/bhpic.exo
bin\exomizer.exe level -c -M256 build/sgpic.dat@0x3000 -o build/sgpic.exo
bin\exomizer.exe level -c -M256 build/scr_pic.dat@0x3000 -o build/scrpic.exo

rem ) ELSE (
rem    echo No crunch.
rem )

