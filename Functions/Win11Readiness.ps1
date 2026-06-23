function Add-Win11Readiness {
    param(
        [PSObject[]]$InputObjects,
        [int]$ThrottleLimit = $Config.ThrottleLimit
    )

    Write-Log "Запуск Win11 Readiness Audit ($ThrottleLimit потоков)" -Level Info

    $results = $InputObjects | ForEach-Object -Parallel {

        $obj = $_.PSObject.Copy()

        # Добавляем новые колонки
        $obj | Add-Member -NotePropertyName "CPU" -NotePropertyValue "" -Force
        $obj | Add-Member -NotePropertyName "RAM_GB" -NotePropertyValue 0 -Force
        $obj | Add-Member -NotePropertyName "Disk_GB" -NotePropertyValue 0 -Force
        $obj | Add-Member -NotePropertyName "TPM2" -NotePropertyValue "Unknown" -Force
        $obj | Add-Member -NotePropertyName "SecureBoot" -NotePropertyValue "Unknown" -Force
        $obj | Add-Member -NotePropertyName "Win11Ready" -NotePropertyValue "Unknown" -Force
        $obj | Add-Member -NotePropertyName "Issues" -NotePropertyValue "" -Force

        if ($obj."Состояние" -eq "НЕ НАЙДЕН" -or $obj."Онлайн" -ne "Да") {
            $obj.Win11Ready = "Недоступен"
            return $obj
        }

        try {
            $session = New-CimSession -ComputerName $obj.Компьютер -OperationTimeoutSec 10 -ErrorAction Stop

            # RAM
            $osInfo = Get-CimInstance Win32_OperatingSystem -CimSession $session
            $obj.RAM_GB = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 1)

            # CPU
            $cpuInfo = Get-CimInstance Win32_Processor -CimSession $session
            $obj.CPU = $cpuInfo.Name

            # Disk C:
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -CimSession $session
            $obj.Disk_GB = [math]::Round($disk.Size / 1GB, 0)

            # TPM 2.0
            try {
                $tpm = Get-CimInstance -Namespace root/cimv2/security/microsofttpm -Class Win32_Tpm -CimSession $session
                $obj.TPM2 = if ($tpm.SpecVersion -match "2\.0") { "Yes" } else { "No" }
            } catch { $obj.TPM2 = "Unknown" }

            # Secure Boot
            try {
                $sb = Get-CimInstance -Namespace root\Microsoft\Windows\SecureBoot -Class MS_SecureBoot -CimSession $session
                $obj.SecureBoot = if ($sb.UEFISecureBootEnabled) { "Yes" } else { "No" }
            } catch { $obj.SecureBoot = "Unknown" }

            Remove-CimSession $session

            # Анализ
            $issues = @()
            if (-not (Test-Win11CpuSupport $obj.CPU)) { $issues += "CPU" }
            if ($obj.RAM_GB -lt 4) { $issues += "RAM" }
            if ($obj.Disk_GB -lt 64) { $issues += "Disk" }
            if ($obj.TPM2 -ne "Yes") { $issues += "TPM2" }
            if ($obj.SecureBoot -ne "Yes") { $issues += "SecureBoot" }

            $obj.Issues = $issues -join ", "
            $obj.Win11Ready = if ($issues.Count -eq 0) { "Готов" } else { "Не готов" }

        }
        catch {
            $obj.Win11Ready = "Ошибка"
            $obj.Issues = $_.Exception.Message
        }

        return $obj

    } -ThrottleLimit $ThrottleLimit

    Write-Log "Win11 Readiness Audit завершён" -Level Success
    return $results
}

function Test-Win11CpuSupport {
    param([string]$CpuName)
    if ([string]::IsNullOrWhiteSpace($CpuName)) { return $false }

    if ($CpuName -match 'Intel.*(i[3579]-|Core Ultra|Xeon)') { return $true }
    if ($CpuName -match 'Ryzen.*[3-9]\d{3,}') { return $true }
    if ($CpuName -match 'Threadripper|EPYC') { return $true }
    return $false
}