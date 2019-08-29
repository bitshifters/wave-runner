10 REM HARDWARE CHECK AND WARNING!
20 A%=0:X%=1:C%=(USR(&FFF4)AND&FF00)DIV256
30 IF C% < 3 OR C% > 5 THEN PRINT"SORRY, BBC MASTER REQUIRED!":END
40 PRINT '"WAVE RUNNER."
50 PRINT '"Released at Nova 19"
60 PRINT "by BitShifters."
61 PRINT '"Code:     VectorEyes and tom_seddon."
62 PRINT  "Graphics: Dethmmunk."
63 PRINT  "Music player/conversion: Simon M."
64 PRINT  "Player optimisation: Hexwab."
65 PRINT  "Music: 'Synergy Main Menu' by Scavenger."
66 PRINT  "Special thanks to KieranHJ!"
67 PRINT '"This demo has mostly been tested"
68 PRINT "on the B2 emulator. Support for older"
69 PRINT "emulators not guaranteed, sorry!"
70 PRINT '"If you experience any serious glitches"
80 PRINT "please report them to us at:"
90 PRINT '"https://bitshifters.github.io"
180 PRINT '"Let's get going...";
190 *RUN Main
