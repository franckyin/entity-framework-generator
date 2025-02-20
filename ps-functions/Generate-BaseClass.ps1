# Definition
function Generate-BaseClass {
    param (
        [string]$dataClassType,
        [string]$namespaceRoot,
        [string]$outputPath,
        [bool]$isAuditExtension
    )

    # Class name string and namespace
    $className = ""
    $classExtensionString = ""
    $namespace = ""
    $usingString = ""
    if ($isAuditExtension -eq $false) {
        $className = "Base$dataClassType"
        $classExtensionString = " : I$dataClassType"
        $namespace = "$namespaceRoot.$dataClassType"
    }
    else {
        $className = "BaseAudit$dataClassType"
        $classExtensionString = " : Base$dataClassType, IAudit$dataClassType"
        $namespace = "$namespaceRoot.$dataClassType.Audit"
        $usingString = "using $namespaceRoot.$dataClassType;`n"
    }

    # Strings
    $classOpeningString = @"
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
$usingString
namespace $namespace
{
    public class $className$classExtensionString
    {

"@
    $classBodyString = ""
    $classClosingString = @"
    }
}
"@

    # Fields
    if ($isAuditExtension -eq $false) {
        if ($dataClassType -eq "Entity") {
            $classBodyString += "        [Key, DatabaseGenerated(DatabaseGeneratedOption.Identity)]"
            $classBodyString += "`n"
        }
        $classBodyString += "        public int Id { get; set; }"
        $classBodyString += "`n"
    }
    else {
        $classBodyString += "        public int CacheId { get; set; }"
        $classBodyString += "`n"
    }

    # Class Text
    $fileContents = $classOpeningString + $classBodyString + $classClosingString

    # Output path
    $classOutputPath = "$outputPath\$dataClassType"
    if ($isAuditExtension -eq $true) {
        $classOutputPath += "\Audit"
    }

    # Output Repository
    if (-not (Test-Path $classOutputPath)) {
        $newItemOutput = New-Item -Path $classOutputPath -ItemType Directory
        Write-Host "New Item $classOutputPath"
    }

    # Replace CRLF (`r`n) with LF (`n`)
    $fileContents = $fileContents -replace "`r`n", "`n"
    $fileContents += "`n"

    # Write the file
    $filePath = "$classOutputPath\$className.cs"
    $writer = New-Object System.IO.StreamWriter($filePath, $false)
    $writer.Write($fileContents)
    $writer.Close()
    Write-Host "Generated: $filePath"
}
