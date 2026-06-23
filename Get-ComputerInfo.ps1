<#
.SYNOPSIS
    Универсальный модульный инструмент аудита компьютеров в Active Directory
.DESCRIPTION
    Поддерживает от 5 до 6000+ компьютеров.
    Все проверки логируются, результаты сохраняются в CSV + логи.
#>

[CmdletBinding(DefaultParameterSetName = 'ByList')]
param(
    [Parameter(Mandatory=$true, ParameterSetName='ByList')]
    [string]$ComputerListPath,

    [Parameter(Mandatory=$true, ParameterSetName='ByOU')]
    [string]$OU,

    [string]$OutputCsv = ".\Reports\ComputerReport_$(Get-Date -Format 'yyyyMMdd_HHmm').csv",
    [string]$Server,

    [string]$LogLevel = "Info",

    # === Основные модули ===
    [switch]$IncludeLastLogon,
    [switch]$IncludeOnlineCheck,
    [int[]]$Port,

    # === Расширенные модули ===
    [switch]$IncludeWin11Readiness,
    [switch]$IncludeRemoteAccessAudit,     # RDP + LiteManager
    [switch]$IncludeKasperskyCheck,
    [switch]$IncludeDisableInactive,

    [string[]]$FilePath,
    [string[]]$SoftwareContains,
    [switch]$SoftwareExact,

    [int]$DaysInactive = 30,               # для DisableInactive
    [string]$TargetOU                      # для DisableInactive
)

$ScriptRoot = $PSScriptRoot
$LogPath = "$ScriptRoot\Logs\ComputerInfo_$(Get-Date -Format 'yyyyMMdd_HHmm').log"

# ====================== Загрузка конфигурации и логирования ======================
. "$ScriptRoot\config.ps1"
. "$ScriptRoot\Functions\Logging.ps1"

Start-Logging -LogPath $LogPath -LogLevel $LogLevel
Write-Log "=== Запуск Get-ComputerInfo.ps1 ===" -Level Info
Write-Log "Режим: $($PSCmdlet.ParameterSetName) | Компьютеров будет обработано: ~$($computers.Count)" -Level Info

# ====================== Загрузка модулей ======================
. "$ScriptRoot\Functions\Core.ps1"
. "$ScriptRoot\Functions\AD.ps1"

if ($IncludeOnlineCheck)          { . "$ScriptRoot\Functions\OnlineCheck.ps1" }
if ($IncludeWin11Readiness)       { . "$ScriptRoot\Functions\Win11Readiness.ps1" }
if ($IncludeRemoteAccessAudit)    { . "$ScriptRoot\Functions\RemoteAccessAudit.ps1" }
if ($IncludeKasperskyCheck)       { . "$ScriptRoot\Functions\KasperskyCheck.ps1" }
if ($IncludeDisableInactive)      { . "$ScriptRoot\Functions\DisableInactive.ps1" }
if ($Port)                        { . "$ScriptRoot\Functions\PortCheck.ps1" }
if ($FilePath)                    { . "$ScriptRoot\Functions\FileCheck.ps1" }
if ($SoftwareContains)            { . "$ScriptRoot\Functions\SoftwareCheck.ps1" }

Write-Log "Все модули успешно загружены" -Level Success

# ====================== Получение списка компьютеров ======================
$computers = Get-ComputerList @PSBoundParameters
Write-Log "Всего компьютеров для обработки: $($computers.Count)" -Level Info

# ====================== Базовая информация из AD ======================
$results = Get-ADComputerInfo -Computers $computers -Server $Server

# ====================== Выполнение модулей ======================
if ($IncludeOnlineCheck) {
    Write-Log "Запуск OnlineCheck (Ping + DNS + IP)" -Level Info
    $results = Add-OnlineCheck -InputObjects $results
}

if ($IncludeWin11Readiness) {
    Write-Log "Запуск Win11 Readiness Audit" -Level Info
    $results = Add-Win11Readiness -InputObjects $results
}

if ($IncludeRemoteAccessAudit) {
    Write-Log "Запуск аудита удалённого доступа (RDP + LiteManager)" -Level Info
    $results = Add-RemoteAccessAudit -InputObjects $results
}

if ($IncludeKasperskyCheck) {
    Write-Log "Запуск проверки Kaspersky" -Level Info
    $results = Add-KasperskyCheck -InputObjects $results
}

if ($Port) {
    Write-Log "Запуск проверки портов: $($Port -join ', ')" -Level Info
    $results = Add-PortCheck -InputObjects $results -Ports $Port
}

if ($FilePath) {
    Write-Log "Запуск проверки файлов" -Level Info
    $results = Add-FileCheck -InputObjects $results -Paths $FilePath
}

if ($SoftwareContains) {
    Write-Log "Запуск проверки установленного ПО" -Level Info
    $results = Add-SoftwareCheck -InputObjects $results -Software $SoftwareContains -Exact:$SoftwareExact
}

if ($IncludeDisableInactive) {
    Write-Log "Запуск отключения неактивных компьютеров" -Level Warning
    Disable-InactiveComputers -SearchBase $OU -DaysInactive $DaysInactive -TargetOU $TargetOU -WhatIf:$WhatIf
}

# ====================== Экспорт результата ======================
$results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding utf8BOM

Write-Log "Отчёт успешно сохранён: $OutputCsv" -Level Success
Write-Host "`n✅ Основной отчёт сохранён: $OutputCsv" -ForegroundColor Green

# ====================== Итоговая сводка ======================
Write-Host "`n===== КРАТКАЯ СВОДКА =====" -ForegroundColor Cyan
$results | Where-Object { $_."Состояние" -ne "НЕ НАЙДЕН" } | 
    Group-Object "Состояние" | 
    Sort-Object Count -Descending | 
    ForEach-Object { Write-Host "$($_.Name): $($_.Count)" }

Stop-Logging