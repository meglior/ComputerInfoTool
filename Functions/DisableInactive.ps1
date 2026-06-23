<#
    Модуль отключения неактивных компьютеров
#>

function Disable-InactiveComputers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchBase,

        [int]$DaysInactive = 30,
        [string]$TargetOU,
        [switch]$WhatIf,
        [switch]$MoveOnly
    )

    if (-not $TargetOU) {
        Write-Log "TargetOU не указан!" -Level Error
        return
    }

    Write-Log "Запуск отключения неактивных компьютеров (> $DaysInactive дней)" -Level Warning

    $dateThreshold = (Get-Date).AddDays(-$DaysInactive)

    # === Более надёжный способ получения неактивных компьютеров ===
    $inactive = Get-ADComputer -SearchBase $SearchBase `
        -Properties LastLogonDate, OperatingSystem, Description, Enabled `
        -Filter { Enabled -eq $true } `
        -ErrorAction SilentlyContinue |
        Where-Object {
            -not $_.LastLogonDate -or 
            $_.LastLogonDate -lt $dateThreshold
        }

    # Компьютеры, которые никогда не логинились
    $neverLogged = Get-ADComputer -SearchBase $SearchBase `
        -Properties LastLogonDate, OperatingSystem, Description, Enabled `
        -LDAPFilter "(&(objectClass=computer)(!(lastLogonTimestamp=*))(enabled=TRUE))" `
        -ErrorAction SilentlyContinue

    $comps = ($inactive + $neverLogged) | 
             Where-Object { $_.DistinguishedName -notlike "*_Заблокированные*" } |
             Sort-Object Name -Unique

    if (-not $comps) {
        Write-Log "Не найдено неактивных компьютеров" -Level Info
        return
    }

    Write-Log "Найдено для обработки: $($comps.Count) компьютеров" -Level Info

    $success = 0
    $failed = 0

    foreach ($comp in $comps) {
        $lastLogonStr = if ($comp.LastLogonDate) { 
                            $comp.LastLogonDate.ToString("yyyy-MM-dd") 
                        } else { 
                            "Никогда" 
                        }

        $action = if ($MoveOnly) { "Переместить" } else { "Отключить и переместить" }

        if ($WhatIf) {
            Write-Log "[WHATIF] $action → $($comp.Name) | LastLogon: $lastLogonStr" -Level Info
            continue
        }

        try {
            if (-not $MoveOnly) {
                Disable-ADAccount -Identity $comp.DistinguishedName -ErrorAction Stop
            }
            Move-ADObject -Identity $comp.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop

            $success++
            Write-Log "[OK] $($action): $($comp.Name)" -Level Success
        }
        catch {
            $failed++
            Write-Log "[ERROR] $($comp.Name) — $($_.Exception.Message)" -Level Error
        }
    }

    Write-Log "Модуль завершён. Успешно: $success | Ошибок: $failed" -Level Success
}