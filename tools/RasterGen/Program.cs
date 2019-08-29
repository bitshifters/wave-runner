using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

using System.Collections.Specialized;

namespace RasterGen
{
    class Program
    {
        // Represents commands that we can execute as the raster beam is scanning.
        // Some of these are simple 6502 instructions (e.g. 'NOP') but some are more
        // complicated (e.g. write 'foreground' or 'background' colour to palette register).
        enum RasterCommand
        {
            NOP,
            WriteBlack,
            WriteWhite
        }

        delegate void commandLineArgParser(string arg);

        static readonly Dictionary<string, commandLineArgParser> commandLineParsers
            = new Dictionary<string, commandLineArgParser>
            {
                { "inputfolder:", ParseInputFolder },
                { "outputfolder:", ParseOutputFolder },
                { "glyphsfile:",ParseGlyphsFile },
            };

        static string inputFolder = "";
        static string outputFolder = "";
        static List<string> glyphsFile = new List<string>();

        class GlyphLine
        {
            public List<RasterCommand> code;
        }

        class Glyph
        {
            public GlyphLine[] lines;
        }


        static string white = "STA &FE21:";
        static string black = "STX &FE21:";
        static string doNothing = "NOP:";

        struct RasterCommandInfo
        {
            public string assemblerCode;
            public int cycles;
            public System.Drawing.Color colour;     // Will be 'empty' if this command does not change the colour

            public RasterCommandInfo(string assemblerCode, int cycles, System.Drawing.Color colour)
            {
                this.assemblerCode = assemblerCode;
                this.cycles = cycles;
                this.colour = colour;
            }
        }

        static Dictionary<RasterCommand, RasterCommandInfo> CommandsInfo
            = new Dictionary<RasterCommand, RasterCommandInfo>
            {
                { RasterCommand.NOP, new RasterCommandInfo(doNothing, 2, System.Drawing.Color.Empty) },
                { RasterCommand.WriteBlack, new RasterCommandInfo(black, 4, System.Drawing.Color.Black) },
                { RasterCommand.WriteWhite, new RasterCommandInfo(white, 4, System.Drawing.Color.White) }
            };

