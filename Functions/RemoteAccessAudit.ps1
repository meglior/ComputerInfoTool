<#
    Аудит RDP и LiteManager / других средств удалённого доступа
#>

function Add-RemoteAccessAudit {
    param(
        [PSObject[]]$InputObjects,
        [int]$DaysBack = 90
    )

    Write-Log "Запуск аудита удалённого доступа (RDP + LiteManager) за $DaysBack дней" -Level Info

    foreach ($obj in $InputObjects) {
        $computer = $obj.Компьютер
        if ($obj."Состояние" -eq "НЕ НАЙДЕН" -or $obj."Онлайн" -ne "Да") {
            $obj | Add-Member -NotePropertyName "RDP_Events" -NotePropertyValue "N/A" -Force
            $obj | Add-Member -NotePropertyName "LiteManager" -NotePropertyValue "N/A" -Force
            continue
        }

        $rdpCount = 0
        $liteFound = $false

        try {
            # RDP Events (TerminalServices + Security)
            $rdpEvents = Get-WinEvent -ComputerName $computer -FilterHashtable @{
                LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
                ID = 21,23,24,25
                StartTime = (Get-Date).AddDays(-$DaysBack)
            } -ErrorAction SilentlyContinue

            $rdpCount = $rdpEvents.Count

            # LiteManager
            $processes = Get-Process -ComputerName $computer -Name "*LiteManager*","*ROM*","*LM*","*RemoteControl*" -ErrorAction SilentlyContinue
            $services = Get-Service -ComputerName $computer -ErrorAction SilentlyContinue | 
                        Where-Object { $_.DisplayName -like "*LiteManager*" -or $_.Name -like "*LiteManager*" -or $_.Name -like "*ROM*" }

            $liteFound = ($processes.Count -gt 0) -or ($services.Count -gt 0)
        }
        catch {
            Write-Log "RemoteAccessAudit: Ошибка на $computer — $($_.Exception.Message)" -Level Warning
        }

        $obj | Add-Member -NotePropertyName "RDP_Events_Last$($DaysBack)d" -NotePropertyValue $rdpCount -Force
        $obj | Add-Member -NotePropertyName "LiteManager_Detected" -NotePropertyValue ($liteFound ? "Да" : "Нет") -Force
    }

    Write-Log "Аудит удалённого доступа завершён" -Level Info
    return $InputObjects
}