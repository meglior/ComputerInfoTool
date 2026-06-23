function Add-OnlineCheck {
    param([PSObject[]]$InputObjects)

    Write-Log "Запуск проверки доступности + DNS" -Level Info

    foreach ($obj in $InputObjects) {
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
            continue
        }

        $onlineInfo = @{
            Online = $false
            IP     = "—"
            DNS    = "Failed"
        }

        try {
            # DNS
            try {
                $dns = Resolve-DnsName -Name $name -Type A -ErrorAction Stop | Select-Object -First 1
                $onlineInfo.DNS = "OK"
                $onlineInfo.IP = $dns.IPAddress
            } catch {
                $onlineInfo.DNS = "Failed"
            }

            # Ping / Online
            $ping = Test-Connection -ComputerName $name -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue
            $onlineInfo.Online = $null -ne $ping

            if ($ping) {
                $obj | Add-Member -NotePropertyName "ResponseMS" -NotePropertyValue $ping.Latency -Force
            }
        }
        catch {}

        $obj | Add-Member -NotePropertyName "Онлайн" -NotePropertyValue ($onlineInfo.Online ? "Да" : "Нет") -Force
        $obj | Add-Member -NotePropertyName "IP-адрес" -NotePropertyValue $onlineInfo.IP -Force
        $obj | Add-Member -NotePropertyName "DNS" -NotePropertyValue $onlineInfo.DNS -Force
    }

    Write-Log "Проверка доступности завершена" -Level Info
    return $InputObjects
}