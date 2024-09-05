# Dot Sourcing
. .\ps-functions\Generate-Class.ps1
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
    if ($outputPath -ne "" -and $null -ne $outputPath){
        Write-Host $outputPath
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
                
                # Copy base PK field reference
                $basePkField = $tableInfo.Group | Where-Object { $_.Decorator -eq "PK" }
    
                # Create AuditId PK field from base PK field properties
                $auditPkField = $basePkField | Select-Object *
                $auditPkField.Decorator = "PK"
                $auditPkField.FieldCodeName = $basePkField.FieldCodeName -replace "Id$", "AuditId"
    
                # Update base field PK
                $basePkField.Decorator = "FK"
    
                # Create a new array with the new fields prepended
                $auditTableInfo.Group = @($auditPkField) + $tableInfo.Group
    
                $auditTableInfo.Group.ForEach(
                    {
                        # Replace Each Namespace with "Audit"
                        $_.Namespace = "Audit"
    
                        # Update the type of each "NP" field
                        if ($_.Decorator -eq "NP" -and $_.TypeAudit -eq "x") {
                            $_.Type += "Audit"
                        }
                        # Update the type of each "NPs" field
                        elseif ($_.Decorator -eq "NPs" -and $_.TypeAudit -eq "x") {
                            $_.Type = $_.Type -replace "ICollection<(.+)>", 'ICollection<${1}Audit>'
                        }
                    }
                )
    
                # Generate audit trail classes
                Generate-Class $auditTableInfo "Entity" $config.namespaceRoot $outputPath
                Generate-Class $auditTableInfo "Domain" $config.namespaceRoot $outputPath
                Generate-Class $auditTableInfo "Dto" $config.namespaceRoot $outputPath
            }
        }
    }
}

# Main call
Main
