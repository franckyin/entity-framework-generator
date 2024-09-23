# Definition
function Generate-BaseClass {
    param (
        [string]$dataClassType,
        [string]$namespaceRoot,
        [string]$outputPath
    )

    # Class Name
    $className = "Base$dataClassType"

    # Namespace
    $namespace = ""
    if ($tableInfo.Group[0].Namespace -ne "") {
        $namespace = "$namespaceRoot.$dataClassType.$($tableInfo.Group[0].Namespace)"
    }
    else {
        $namespace = "$namespaceRoot.$dataClassType"
    }

    # Strings
    $classOpeningString = @"
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace $namespace
{
    public class $className
    {

"@
    $classBodyString = ""
    $classClosingString = @"
    }
}
"@

    # Fields
    if ($dataClassType -eq "Entity") {
        $classBodyString += "        [Key, DatabaseGenerated(DatabaseGeneratedOption.Identity)]"
        $classBodyString += "`n"
    }
    $classBodyString += "        public string Id { get; set; }"
    $classBodyString += "`n"

    # Class Text
    $fileContents = $classOpeningString + $classBodyString + $classClosingString

    # Output path
    $classOutputPath = "$outputPath\$dataClassType"
    if ($tableInfo.Group[0].Namespace -ne "") {
        $classOutputPath += "\$($tableInfo.Group[0].Namespace)"
    }

    # Output Repository
    if (-not (Test-Path $classOutputPath)) {
        $newItemOutput = New-Item -Path $classOutputPath -ItemType Directory
        Write-Host "New Item $classOutputPath"
    }

    # Write the file
    $filePath = "$classOutputPath\$className.cs"
    Set-Content -Path $filePath -Value $fileContents
    Write-Host "Generated: $filePath"
}
