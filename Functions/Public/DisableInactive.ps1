<#
.SYNOPSIS
    Отключение и перемещение неактивных компьютеров в Active Directory
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
        Write-Log "TargetOU не указан! Укажите OU для перемещения." -Level Error
        return
    }

    Write-Log "Запуск Disable-InactiveComputers (> $DaysInactive дней неактивности)" -Level Warning

    $dateThreshold = (Get-Date).AddDays(-$DaysInactive)

    # Основные неактивные
    $inactive = Get-ADComputer -SearchBase $SearchBase `
        -Properties LastLogonDate, OperatingSystem, Description, Enabled `
        -Filter { Enabled -eq $true } -ErrorAction SilentlyContinue |
        Where-Object { -not $_.LastLogonDate -or $_.LastLogonDate -lt $dateThreshold }

    # Никогда не логинились
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
        } else { "Никогда" }

        $action = if ($MoveOnly) { "Переместить" } else { "Отключить + переместить" }

        if ($PSCmdlet.ShouldProcess($comp.Name, $action)) {
            try {
                if (-not $MoveOnly) {
                    Disable-ADAccount -Identity $comp.DistinguishedName -ErrorAction Stop
                }
                Move-ADObject -Identity $comp.DistinguishedName -TargetPath $TargetOU -ErrorAction Stop

                $success++
                Write-Log "[OK] $action → $($comp.Name) | LastLogon: $lastLogonStr" -Level Success
            }
            catch {
                $failed++
                Write-Log "[ERROR] $($comp.Name) — $($_.Exception.Message)" -Level Error
            }
        } else {
            Write-Log "[WHATIF] $action → $($comp.Name) | LastLogon: $lastLogonStr" -Level Info
        }
    }

    Write-Log "Disable-InactiveComputers завершён. Успешно: $success | Ошибок: $failed" -Level Success
}