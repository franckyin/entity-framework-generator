function Generate-Schemas {
    param (
        [pscustomobject]$fields,
        [string]$outputPath
    )

    # Function to build the schema for two levels of nested types (no recursion)
    function Build-NestedSchema {
        param (
            [string]$topLevelEntity, # Current Top Level Entity
            [pscustomobject]$fields, # The full set of fields to search
            [string]$nestedClassName, # The class name to search for nested fields
            [string]$fieldFriendlyName, # Friendly name of the current field
            [string]$fieldCodeName, # Code name of the current field
            [bool]$required           # Whether the field is required
        )

        # Find all fields that belong to the nested class
        $nestedFields = $fields | Where-Object { $_.TableCodeName -eq $nestedClassName }

        # Build the nested array schema (1st level)
        $nestedSchema = @{
            label    = $fieldFriendlyName
            name     = $fieldCodeName
            type     = 'array'
            required = $required
            schema   = @()
        }

        foreach ($nestedField in $nestedFields) {
            $nestedFieldSpec = @{
                label    = $nestedField.FieldFriendlyName
                name     = $nestedField.FieldCodeName
                type     = $nestedField.Type
                required = $nestedField.Required -eq 'true'
            }

            $test = $false

            # If the nested field is a collection (2nd level), build it (no recursion)
            if ($nestedField.Type -like 'ICollection*') {
                $innerNestedClass = $nestedField.Type -replace 'ICollection<', '' -replace '>', ''

                $innerNestedFields = $fields | Where-Object { $_.TableCodeName -eq $innerNestedClass }

                $innerSchema = @()
                foreach ($innerField in $innerNestedFields) {
                    $innerSchema += @{
                        label    = $innerField.FieldFriendlyName
                        name     = $innerField.FieldCodeName
                        type     = $innerField.Type
                        required = $innerField.Required -eq 'true'
                    }
                }

                # Add the inner schema to the field
                $nestedFieldSpec.schema = $innerSchema
                $nestedFieldSpec.type = 'array'
                $test = $true
            }

            # Add the field spec to the first-level schema
            $nestedSchema.schema += $nestedFieldSpec

            if ($test -eq $true) {
                $nestedSchema | ConvertTo-Json -Depth 5 | Write-Host
            }
        }

        return $nestedSchema
    }

    # Initialize an empty array to store schemas by TopLevelEntity in order
    $schemas = @()

    # Iterate through each row in the CSV file
    foreach ($field in $fields) {
        if (-not $field.Category) { continue }

        $topLevelEntity = $field.TopLevelEntity
        $feTopLevelEntity = $field.UrlTle
        $category = $field.Category
        $fieldFriendlyName = $field.FieldFriendlyName
        $fieldCodeName = $field.FieldCodeName
        $type = $field.Type
        $required = $field.Required -eq 'true'

        $tle = $schemas | Where-Object { $_.name -eq $feTopLevelEntity }
        if (-not $tle) {
            $tle = @{ name = $feTopLevelEntity; categories = @() }
            $schemas += $tle
        }

        $categorySchema = $tle.categories | Where-Object { $_.categoryName -eq $category }
        if (-not $categorySchema) {
            $categorySchema = @{ categoryName = $category; schema = @() }
            $tle.categories += $categorySchema
        }

        if ($type -like 'ICollection*') {
            $nestedClass = $type -replace 'ICollection<', '' -replace '>', ''
            $nestedSchema = Build-NestedSchema -topLevelEntity $topLevelEntity -fields $fields -nestedClassName $nestedClass -fieldFriendlyName $fieldFriendlyName -fieldCodeName $fieldCodeName -required $required
            $categorySchema.schema += $nestedSchema
        }
        else {
            $controlSpec = @{
                label    = $fieldFriendlyName
                name     = $fieldCodeName
                type     = $type
                required = $required
            }
            $categorySchema.schema += $controlSpec
        }
    }

    # Generate output
    $schemaOutputPath = "$outputPath\generated-schema.ts"
    $fileContents = "export const formSchemas = {`n"

    foreach ($tle in $schemas) {
        $fileContents += "    '$($tle.name)': ["  

        foreach ($categorySchema in $tle.categories) {
            $fileContents += "`n        { categoryName: `"$($categorySchema.categoryName)`", schema: ["

            foreach ($field in $categorySchema.schema) {
                if ($field.type -eq 'array') {
                    $fileContents += "`n                { label: `"$($field.label)`", name: `"$($field.name)`", type: `"$($field.type)`", required: $($field.required.ToString().ToLower()), schema: ["

                    # Process the first level of nested schema
                    foreach ($nestedField in $field.schema) {
                        if ($nestedField.type -eq 'array') {
                            # Add the first-level array schema
                            $fileContents += "`n                    { label: `"$($nestedField.label)`", name: `"$($nestedField.name)`", type: `"$($nestedField.type)`", required: $($nestedField.required.ToString().ToLower()), schema: ["
                    
                            # Process the second level of nested schema
                            foreach ($innerNestedField in $nestedField.schema) {
                                $fileContents += "`n                        { label: `"$($innerNestedField.label)`", name: `"$($innerNestedField.name)`", type: `"$($innerNestedField.type)`", required: $($innerNestedField.required.ToString().ToLower()) },"
                            }
                    
                            $fileContents = $fileContents.TrimEnd(',')
                            $fileContents += "`n                    ] },"
                        }
                        else {
                            # Add normal fields
                            $fileContents += "`n                    { label: `"$($nestedField.label)`", name: `"$($nestedField.name)`", type: `"$($nestedField.type)`", required: $($nestedField.required.ToString().ToLower()) },"
                        }
                    }                    

                    $fileContents = $fileContents.TrimEnd(',')
                    $fileContents += "`n                ] },"  # Close the first level array schema
                }
                else {
                    $fileContents += "`n                { label: `"$($field.label)`", name: `"$($field.name)`", type: `"$($field.type)`", required: $($field.required.ToString().ToLower()) },"
                }
            }

            $fileContents = $fileContents.TrimEnd(',')
            $fileContents += "`n            ]`n        },"
        }

        $fileContents = $fileContents.TrimEnd(',')
        $fileContents += "`n    ],`n"
    }

    $fileContents = $fileContents.TrimEnd(',')
    $fileContents += "`n};"

    Set-Content -Path $schemaOutputPath -Value $fileContents
    Write-Host "Generated: $schemaOutputPath"
}
