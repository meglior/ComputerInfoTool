<#
.SYNOPSIS
    Проверка открытых портов на компьютерах
#>

function Add-PortCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObjects,
        
        [int[]]$Ports = @(135, 445, 3389, 5985, 5986),
        [int]$ThrottleLimit = 40
    )

    Begin { Write-Log "Запуск PortCheck (порты: $($Ports -join ', '))" -Level Info }

    Process {
        $results = $InputObjects | ForEach-Object -Parallel {
            Import-Module ComputerInfoTool -Force

            $obj = $_.PSObject.Copy()
            $name = $obj.Компьютер

            if ($obj."Онлайн" -ne "Да") {
                $obj | Add-Member -NotePropertyName "ОткрытыеПорты" -NotePropertyValue "—" -Force
                return $obj
            }

            $openPorts = @()
            foreach ($port in $using:Ports) {
                try {
                    $tcp = Test-NetConnection -ComputerName $name -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                    if ($tcp.TcpTestSucceeded) {
                        $openPorts += $port
                    }
                } catch {}
            }

            $obj | Add-Member -NotePropertyName "ОткрытыеПорты" -NotePropertyValue ($openPorts ? ($openPorts -join ", ") : "Нет") -Force
            $obj
        } -ThrottleLimit $ThrottleLimit

        $results
    }

    End { Write-Log "PortCheck завершён" -Level Success }
}