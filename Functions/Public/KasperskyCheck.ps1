<#
    Проверка установленного Kaspersky (Agent и Endpoint Security)
#>

function Add-KasperskyCheck {
    param([PSObject[]]$InputObjects)

    Write-Log "Запуск проверки Kaspersky Endpoint / Security Center" -Level Info

    foreach ($obj in $InputObjects) {
        $computer = $obj.Компьютер

        if ($obj."Онлайн" -ne "Да") {
            $obj | Add-Member -NotePropertyName "Kaspersky_Agent" -NotePropertyValue "N/A" -Force
            $obj | Add-Member -NotePropertyName "Kaspersky_Endpoint" -NotePropertyValue "N/A" -Force
            continue
        }

        $agentVer = "Not Found"
        $epVer    = "Not Found"

        try {
            # Самый надёжный способ — через Invoke-Command
            $installed = Invoke-Command -ComputerName $computer -ScriptBlock {
                Get-ItemProperty `
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" `
                    -ErrorAction SilentlyContinue |
                Where-Object DisplayName |
                Select-Object DisplayName, DisplayVersion
            } -ErrorAction Stop

            foreach ($app in $installed) {
                if ($app.DisplayName -like "*Kaspersky Security Center*") {
                    $agentVer = $app.DisplayVersion
                }
                elseif ($app.DisplayName -like "*Kaspersky Endpoint Security*") {
                    $epVer = $app.DisplayVersion
                }
            }
        }
        catch {
            Write-Log "KasperskyCheck: Ошибка подключения к $computer — $($_.Exception.Message)" -Level Warning
        }

        $obj | Add-Member -NotePropertyName "Kaspersky_Agent" -NotePropertyValue $agentVer -Force
        $obj | Add-Member -NotePropertyName "Kaspersky_Endpoint" -NotePropertyValue $epVer -Force
    }

    Write-Log "Проверка Kaspersky завершена" -Level Info
    return $InputObjects
}