        static void Main(string[] args)
        {
            // For each glyph image:
            // - Confirm correct size. (Pad out functionality?)
            // - For each line:
            //   - Convert to a form that can be expressed as raster.
            //   - Add to hashmap if not already there.
            //   - Build raster instructions if necessary.

            ParseCommandLine(args);

            // Need an IComparer<List<RasterCommand>>.....

            var glyphLines = new SortedSet<List<RasterCommand>>(
                Comparer<List<RasterCommand>>.Create(
                    (a, b) =>
                    {
                        if (a.Count > b.Count)
                            return -1;
                        else if (a.Count < b.Count)
                            return 1;
                        else
                        {
                            for (int i = 0; i < a.Count; i++)
                            {
                                var comparisonResult = a[i].CompareTo(b[i]);
                                if (comparisonResult != 0)
                                    return comparisonResult;
                            }
                            return 0;
                        }
                    }
                    ));

            // Ensure we always have an 'empty' (blank) line that does nothing, that we can insert at the
            // end of every glyph.
            // TODO: Make whether to end every glyph with an empty line an option.
            List<RasterCommand> emptyLine = Enumerable.Repeat(RasterCommand.NOP, 17).ToList();
            glyphLines.Add(emptyLine);

            Dictionary<string, Glyph> processedGlyphs = new Dictionary<string, Glyph>();

            if (inputFolder == string.Empty)
            {
                // source folder wasn't specified. Default to current Folder.
                inputFolder = System.IO.Directory.GetCurrentDirectory();
            }
            else
            {
                // input folder was specified. Is it a valid path, or was it meant to be relative?
                string queryFolder = System.IO.Path.GetDirectoryName(inputFolder);
                if (queryFolder == string.Empty)
                {
                    // It was probably meant to be relative. Make it relative to the current folder.
                    inputFolder = Path.Combine(System.IO.Directory.GetCurrentDirectory(), inputFolder);
                }
            }

            string destFolder;

            if (outputFolder == string.Empty)
            {
                // dest folder wasn't specified. Default to source Folder.
                destFolder = inputFolder;
            }
            else
            {
                // output folder was specified. Is it a valid path, or was it meant to be relative?
                destFolder = System.IO.Path.GetDirectoryName(outputFolder);
                if (destFolder == string.Empty)
                {
                    // It was probably meant to be relative. Make it relative to the source folder.
                    destFolder = Path.Combine(inputFolder, outputFolder);
                }
            }

            System.IO.Directory.CreateDirectory(destFolder);

            //var pngFiles = System.IO.Directory.EnumerateFiles(inputFolder, "*.png");

            int lineCount = 0;
            int duplicateCount = 0;

            foreach (var glyphName in glyphsFile)
            {
                string png = Path.Combine(inputFolder, glyphName + ".png");
                //string glyphName = System.IO.Path.GetFileNameWithoutExtension(png);

                // Access the actual pixels of the image...
                var imgBitmap = new System.Drawing.Bitmap(png);
                var glyph = new Glyph
                {
                    lines = new GlyphLine[imgBitmap.Height]
                };

                for (int i = 0; i < imgBitmap.Height; i++)
                {
                    var pixels = new List<bool>();

                    // Create a line of bools representing pixel on/off
                    for (int j = 0; j < imgBitmap.Width; j++)
                    {
                        pixels.Add(imgBitmap.GetPixel(j, i).GetBrightness() != 0 ? true : false);
                    }

                    var code = CreateGlyphLine(pixels, glyphName);

                    // Add to dictionary of line drawing functions.
                    if (glyphLines.Add(code))
                    {
                        lineCount++;
                    }
                    else
                    {
                        duplicateCount++;
                    }
                    glyph.lines[i] = new GlyphLine();
                    glyph.lines[i].code = code;
                }

                processedGlyphs.Add(glyphName, glyph);
            }

            // Now that we have processed all the files, we need to output the lines-code and the
            // info about which glyphs use which lines.
            var lineList = glyphLines.ToList();

            string linesCode = ".glyphLines\n";

            string lineAdressesHigh = ".LineAddressTableHigh\n";
            string lineAdressesLow = ".LineAddressTableLow\n";

            int lineIndex = 0;
            foreach (var lineCode in lineList)
            {
                string lineLabel = "line" + lineIndex.ToString();
                linesCode += "." + lineLabel + "\n";
                foreach (var rasterCommand in lineCode)
                {
                    linesCode += CommandsInfo[rasterCommand].assemblerCode;
                }
                linesCode += "\n";
                linesCode += "JMP lineReturn\n";

                lineAdressesHigh += "EQUB HI(" + lineLabel + ")\n";
                lineAdressesLow += "EQUB LO(" + lineLabel + ")\n";

                lineIndex++;
            }
            linesCode += "processedLineCount = " + lineList.Count.ToString() + "\n";

            string glyphsCode = ".glyphs\n";
            string glyphAddressesLow = ".glyphAddressTableLow\n";
            string glyphAddressesHigh = ".glyphAddressTableHigh\n";

            var dbgLinesImage = new System.Drawing.Bitmap(34, lineList.Count, System.Drawing.Imaging.PixelFormat.Format24bppRgb);

            int dbgLineIndex = 0;
            foreach (var lineCode in lineList)
            {
                CreatePixelLine(dbgLinesImage, dbgLineIndex, lineCode);
                dbgLineIndex++;
            }

            // Write out the debug image here!
            dbgLinesImage.Save(Path.Combine(destFolder, "uniqueGlyphLines.png"));

            var emptyLineIndex = lineList.FindIndex(x =>
            {
                return x.SequenceEqual(emptyLine);
            });

            foreach (var glyph in processedGlyphs)
            {
                string glyphName = glyph.Key;
                string label = "glyph_" + glyphName;
                glyphsCode += "." + label + "\n";
                // The +1 is for the empty line. Make this optional!
                glyphsCode += "EQUB " + (glyph.Value.lines.Length + 1).ToString() + " \\\\ Line count\n";     // Linecount.
                foreach (var line in glyph.Value.lines)
                {
                    var codeIndex = lineList.FindIndex(x =>
                        {
                            return x.SequenceEqual(line.code);
                        }
                    );

                    glyphsCode += "EQUB " + codeIndex + ":";
                }

                // Insert empty line. TODO: Make this optional!
                glyphsCode += "EQUB " + emptyLineIndex;

                glyphsCode += "\n";

                glyphAddressesHigh += "EQUB HI(" + label + ")\n";
                glyphAddressesLow += "EQUB LO(" + label + ")\n";
            }

            glyphsCode += "processedGlyphCount = " + processedGlyphs.Count.ToString() + "\n";

            //string final = lineAdressesHigh + lineAdressesLow + glyphAddressesHigh + glyphAddressesLow + glyphsCode + linesCode;
            //System.IO.File.WriteAllText(Path.Combine(destFolder,"GlyphOutput.6502"), final);
            System.IO.File.WriteAllText(Path.Combine(destFolder, "LineAddressesHigh.6502"), lineAdressesHigh);
            System.IO.File.WriteAllText(Path.Combine(destFolder, "LineAddressesLow.6502"), lineAdressesLow);
            System.IO.File.WriteAllText(Path.Combine(destFolder, "GlyphAddressesHigh.6502"), glyphAddressesHigh);
            System.IO.File.WriteAllText(Path.Combine(destFolder, "GlyphAddressesLow.6502"), glyphAddressesLow);
            System.IO.File.WriteAllText(Path.Combine(destFolder, "GlyphLines.6502"), linesCode);
            System.IO.File.WriteAllText(Path.Combine(destFolder, "Glyphs.6502"), glyphsCode);

            // Iterate over lineList, write each line to lineOutput, with labels in-between.
            // (We'll need to keep track of code byte size later and move them around to avoid any crossing
            // page boundaries).

            // Then write out BeebAsm code that is a table of addresses of line-drawing fns.

            // Then go over each glyph, create BeebAsm declarations (labels) for each one, and write out
            // one byte (lineCount) and another byte which is line index.
        }

