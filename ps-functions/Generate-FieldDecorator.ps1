# Definition
function Generate-FieldDecorator {
    param (
        [pscustomobject]$fieldInfo,
        [string]$dataClassType
    )

    $fieldDecorator = ""

    # Decorators are only required in the Entity class definition
    if ($dataClassType -eq "Entity") {
        if ($fieldInfo.Decorator -eq "PK") {
            $fieldDecorator = "[Key, DatabaseGenerated(DatabaseGeneratedOption.Identity)]"
        } elseif ($fieldInfo.Decorator.Contains("StringLength")) {
            $fieldDecorator = $fieldInfo.Decorator
        }
    }

    if ($fieldDecorator -ne "") {
        $fieldDecorator = "        $fieldDecorator`n"
    }

    return $fieldDecorator
}
