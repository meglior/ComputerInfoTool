# ====================== Конфигурация ======================
$Config = @{
    LogLevel          = "Info"
    CreateLogFile     = $true
    ConsoleOutput     = $true
    DefaultOutputPath = ".\Reports"
    ThrottleLimit     = 30          # по умолчанию для параллельных проверок
}

# ====================== Функции нормализации ======================
function Get-NormalizedOS {
    param([string]$OSName)
    if ([string]::IsNullOrWhiteSpace($OSName)) { return "Неизвестно" }
    $os = $OSName.ToLower()
    switch -Regex ($os) {
        'windows 11'             { "Windows 11" }
        'windows 10'             { "Windows 10" }
        'windows 8\.1'           { "Windows 8.1" }
        'windows 8'              { "Windows 8" }
        'windows 7'              { "Windows 7" }
        'windows xp'             { "Windows XP" }
        'windows server 2022'    { "Server 2022" }
        'windows server 2019'    { "Server 2019" }
        'windows server 2016'    { "Server 2016" }
        'windows server 2012'    { "Server 2012" }
        'linux|ubuntu|debian'    { "Linux" }
        'mac'                    { "macOS" }
        default                  { $OSName.Trim() }
    }
}

function Get-WindowsBuildInfo {
    param([string]$OSVersion)
    if ([string]::IsNullOrWhiteSpace($OSVersion)) { return @('', '') }
    $build = if ($OSVersion -match '\(\s*(\d+)\s*\)') { $Matches[1] } else { '' }
    $version = switch ($build) {
        '26200' { '25H2' } '26100' { '24H2' } '22631' { '23H2' } '22621' { '22H2' }
        '22000' { '21H2' } '19045' { '22H2' } '19044' { '21H2' } # ... (остальное как было)
        default { '' }
    }
    return @($build, $version)
}
# Экспорт конфигурации для использования в других модулях
Export-ModuleMember -Variable Config   # если сделаем модуль позже
# Или просто используем её
$Global:Config = $Config