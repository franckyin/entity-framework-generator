# Definition
function Generate-FieldComment {
    param (
        [pscustomobject]$fieldInfo,
        [string]$dataClassType
    )

    $fieldComment = ""

    switch ($fieldInfo.Decorator) {
        "FK" {
            $fieldComment = "Navigation Property - Foreign Key"
            break
        }
        "FKs" {
            $fieldComment = "Navigation Property - Foreign Keys"
            break
        }
        "NP" {
            $fieldComment = "Navigation Property - Reference"
            break
        }
        "NPs" {
            $fieldComment = "Navigation Property - References"
            break
        }
    }

    if ($fieldComment -ne "") {
        $fieldComment = "        // $fieldComment`n"
    }

    return $fieldComment
}
