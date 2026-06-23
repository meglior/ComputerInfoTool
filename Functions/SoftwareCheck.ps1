function Add-SoftwareCheck {
    param(
        [PSObject[]]$InputObjects,
        [string[]]$Software,
        [switch]$Exact
    )

    Write-Log "Запуск проверки ПО: $($Software -join ', ')" -Level Info

    foreach ($obj in $InputObjects) {
        $computer = $obj.Компьютер
        if ($obj."Состояние" -eq "НЕ НАЙДЕН") { continue }

        try {
            $installed = Invoke-Command -ComputerName $computer -ScriptBlock {
                $list = @()
                $paths = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                foreach ($reg in $paths) {
                    Get-ItemProperty $reg -ErrorAction SilentlyContinue | 
                        Where-Object DisplayName | 
                        Select-Object DisplayName, DisplayVersion
                }
            }

            foreach ($sw in $Software) {
                $found = $installed | Where-Object {
                    if ($Exact) { $_.DisplayName -eq $sw }
                    else { $_.DisplayName -like "*$sw*" }
                }

                $colName = "SW_" + ($sw -replace '[^a-zA-Z0-9]', '_')
                $status = if ($found) { 
                    "✅ Установлен ($($found.DisplayVersion -join ', '))" 
                } else { 
                    "❌ Не установлен" 
                }
                $obj | Add-Member -NotePropertyName $colName -NotePropertyValue $status -Force
            }
        }
        catch {
            Write-Log "SoftwareCheck: Ошибка на $computer — $($_.Exception.Message)" -Level Warning
        }
    }
    return $InputObjects
}