@{
    RootModule           = 'ComputerInfoTool.psm1'
    ModuleVersion        = '2.0.0'
    GUID                 = 'a7b8c9d0-e1f2-3456-7890-abcdef123456'  # Замени на [guid]::NewGuid()
    Author               = 'meglior'
    Description          = 'Современный модульный инструмент аудита компьютеров в Active Directory (PowerShell 7+)'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')
    RequiredModules      = @('ActiveDirectory')
    
    FunctionsToExport    = @(
        'Get-ComputerInfo',
        'Get-ADComputerInfo',
        'Add-OnlineCheck',
        'Add-Win11Readiness',
        'Add-RemoteAccessAudit',
        'Add-KasperskyCheck',
        'Disable-InactiveComputers',
        'Add-PortCheck',
        'Add-FileCheck',
        'Add-SoftwareCheck'
    )
    
    VariablesToExport    = @()
    AliasesToExport      = @()
    
    PrivateData = @{
        PSData = @{
            Tags         = @('ActiveDirectory', 'Audit', 'Windows11', 'SysAdmin', 'PowerShell7')
            LicenseUri   = 'https://github.com/meglior/ComputerInfoTool/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/meglior/ComputerInfoTool'
        }
    }
}