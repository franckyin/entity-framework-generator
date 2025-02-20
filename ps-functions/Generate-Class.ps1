# Definition
function Generate-Class {
    param (
        [pscustomobject]$tableInfo,
        [string]$dataClassType,
        [string]$namespaceRoot,
        [string]$outputPath,
        [bool]$isAuditClass
    )

    # Class Name
    $className = "$($tableInfo.Name)$dataClassType"

    # Namespace
    $namespace = ""
    if ($tableInfo.Group[0].Namespace -ne "") {
        $namespace = "$namespaceRoot.$dataClassType.$($tableInfo.Group[0].Namespace)"
    }
    else {
        $namespace = "$namespaceRoot.$dataClassType"
    }

    # Extension
    $classExtensionString = ""

    if ($tableInfo.Group[0].Namespace -ne "Audit") {
        $classExtensionString = " : Base$dataClassType, I$dataClassType"
    }
    else {
        $classExtensionString = " : BaseAudit$dataClassType, IAudit$dataClassType"
    }


    # Strings
    $classOpeningString = @"
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using $namespaceRoot.$dataClassType;
using $namespaceRoot.$dataClassType.Core;
using $namespaceRoot.$dataClassType.Audit;

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
    foreach ($field in $tableInfo.Group) {

        if ($field.Decorator -eq "PK") {
            # Do not create field. All classes will extend a base class, which contains the PK ID.
        }
        else {
            $classBodyString += "$(Generate-FieldComment $field $dataClassType)"
            $classBodyString += "$(Generate-FieldDecorator $field $dataClassType)"
            $classBodyString += "$(Generate-FieldDefinition $field $dataClassType -isAuditClass $isAuditClass)"
            $classBodyString += "`n"
        }
    }

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
