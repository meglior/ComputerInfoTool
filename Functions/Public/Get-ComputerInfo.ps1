<#
.SYNOPSIS
    Главная функция модуля ComputerInfoTool (PowerShell 7+)
.DESCRIPTION
    Универсальный аудит компьютеров в Active Directory.
#>

[CmdletBinding(DefaultParameterSetName = 'ByList')]
param(
    [Parameter(Mandatory=$true, ParameterSetName='ByList')]
    [string]$ComputerListPath,

    [Parameter(Mandatory=$true, ParameterSetName='ByOU')]
    [string]$OU,

    [string]$OutputCsv = ".\Reports\ComputerReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    [string]$Server,
    [string]$LogLevel = "Info",

    # Основные модули
    [switch]$IncludeLastLogon,
    [switch]$IncludeOnlineCheck,
    [int[]]$Port,

    # Расширенные модули
    [switch]$IncludeWin11Readiness,
    [switch]$IncludeRemoteAccessAudit,
    [switch]$IncludeKasperskyCheck,
    [switch]$IncludeDisableInactive,

    [string[]]$FilePath,
    [string[]]$SoftwareContains,
    [switch]$SoftwareExact,

    [int]$DaysInactive = 30,
    [string]$TargetOU,
    [switch]$WhatIf,

    # PS7+ параметры
    [int]$ThrottleLimit = 60,
    [switch]$AsJson
)

$ScriptRoot = $PSScriptRoot

# Инициализация папок и логирования
Initialize-ModuleFolders -RootPath $ScriptRoot
$LogPath = Join-Path $ScriptRoot "Logs\ComputerInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Start-Logging -LogPath $LogPath -LogLevel $LogLevel
Write-Log "=== Запуск Get-ComputerInfo (PS $($PSVersionTable.PSVersion)) ===" -Level Info

# Получение списка компьютеров
$computers = Get-ComputerList @PSBoundParameters
Write-Log "Найдено компьютеров: $($computers.Count)" -Level Info

# Базовая информация
$results = Get-ADComputerInfo -Computers $computers -Server $Server

# Параллельные проверки (PS7+)
$parallelParams = @{ ThrottleLimit = $ThrottleLimit; AsJob = $true }

if ($IncludeOnlineCheck) {
    Write-Log "Запуск OnlineCheck (параллельно)" -Level Info
    $results = $results | ForEach-Object -Parallel {
        Import-Module ComputerInfoTool -Force
        Add-OnlineCheck -InputObjects $_
    } @parallelParams | Receive-Job -Wait
}

if ($IncludeWin11Readiness) {
    Write-Log "Запуск Win11Readiness (параллельно)" -Level Info
    $results = $results | ForEach-Object -Parallel {
        Import-Module ComputerInfoTool -Force
        Add-Win11Readiness -InputObjects $_
    } @parallelParams | Receive-Job -Wait
}

# Последовательные проверки (быстрые)
if ($IncludeRemoteAccessAudit) { $results = Add-RemoteAccessAudit -InputObjects $results }
if ($IncludeKasperskyCheck)    { $results = Add-KasperskyCheck -InputObjects $results }
if ($Port)                     { $results = Add-PortCheck -InputObjects $results -Ports $Port }
if ($FilePath)                 { $results = Add-FileCheck -InputObjects $results -Paths $FilePath }
if ($SoftwareContains)         { $results = Add-SoftwareCheck -InputObjects $results -Software $SoftwareContains -Exact:$SoftwareExact }

if ($IncludeDisableInactive) {
    Write-Log "Запуск Disable-InactiveComputers" -Level Warning
    Disable-InactiveComputers -SearchBase $OU -DaysInactive $DaysInactive -TargetOU $TargetOU -WhatIf:$WhatIf
}

# Экспорт
if ($AsJson) {
    $jsonPath = $OutputCsv -replace '\.csv$', '.json'
    $results | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding utf8
    Write-Log "JSON отчёт сохранён: $jsonPath" -Level Success
} else {
    $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding utf8BOM
    Write-Log "CSV отчёт сохранён: $OutputCsv" -Level Success
}

# Сводка
Write-Host "`n===== СВОДКА =====" -ForegroundColor Cyan
$results | Where-Object { $_."Состояние" -ne "НЕ НАЙДЕН" } |
    Group-Object "Состояние" |
    Sort-Object Count -Descending |
    ForEach-Object { Write-Host "$($_.Name): $($_.Count)" -ForegroundColor Green }

Stop-Logging