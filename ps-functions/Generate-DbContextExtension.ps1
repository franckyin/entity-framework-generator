function Generate-DbContextExtension {
    param (
        [array]$tables,
        [string]$namespaceRoot,
        [string]$outputPath
    )

    # Initialize Code String
    $dbSetCode = ""
    $dbSetCode += "        // Business Tables`r`n"

    # Create a list of DbSet lines
    $dbSetLines = foreach ($tableInfo in $tables) {
        $entityName = $tableInfo.Group[0].TableCodeName
        "        public DbSet<$($entityName)Entity> $($entityName)Entities { get; set; }"
    }
    foreach ($line in $dbSetLines) {
        $dbSetCode += "$line`r`n"
    }
    $dbSetCode += "`r`n"
    $dbSetCode += "        // Audit Tables`r`n"

    # Create a list of DbSet lines for Audit tables
    $dbSetLines = foreach ($tableInfo in $tables) {
        if ($tableInfo.Group[0].Audit -eq "x") {
            $entityName = $tableInfo.Group[0].TableCodeName
            "        public DbSet<$($entityName)AuditEntity> $($entityName)AuditEntities { get; set; }"
        }
    }
    foreach ($line in $dbSetLines) {
        $dbSetCode += "$line`r`n"
    }



    # Combine the template and the DbSet lines
    $finalDbContextContent = @"
using Microsoft.EntityFrameworkCore;
using $namespaceRoot.Entity;
using $namespaceRoot.Entity.Audit;
using $namespaceRoot.Entity.Core;

namespace $namespaceRoot
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

$dbSetCode
    }
}
"@

    # Replace CRLF (`r`n) with LF (`n`)
    $finalDbContextContent = $finalDbContextContent -replace "`r`n", "`n"
    $finalDbContextContent += "`n"

    # Write the file
    $outputFilePath = Join-Path $outputPath "ApplicationDbContext.cs"
    $writer = New-Object System.IO.StreamWriter($outputFilePath, $false)
    $writer.Write($finalDbContextContent)
    $writer.Close()
    Write-Host "Generated: $outputFilePath"
}
