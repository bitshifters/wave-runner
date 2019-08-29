using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

using System.Collections.Specialized;

namespace ImageAnalyser
{
    class Program
    {
        delegate void commandLineArgParser(string arg);

        static readonly Dictionary<string, commandLineArgParser> commandLineParsers
            = new Dictionary<string, commandLineArgParser>
            {
                { "inputfolder:", ParseInputFolder },
                { "outputfolder:", ParseOutputFolder },
                { "imagefile:",ParseSourceFile },
            };

        static string inputFolder = "";
        static string outputFolder = "";
        static List<string> imagesFile = new List<string>();

        static void Main(string[] args)
        {
            ParseCommandLine(args);

            // Need an IComparer<List<RasterCommand>>.....

            var uniqueLines = new SortedSet<List<System.Drawing.Color>>(
                Comparer<List<System.Drawing.Color>>.Create(
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
                                var colA = a[i];
                                var colB = b[i];

                                if (colA.R > colB.R) return 1;
                                else if (colA.R < colB.R) return -1;
                                else if (colA.G > colB.G) return 1;
                                else if (colA.G < colB.G) return -1;
                                else if (colA.B > colB.B) return 1;
                                else if (colA.B < colB.B) return -1;
                            } 
                            return 0;
                        }
                    }
                    ));


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
                var fullPath = Path.GetFullPath(outputFolder);
                // output folder was specified. Is it a valid path, or was it meant to be relative?
                destFolder = System.IO.Path.GetDirectoryName(fullPath);
                if (destFolder == string.Empty)
                {
                    // It was probably meant to be relative. Make it relative to the source folder.
                    destFolder = Path.Combine(inputFolder, outputFolder);
                }
            }

            System.IO.Directory.CreateDirectory(destFolder);

            int lineCount = 0;
            int duplicateCount = 0;

            foreach (var fileName in imagesFile)
            {
                string png = Path.Combine(inputFolder, fileName + ".png");

                // Access the actual pixels of the image...
                var imgBitmap = new System.Drawing.Bitmap(png);

                List<List<System.Drawing.Color>> imageLines = new List<List<System.Drawing.Color>>(imgBitmap.Height);

                for (int i = 0; i < imgBitmap.Height; i++)
                {
                    List<System.Drawing.Color> line = new List<System.Drawing.Color>(imgBitmap.Width);

                    // Create a line of pixels
                    for (int j = 0; j < imgBitmap.Width; j++)
                    {
                        line.Add(imgBitmap.GetPixel(j, i));
                    }

                    // Add to dictionary of lines within the image
                    if (uniqueLines.Add(line))
                    {
                        lineCount++;
                    }
                    else
                    {
                        duplicateCount++;
                    }

                    imageLines.Add(line);
                }

                List<int> sourceImageUniqueIndices = new List<int>(imgBitmap.Height);

                var uniqeLinesList = uniqueLines.ToList();

                foreach(var imageLine in imageLines)
                {
                    sourceImageUniqueIndices.Add(uniqeLinesList.FindIndex(x =>
                        { return x.SequenceEqual(imageLine); }
                    ));
                }

                // Now we have a list which gives every source image line's index in the set of unique lines.
                // We output this, along with the packed imaged itself.

                string indicesOutput = "";
                foreach (var index in sourceImageUniqueIndices)
                {
                    indicesOutput += "EQUB " + index.ToString() + "\n";
                }

                System.IO.File.WriteAllText(Path.Combine(destFolder, fileName + "_indices.6502"), indicesOutput);

                int numLinesFirstImage = uniqeLinesList.Count > 32 ? 32 : uniqeLinesList.Count;
                int numLinesSecondImage = uniqeLinesList.Count > 32 ? uniqeLinesList.Count - 32 : 0;

                // Create the image of unique lines
                var bm = new System.Drawing.Bitmap(imgBitmap.Width, numLinesFirstImage * 8);
                for (int y = 0; y < numLinesFirstImage; y++)
                {
                    for (int lineRep = 0; lineRep <= 7; lineRep++)
                    {
                        for (int x = 0; x < bm.Width; x++)
                        {
                            bm.SetPixel(x, y * 8 + lineRep, uniqueLines.ElementAt(y).ElementAt(x));
                        }
                    }
                }
                bm.Save(Path.Combine(destFolder, fileName + "uniquelines.png"));

                if (numLinesSecondImage > 0)
                {
                    bm = new System.Drawing.Bitmap(imgBitmap.Width, numLinesSecondImage * 8);
                    for (int y = 0; y < numLinesSecondImage; y++)
                    {
                        for (int lineRep = 0; lineRep <= 7; lineRep++)
                        {
                            for (int x = 0; x < bm.Width; x++)
                            {
                                bm.SetPixel(x, y * 8 + lineRep, uniqueLines.ElementAt(y + 32).ElementAt(x));
                            }
                        }
                    }
                    bm.Save(Path.Combine(destFolder, fileName + "uniquelines_shadow.png"));
                }
            }
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

        static void ParseSourceFile(string arg)
        {
            imagesFile.Add(arg.Trim());
        }
    }
}
