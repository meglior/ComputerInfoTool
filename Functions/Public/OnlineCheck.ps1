<#
.SYNOPSIS
    Проверка доступности компьютеров (Ping + DNS + IP)
#>

function Add-OnlineCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObjects,
        
        [int]$ThrottleLimit = 60
    )

    Begin {
        Write-Log "Запуск OnlineCheck (Throttle: $ThrottleLimit)" -Level Info
    }

    Process {
        $results = $InputObjects | ForEach-Object -Parallel {
            Import-Module ComputerInfoTool -Force

            $obj = $_.PSObject.Copy()

            $name = $obj.Компьютер

            # LastLogonDaysAgo
            if ($obj.LastLogonDate) {
                $days = (Get-Date) - $obj.LastLogonDate
                $obj | Add-Member -NotePropertyName "LastLogonDaysAgo" -NotePropertyValue $days.Days -Force
            } else {
                $obj | Add-Member -NotePropertyName "LastLogonDaysAgo" -NotePropertyValue "—" -Force
            }

            if ($obj."Состояние" -eq "НЕ НАЙДЕН") {
                $obj | Add-Member -NotePropertyName "Онлайн" -NotePropertyValue "—" -Force
                $obj | Add-Member -NotePropertyName "IP-адрес" -NotePropertyValue "—" -Force
                $obj | Add-Member -NotePropertyName "DNS" -NotePropertyValue "—" -Force
                return $obj
            }

            try {
                # DNS
                $dns = Resolve-DnsName -Name $name -Type A -ErrorAction Stop | Select-Object -First 1
                $obj | Add-Member -NotePropertyName "IP-адрес" -NotePropertyValue $dns.IPAddress -Force
                $obj | Add-Member -NotePropertyName "DNS" -NotePropertyValue "OK" -Force

                # Ping
                $ping = Test-Connection -ComputerName $name -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue
                $online = $null -ne $ping

                $obj | Add-Member -NotePropertyName "Онлайн" -NotePropertyValue ($online ? "Да" : "Нет") -Force
                if ($ping) {
                    $obj | Add-Member -NotePropertyName "ResponseMS" -NotePropertyValue $ping.Latency -Force
                }
            }
            catch {
                $obj | Add-Member -NotePropertyName "Онлайн" -NotePropertyValue "Нет" -Force
                $obj | Add-Member -NotePropertyName "DNS" -NotePropertyValue "Failed" -Force
            }

            $obj
        } -ThrottleLimit $ThrottleLimit

        $results
    }

    End {
        Write-Log "OnlineCheck завершён" -Level Success
    }
}