function Add-FileCheck {
    param(
        [PSObject[]]$InputObjects,
        [string[]]$Paths
    )

    Write-Log "Запуск проверки файлов/папок: $($Paths -join ', ')" -Level Info

    foreach ($obj in $InputObjects) {
        $computer = $obj.Компьютер
        if ($obj."Состояние" -eq "НЕ НАЙДЕН") { continue }

        foreach ($path in $Paths) {
            try {
                $result = Invoke-Command -ComputerName $computer -ScriptBlock {
                    param($p)
                    [PSCustomObject]@{
                        Exists = Test-Path $p
                        Path   = $p
                    }
                } -ArgumentList $path -ErrorAction Stop

                $colName = "File_" + ($path -replace '[\\\/:\*\?<>|"]', '_')
                $obj | Add-Member -NotePropertyName $colName -NotePropertyValue ($result.Exists ? "✅ Найден" : "❌ Не найден") -Force
            }
            catch {
                $colName = "File_" + ($path -replace '[\\\/:\*\?<>|"]', '_')
                $obj | Add-Member -NotePropertyName $colName -NotePropertyValue "Ошибка доступа" -Force
                Write-Log "FileCheck: Ошибка на $computer для пути $path — $($_.Exception.Message)" -Level Warning
            }
        }
    }
    return $InputObjects
}