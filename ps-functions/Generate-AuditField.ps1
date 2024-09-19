function Generate-AuditField {
    param (
        [pscustomobject]$field
    )

    $auditField = $field | Select-Object *

    switch ($field.Decorator) {
        "PK" {
            $auditField.FieldCodeName = $auditField.FieldCodeName -replace "Id$", "AuditId"
        }
        "FK" {
            $auditField.FieldCodeName = $auditField.FieldCodeName -replace "Id$", "AuditId"
        }
        "FKs" {
            $auditField.FieldCodeName = $auditField.FieldCodeName -replace "Ids$", "AuditIds"
        }
        "NP" {
            $auditField.Type += "Audit"
            $auditField.FieldCodeName = $auditField.FieldCodeName -replace "Ref$", "AuditRef"
        }
        "NPs" {
            $auditField.Type = $auditField.Type -replace "ICollection<(.+)>", 'ICollection<${1}Audit>'
            $auditField.FieldCodeName = $auditField.FieldCodeName -replace "Refs$", "AuditRefs"
        }
    }

    return $auditField
}