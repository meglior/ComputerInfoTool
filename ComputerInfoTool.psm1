# ComputerInfoTool.psm1

# Загружаем Private функции
$PrivatePath = Join-Path $PSScriptRoot 'Functions\Private'
if (Test-Path $PrivatePath) {
    Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Загружаем Public функции
$PublicPath = Join-Path $PSScriptRoot 'Functions\Public'
if (Test-Path $PublicPath) {
    Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Инициализация
Initialize-ModuleFolders -RootPath $PSScriptRoot
Write-Verbose "✅ ComputerInfoTool v2.0.0 (PowerShell 7+) успешно загружен"