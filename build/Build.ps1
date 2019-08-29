# Set up folders and config

$outputFolder = $pwd.ToString() + "\..\output"
$intFolder = $pwd.ToString() + "\..\intermediate"

# Extract fonts
# TODO: Refactor this so that ALL parameters are specified in external file. So we can just have one file per font, and trivially try different fonts
$fontSourceFolder = $pwd.ToString() + "\..\fonts"
$fontsOutputFolder = $intFolder + "\font\razor14x14\images\"

$extractorPath = $outputFolder + "\FontExtractor\Release\FontExtractor.exe"
$fontSourceFile = $fontSourceFolder + "\Charset_1Bitplan.PNG"
$glyphsFile = $fontSourceFolder + "\CharsetRazor.txt"

$extractParams = "imagefile:" + $fontSourceFile + " origin:1,0 padding:2,1 tilecount:20,3,56 tilesize:14,14 glyphsfile:" + $glyphsFile + " inputfolder:" + $fontSourceFolder +  " outputfolder:" + $fontsOutputFolder
$extractParamsArray = $extractParams.Split(" ")

& "$extractorPath" $extractParamsArray

# Generate raster code
$rasterGenPath = $outputFolder + "\RasterGen\Release\RasterGen.exe"
$rasterGenInputPath = $fontsOutputFolder
$rasterGenOutputPath = $intFolder + "\font\razor14x14\code\"

$rasterGenParams = "inputfolder:" + $rasterGenInputPath + " outputfolder:" + $rasterGenOutputPath
$rasterGenParamsArray = $rasterGenParams.Split(" ")

# Actually call RasterGen.exe passing the inputFolder and outputFolder arguments.
& "$rasterGenPath" $rasterGenParamsArray

# TODO: Call BeebAsm to build the actual code!
# TODO2: input validation, output validation, error messages, etc.

Write-Host "Press any key to continue..."
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","")]
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host