        static void CreatePixelLine(System.Drawing.Bitmap targetBmp, int lineIndex, List<RasterCommand> commands)
        {
            int xPos = 0;
            System.Drawing.Color currentCol = System.Drawing.Color.Black;
            foreach (var command in commands)
            {
                var info = CommandsInfo[command];
                if (info.colour != System.Drawing.Color.Empty)
                {
                    currentCol = info.colour;
                }
                for (int i = 0; i < info.cycles; i++)
                {
                    targetBmp.SetPixel(xPos, lineIndex, currentCol);
                    xPos++;
                }
            }

            // TODO: Need to check that xPos == expected width!

        }

        static List<RasterCommand> CreateGlyphLine(List<bool> pixels, string glyphName)
        {
            bool currentValue = false;      // Start black
            int cyclesLeft = 0;
            int totalCycles = 0;

            var line = new List<RasterCommand>();

            foreach (var pixel in pixels)
            {
                if (cyclesLeft == 0)
                {
                    // Must write an instruction and reset cyclesLeft
                    if (currentValue != pixel)
                    {
                        line.Add(pixel ? RasterCommand.WriteWhite : RasterCommand.WriteBlack);
                        currentValue = pixel;
                        cyclesLeft = 4;
                    }
                    else
                    {
                        line.Add(RasterCommand.NOP);
                        cyclesLeft += 2;
                    }
                }

                // Current instr still executing. Decrement cyclesLeft.
                cyclesLeft -= 2;
                totalCycles += 2;
            }

            // Now write the final "back to black as soon as we can, then nops"...
            while (totalCycles < 34 || cyclesLeft > 0)
            {
                if (cyclesLeft == 0)
                {
                    if (currentValue)
                    {
                        line.Add(RasterCommand.WriteBlack);
                        currentValue = false;
                        cyclesLeft = 4;
                    }
                    else
                    {
                        line.Add(RasterCommand.NOP);
                        cyclesLeft = 2;
                    }
                }

                cyclesLeft -= 2;
                totalCycles += 2;
            }

            if (totalCycles > 34)
            {
                Console.WriteLine("Problem. Glyph '" + glyphName + "' had line with more than 34 cycles.");
            }

            return line;
        }

        static void ParseCommandLine(string[] args)
        {
            foreach (string arg in args)
            {
                // arg is either of the form "argName:remainder" or just "argName".
                foreach (string key in commandLineParsers.Keys)
                {
                    if (arg.StartsWith(key))
                    {
                        commandLineParsers[key](arg.Substring(key.Length));
                        break;
                    }
                }
            }
        }

        static void ParseInputFolder(string arg)
        {
            inputFolder = arg;
        }

        static void ParseOutputFolder(string arg)
        {
            outputFolder = arg;
        }

        static void ParseGlyphsFile(string arg)
        {
            var loaded = System.IO.File.OpenText(arg);
            string line;
            while ((line = loaded.ReadLine()) != null)
            {
                if (line != string.Empty)
                {
                    glyphsFile.Add(line.Trim());
                }
            }

            // The font converter always adds an empty one in at the end when
            // writing, so add a corresponding one in when reading.
            glyphsFile.Add("empty");
        }
    }
}
