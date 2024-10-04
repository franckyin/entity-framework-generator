
# Definition
function Generate-FieldDefinition {
    param (
        [pscustomobject]$fieldInfo,
        [string]$dataClassType,
        [bool]$isAuditClass
    )

    $fieldDefinition = ""
    if ($dataClassType -eq "Entity" -and $fieldInfo.Decorator -eq "FKs") {
        if ($isAuditClass -eq $false) {
            $fieldDefinition = "// $($fieldInfo.FieldCodeName) - One-to-Many Foreign Keys not defined in Entity"
        }
        else {
            $fieldDefinition = "// $($fieldInfo.FieldCodeName) - One-to-Many Foreign Keys not defined in Audit Entity"
        }
    }
    elseif ($dataClassType -eq "Entity" -and $fieldInfo.Decorator -eq "NPs" -and $isAuditClass -eq $true) {
        $fieldDefinition = "// $($fieldInfo.FieldCodeName) - One-to-Many Foreign References not defined in Audit Entity"
    }
    else {
        # Nullable attributes
        $nullable = ""
        if ($fieldInfo.Nullable -eq "x") {
            $nullable = "?"
        }
        
        # Default strings
        $rootType = ""
        $listInit = ""

        # Multiple References
        if ($fieldInfo.FieldCodeName.EndsWith("Refs")) {
            
            # Root type
            $resultCatcher = $fieldInfo.Type -match "^ICollection\<(.+)\>$"
            $rootType = $matches[1]

            # Reference type
            $type = "ICollection<$rootType$dataClassType>"

            # List initializations
            $listInit = " = new List<$rootType$dataClassType>();"
        }
        # Single Reference
        elseif ($fieldInfo.FieldCodeName.EndsWith("Ref")) {
            $type = "$($fieldInfo.Type)$dataClassType"
        }
        # Other fields
        else {
            $type = $fieldInfo.Type
        }

        $fieldDefinition = "public $type$nullable $($fieldInfo.FieldCodeName) { get; set; }$listInit"
    }

    if ($fieldDefinition -ne "") {
        $fieldDefinition = "        $fieldDefinition`n"
    }

    return $fieldDefinition
}
