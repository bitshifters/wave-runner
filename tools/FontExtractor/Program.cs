using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace FontExtractor
{
    class Program
    {
        static System.Drawing.Size padding;
        static System.Drawing.Size tileSize;
        static System.Drawing.Size tileArrayDims;
        static int tileCount;
        static System.Drawing.Point origin;
        static List<string> glyphs = new List<string>();
        static string imageFilePath;
        static string outputFolder;

        delegate void commandLineArgParser(string arg);

        static readonly Dictionary<string, commandLineArgParser> commandLineParsers
            = new Dictionary<string, commandLineArgParser>
            {
//                { "rect:", ParseRect },
                { "origin:", ParseOrigin },
                { "tilecount:", ParseTileCount },
                { "tilesize:", ParseTileSize },
                { "imagefile:", ParseImageFilePath },
                { "glyphnames:", ParseGlyphNames },
                { "glyphsfile:", ParseGlyphsFile },
                { "padding:", ParsePadding },
                { "outputfolder:", ParseOutputFolder }
            };

        static void Main(string[] args)
        {
            ParseCommandLine(args);

            // TODO: Validation! Lots and lots of validation;

            var sourceFolder = System.IO.Path.GetDirectoryName(imageFilePath);

            if (sourceFolder == string.Empty)
            {
                sourceFolder = System.IO.Directory.GetCurrentDirectory();
                imageFilePath = Path.Combine(sourceFolder, imageFilePath);
            }

            string destFolder;

            if (outputFolder == string.Empty)
            {
                // dest folder wasn't specified. Default to source Folder.
                destFolder = sourceFolder;
            }
            else
            {
                // output folder was specified. Is it a valid path, or was it meant to be relative?
                destFolder = System.IO.Path.GetDirectoryName(outputFolder);
                if (destFolder == string.Empty)
                {
                    // It was probably meant to be relative. Make it relative to the source folder.
                    destFolder = Path.Combine(sourceFolder, outputFolder);
                }
            }

            System.IO.Directory.CreateDirectory(destFolder);

            var img = System.Drawing.Image.FromFile(imageFilePath);

            // Now we loop creating the tiles.

            int xJump = tileSize.Width + padding.Width;
            int yJump = tileSize.Height + padding.Height;

            int glyphIndex = 0;

            for (int y = 0; y < tileArrayDims.Height; y++)
            {
                int yOffset = origin.Y + y * yJump;
                for (int x = 0; x < tileArrayDims.Width; x++)
                {
                    int xOffset = origin.X + x * xJump;

                    var asBitmap = new System.Drawing.Bitmap(img);
                    var cropRect = new System.Drawing.Rectangle(xOffset, yOffset, tileSize.Width, tileSize.Height);
                    var cropped = asBitmap.Clone(cropRect, asBitmap.PixelFormat);

                    var outputName = Path.Combine(destFolder, glyphs[glyphIndex]) + ".png";
                    cropped.Save(outputName);
                    glyphIndex++;

                    if (glyphIndex >= tileCount)
                    {
                        goto doneGlyphs;
                    }
                }
            }

            doneGlyphs:
            // Insert empty. Make this optional
            var emptyImg = new System.Drawing.Bitmap(tileSize.Width, tileSize.Height);
            System.Drawing.Graphics g = System.Drawing.Graphics.FromImage(emptyImg);
            g.Clear(System.Drawing.Color.Black);
            emptyImg.Save(Path.Combine(destFolder, "empty.png"));
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

            // TODO: If image file not specified, read from input pipe.

        }

        //static void ParseRect(string arg)
        //{
        //    var afterSplit = arg.Split(',');
        //    extractRect = new System.Drawing.Rectangle(int.Parse(afterSplit[0]), int.Parse(afterSplit[1]), int.Parse(afterSplit[2]), int.Parse(afterSplit[3]));
        //}

        static void ParseOrigin(string arg)
        {
            var afterSplit = arg.Split(',');
            origin = new System.Drawing.Point(int.Parse(afterSplit[0]), int.Parse(afterSplit[1]));

        }

        static void ParseTileSize(string arg)
        {
            var afterSplit = arg.Split(',');
            tileSize = new System.Drawing.Size(int.Parse(afterSplit[0]), int.Parse(afterSplit[1]));
        }

        static void ParsePadding(string arg)
        {
            var afterSplit = arg.Split(',');
            padding = new System.Drawing.Size(int.Parse(afterSplit[0]), int.Parse(afterSplit[1]));
        }

        static void ParseTileCount(string arg)
        {
            var afterSplit = arg.Split(',');
            tileArrayDims = new System.Drawing.Size(int.Parse(afterSplit[0]), int.Parse(afterSplit[1]));

            if (afterSplit.Length >= 2)
            {
                tileCount = int.Parse(afterSplit[2]);
            }
            else
            {
                tileCount = tileArrayDims.Width * tileArrayDims.Height;
            }
        }

        static void ParseImageFilePath(string arg)
        {
            imageFilePath = arg;
        }

        static void ParseGlyphNames(string arg)
        {
            var afterSplit = arg.Split(',');
            foreach (var name in afterSplit)
            {
                glyphs.Add(name);
            }
        }

        static void ParseGlyphsFile(string arg)
        {
            var loaded = System.IO.File.OpenText(arg);
            string line;
            while ((line = loaded.ReadLine()) != null)
            {
                if (line != string.Empty)
                {
                    glyphs.Add(line.Trim());
                }
            }
        }

        static void ParseOutputFolder(string arg)
        {
            outputFolder = arg;
        }
    }
}
