# Definition
function Generate-Interface {
    param (
        [string]$dataClassType,
        [string]$namespaceRoot,
        [string]$outputPath,
        [bool]$isAuditExtension
    )

    # Interface name string and namespace
    $interfaceName = ""
    $interfaceExtensionString = ""
    $namespace = ""
    $usingString = ""
    if ($isAuditExtension -eq $false) {
        $interfaceName = "I$dataClassType"
        $namespace = "$namespaceRoot.$dataClassType"
    }
    else {
        $interfaceName = "IAudit$dataClassType"
        $interfaceExtensionString = " : I$dataClassType"
        $namespace = "$namespaceRoot.$dataClassType.Audit"
        $usingString = "using $namespaceRoot.$dataClassType;`n"
    }

    # Strings
    $interfaceOpeningString = @"
$usingString
namespace $namespace
{
    public interface $interfaceName$interfaceExtensionString
    {

"@
    $interfaceBodyString = ""
    $interfaceClosingString = @"
    }
}
"@

    # Fields
    if ($isAuditExtension -eq $false) {
        $interfaceBodyString += "        public int Id { get; set; }"
        $interfaceBodyString += "`n"
    }
    else {
        $interfaceBodyString += "        public int CacheId { get; set; }"
        $interfaceBodyString += "`n"
    }

    # interface Text
    $fileContents = $interfaceOpeningString + $interfaceBodyString + $interfaceClosingString

    # Output path
    $interfaceOutputPath = "$outputPath\$dataClassType"
    if ($isAuditExtension -eq $true) {
        $interfaceOutputPath += "\Audit"
    }

    # Output Repository
    if (-not (Test-Path $interfaceOutputPath)) {
        $newItemOutput = New-Item -Path $interfaceOutputPath -ItemType Directory
        Write-Host "New Item $interfaceOutputPath"
    }

    # Write the file
    $filePath = "$interfaceOutputPath\$interfaceName.cs"
    Set-Content -Path $filePath -Value $fileContents
    Write-Host "Generated: $filePath"
}
