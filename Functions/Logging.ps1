$Global:LogFile = $null
$Global:CurrentLogLevel = "Info"

$LogLevels = @{
    'Debug'   = 0
    'Verbose' = 1
    'Info'    = 2
    'Warning' = 3
    'Error'   = 4
    'Success' = 5
}

function Start-Logging {
    param(
        [string]$LogPath,
        [string]$LogLevel = "Info"
    )

    $Global:CurrentLogLevel = $LogLevel
    $Global:LogFile = $LogPath

    $dir = Split-Path $LogPath -Parent
    if (-not (Test-Path $dir)) { 
        New-Item -Path $dir -ItemType Directory -Force | Out-Null 
    }

    Write-Log "=== Запуск логирования (уровень: $LogLevel) ===" -Level Info
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Debug','Verbose','Info','Warning','Error','Success')]
        [string]$Level = 'Info'
    )

    if ($LogLevels[$Level] -lt $LogLevels[$Global:CurrentLogLevel]) { return }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    if ($Global:LogFile) {
        Add-Content -Path $Global:LogFile -Value $logLine -Encoding UTF8
    }

    $color = switch ($Level) {
        'Debug'   { 'Gray' }
        'Verbose' { 'Cyan' }
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    Write-Host $logLine -ForegroundColor $color
}

function Stop-Logging {
    Write-Log "=== Завершение логирования ===" -Level Info
}