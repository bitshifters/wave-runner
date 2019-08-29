10 REM HARDWARE CHECK AND WARNING!
20 A%=0:X%=1:C%=(USR(&FFF4)AND&FF00)DIV256
30 IF C% < 3 OR C% > 5 THEN PRINT"SORRY, BBC MASTER REQUIRED!":END
35 CLS
40 PRINT '"WAVE RUNNER."
45 PRINT '"Originally released at Nova 2019"
50 PRINT "by BitShifters."
60 PRINT '"v1.1 (Aug '19): Minor bugfixes/tidy-ups."
61 PRINT '"Code:     VectorEyes and tom_seddon."
62 PRINT  "Graphics: Dethmunk."
63 PRINT  "Music player/conversion: Simon M."
64 PRINT  "Player optimisation: Hexwab."
65 PRINT  "Music: 'Synergy Main Menu' by Scavenger."
66 PRINT  "Special thanks to KieranHJ!"
67 PRINT '"This demo has mostly been tested on the"
68 PRINT "B2 emulator. Older emulators may not"
69 PRINT "run it properly, sorry! If you see any"
70 PRINT "bad glitches please report them to us:"
90 PRINT '"https://bitshifters.github.io"
180 PRINT '"Let's get going...";
190 *RUN Main
