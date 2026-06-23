function Get-ComputerList {
    param(
        [string]$ComputerListPath,
        [string]$OU,
        [string]$Server
    )

    if ($ComputerListPath) {
        Write-Log "Чтение списка компьютеров из файла: $ComputerListPath" -Level Info
        Get-Content -Path $ComputerListPath -Encoding UTF8 |
            Where-Object { $_.Trim() -ne '' } |
            ForEach-Object { $_.Trim() } |
            Select-Object -Unique
    }
    else {
        Write-Log "Получение компьютеров из OU: $OU" -Level Info
        $params = @{ Filter = 'objectClass -eq "computer"'; SearchBase = $OU }
        if ($Server) { $params.Server = $Server }
        Get-ADComputer @params | Select-Object -ExpandProperty Name
    }
}

function Get-ADComputerInfo {
    param(
        [string[]]$Computers,
        [string]$Server
    )

    Write-Log "Запрос информации из AD для $($Computers.Count) компьютеров" -Level Info

    $props = @(
        'DistinguishedName',
        'Enabled',
        'OperatingSystem',
        'OperatingSystemVersion',
        'LockedOut',
        'Name',
        'LastLogonTimestamp'      # Самый эффективный способ
    )

    $adParams = @{ 
        Properties = $props
        ErrorAction = 'SilentlyContinue' 
    }
    if ($Server) { $adParams.Server = $Server }

    # Батчевый запрос
    $allAdComputers = @()
    $batchSize = 500

    for ($i = 0; $i -lt $Computers.Count; $i += $batchSize) {
        $batch = $Computers[$i..([math]::Min($i + $batchSize - 1, $Computers.Count - 1))]
        $nameFilter = ($batch | ForEach-Object { "(name=$($_))" }) -join ''
        $ldapFilter = "(&(objectClass=computer)(|$nameFilter))"
        
        $batchResult = Get-ADComputer -LDAPFilter $ldapFilter @adParams
        $allAdComputers += $batchResult
    }

    $adLookup = @{}
    foreach ($c in $allAdComputers) { 
        $adLookup[$c.Name.ToUpper()] = $c 
    }

    $results = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($name in $Computers) {
        $adc = $adLookup[$name.ToUpper()]
        
        if ($adc) {
            # Преобразование LastLogonTimestamp
            $lastLogon = $null
            if ($adc.LastLogonTimestamp) {
                try {
                    $lastLogon = [DateTime]::FromFileTime($adc.LastLogonTimestamp)
                } catch {}
            }

            $status = switch ($true) {
                (-not $adc.Enabled) { "Отключена" }
                $adc.LockedOut      { "Заблокирована" }
                default             { "Активна" }
            }

            $results.Add([PSCustomObject]@{
                "Компьютер"         = $adc.Name
                "Последний OU"      = if ($adc.DistinguishedName -match 'OU=([^,]+)') { $Matches[1] } else { "Корень домена" }
                "Состояние"         = $status
                "ОС"                = Get-NormalizedOS -OSName $adc.OperatingSystem
                "Описание ОС"       = Get-WindowsDisplayInfo -OSName $adc.OperatingSystem -OSVersion $adc.OperatingSystemVersion
                "DN"                = $adc.DistinguishedName ?? ""
                "LastLogonDate"     = $lastLogon
                "LastLogonTimestamp"= $adc.LastLogonTimestamp
            })
        }
        else {
            $results.Add([PSCustomObject]@{
                "Компьютер"      = $name
                "Последний OU"   = "НЕ НАЙДЕН"
                "Состояние"      = "НЕ НАЙДЕН"
                "ОС"             = "НЕ НАЙДЕН"
                "Описание ОС"    = ""
                "DN"             = ""
                "LastLogonDate"  = $null
            })
        }
    }

    Write-Log "Базовая информация из AD успешно получена" -Level Info
    return $results
}