# Definition
function Generate-FieldDecorator {
    param (
        [pscustomobject]$fieldInfo,
        [string]$dataClassType
    )

    $fieldDecorator = ""

    # Decorators are only required in the Entity class definition
    if ($dataClassType -eq "Entity") {
        if ($fieldInfo.Decorator.Contains("StringLength")) {
            $fieldDecorator = $fieldInfo.Decorator
        }
        elseif ($fieldInfo.Decorator -eq "NP") {
            $fkId = $fieldInfo.FieldCodeName -replace "Ref$", "Id"
            $fieldDecorator = '[ForeignKey("'+$fkId+'")]'
        }
    }

    if ($fieldDecorator -ne "") {
        $fieldDecorator = "        $fieldDecorator`n"
    }

    return $fieldDecorator
}
