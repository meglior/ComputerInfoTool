# Functions/Private/Core.ps1

# ====================== Нормализация ОС ======================
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

function Get-WindowsDisplayInfo {
    param([string]$OSName, [string]$OSVersion)

    $normalized = Get-NormalizedOS -OSName $OSName
    $buildInfo = if ($OSVersion -match '\((\d+)\)') { $Matches[1] } else { '' }

    $version = switch ($buildInfo) {
        '26100' { '24H2' }
        '26200' { '25H2' }
        '22631' { '23H2' }
        '22621' { '22H2' }
        '22000' { '21H2' }
        default { '' }
    }

    if ($version) {
        "$normalized ($version)"
    } else {
        $normalized
    }
}

# Автоматическое создание папок
function Initialize-ModuleFolders {
    param([string]$RootPath)

    @('Logs', 'Reports') | ForEach-Object {
        $path = Join-Path $RootPath $_
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
}