<#
.SYNOPSIS
    Проверка готовности компьютеров к Windows 11
#>

function Add-Win11Readiness {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObjects,
        
        [int]$ThrottleLimit = 30
    )

    Begin {
        Write-Log "Запуск Win11 Readiness Audit ($ThrottleLimit потоков)" -Level Info
    }

    Process {
        $results = $InputObjects | ForEach-Object -Parallel {
            Import-Module ComputerInfoTool -Force

            $obj = $_.PSObject.Copy()

            # Добавляем свойства
            $props = @("CPU","RAM_GB","Disk_GB","TPM2","SecureBoot","Win11Ready","Issues")
            foreach ($p in $props) {
                if (-not $obj.PSObject.Properties[$p]) {
                    $obj | Add-Member -NotePropertyName $p -NotePropertyValue "" -Force
                }
            }

            if ($obj."Состояние" -eq "НЕ НАЙДЕН" -or $obj."Онлайн" -ne "Да") {
                $obj.Win11Ready = "Недоступен"
                return $obj
            }

            try {
                $session = New-CimSession -ComputerName $obj.Компьютер -OperationTimeoutSec 15 -ErrorAction Stop

                # RAM
                $os = Get-CimInstance Win32_OperatingSystem -CimSession $session
                $obj.RAM_GB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)

                # CPU
                $cpu = Get-CimInstance Win32_Processor -CimSession $session | Select-Object -First 1
                $obj.CPU = $cpu.Name

                # Disk C:
                $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -CimSession $session
                $obj.Disk_GB = [math]::Round($disk.Size / 1GB, 0)

                # TPM 2.0
                try {
                    $tpm = Get-CimInstance -Namespace root/cimv2/security/microsofttpm -ClassName Win32_Tpm -CimSession $session -ErrorAction Stop
                    $obj.TPM2 = if ($tpm.SpecVersion -match "2\.0") { "Yes" } else { "No" }
                } catch { $obj.TPM2 = "Unknown" }

                # Secure Boot
                try {
                    $sb = Get-CimInstance -Namespace root\Microsoft\Windows\SecureBoot -ClassName MS_SecureBoot -CimSession $session -ErrorAction Stop
                    $obj.SecureBoot = if ($sb.UEFISecureBootEnabled) { "Yes" } else { "No" }
                } catch { $obj.SecureBoot = "Unknown" }

                Remove-CimSession -CimSession $session

                # Анализ
                $issues = @()
                if (-not (Test-Win11CpuSupport $obj.CPU)) { $issues += "CPU" }
                if ($obj.RAM_GB -lt 4) { $issues += "RAM (<4GB)" }
                if ($obj.Disk_GB -lt 64) { $issues += "Disk (<64GB)" }
                if ($obj.TPM2 -ne "Yes") { $issues += "TPM 2.0" }
                if ($obj.SecureBoot -ne "Yes") { $issues += "SecureBoot" }

                $obj.Issues = $issues -join ", "
                $obj.Win11Ready = if ($issues.Count -eq 0) { "✅ Готов" } else { "❌ Не готов" }

            }
            catch {
                $obj.Win11Ready = "Ошибка"
                $obj.Issues = $_.Exception.Message
            }

            $obj
        } -ThrottleLimit $ThrottleLimit

        $results
    }

    End {
        Write-Log "Win11 Readiness Audit завершён" -Level Success
    }
}

function Test-Win11CpuSupport {
    param([string]$CpuName)
    if ([string]::IsNullOrWhiteSpace($CpuName)) { return $false }

    $CpuName -match 'Intel.*(i[3579]-|Core Ultra|Xeon|Pentium Gold|Cel|N\d{4})' -or
    $CpuName -match 'Ryzen.*[3-9]\d{3,}' -or
    $CpuName -match 'Threadripper|EPYC'
}