# Dot Sourcing
. .\ps-functions\Generate-AuditField.ps1
. .\ps-functions\Generate-BaseClass.ps1
. .\ps-functions\Generate-Class.ps1
. .\ps-functions\Generate-DbContextExtension.ps1
. .\ps-functions\Generate-FieldComment.ps1
. .\ps-functions\Generate-FieldDecorator.ps1
. .\ps-functions\Generate-FieldDefinition.ps1

# Definition
function Main {
    param (
    )

    # Load Configuration
    $configPath = ".\files\config.json"
    $config = Get-Content $configPath -raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

    # Load Field Data
    $fields = Import-Csv -Path ".\files\fields.csv"

    # Group by table name "TableCodeName"
    $tables = $fields | Group-Object -Property TableCodeName

    # Output Path
    $outputPath = $config.outputPath

    # Clear Output Repo
    if ($outputPath -ne "" -and $null -ne $outputPath) {
        
        # Confirm deletion
        $confirm = Read-Host "ARE YOU SURE: CONFIRM DELETE CONTENTS OF: $($outputPath)? (Y/N)"
        if ($confirm -eq 'Y') {
            Remove-Item "$outputPath\*" -Recurse -Force
        }
        else {
            Write-Host "Deletion canceled."
        }

        # Generate classes
        foreach ($tableInfo in $tables) {
            Write-Host "--- $($tableInfo.Group[0].Namespace) - $($tableInfo.Name) ---"
            Generate-Class $tableInfo "Entity" $config.namespaceRoot $outputPath
            Generate-Class $tableInfo "Domain" $config.namespaceRoot $outputPath
            Generate-Class $tableInfo "Dto" $config.namespaceRoot $outputPath
    
            # Audit Trail classes
            if ($tableInfo.Group[0].Audit -eq "x") {
    
                # Create Audit Table Info PS Custom Object
                $auditTableInfo = [pscustomobject]@{
                    Name  = $tableInfo.Name + "Audit"
                    Group = @()
                }
    
                $tableInfo.Group.ForEach(
                    {
                        # Replace Each Namespace with "Audit"
                        $_.Namespace = "Audit"

                        # Find fields:
                        # With Decorator "PK"
                        # With audit properties of either:
                        # On the Join side of a Many to Many relationship
                        # On the Child side of a Parent-Child relationship
                        if ($_.AuditProp -in @("N - J", "J - J", "P", "C")) {
                            $auditTableInfo.Group += @(Generate-AuditField($_))
                        }
                        $auditTableInfo.Group += @($_)
                    }
                )
    
                # Generate audit trail classes
                Generate-Class $auditTableInfo "Entity" $config.namespaceRoot $outputPath
                Generate-Class $auditTableInfo "Domain" $config.namespaceRoot $outputPath
                Generate-Class $auditTableInfo "Dto" $config.namespaceRoot $outputPath
            }
        }

        Generate-BaseClass "Entity" $config.namespaceRoot $outputPath -isAuditExtension $false
        Generate-BaseClass "Domain" $config.namespaceRoot $outputPath -isAuditExtension $false
        Generate-BaseClass "Dto" $config.namespaceRoot $outputPath -isAuditExtension $false
    
        Generate-BaseClass "Entity" $config.namespaceRoot $outputPath -isAuditExtension $true
        Generate-BaseClass "Domain" $config.namespaceRoot $outputPath -isAuditExtension $true
        Generate-BaseClass "Dto" $config.namespaceRoot $outputPath -isAuditExtension $true

        # Generate the DbContext extension class
        Generate-DbContextExtension -tables $tables -namespaceRoot $config.namespaceRoot -outputPath $config.outputPath
    }
}

# Main call
Main
