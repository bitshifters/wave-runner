# Set up folders and config

$outputFolder = $pwd.ToString() + "\..\output\"
$intFolder = $pwd.ToString() + "\..\intermediate\"

$imageSourceFolder = $pwd.ToString() + "\..\graphics"
$imageOutputFolder = $intFolder
$sourceFileName = "bslogo_single"

$extractorPath = $outputFolder + "\ImageAnalyser\Release\ImageAnalyser.exe"

$extractParams = "imagefile:" + $sourceFileName + " inputfolder:" + $imageSourceFolder +  " outputfolder:" + $imageOutputFolder
$extractParamsArray = $extractParams.Split(" ")

& "$extractorPath" $extractParamsArray

Write-Host "Press any key to continue..."
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","")]
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host
