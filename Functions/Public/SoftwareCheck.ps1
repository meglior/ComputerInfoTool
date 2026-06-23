<#
.SYNOPSIS
    Поиск установленного ПО по имени
#>

function Add-SoftwareCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObjects,
        
        [string[]]$Software,
        [switch]$Exact
    )

    Begin { Write-Log "Запуск SoftwareCheck: $($Software -join ', ')" -Level Info }

    Process {
        $results = $InputObjects | ForEach-Object {
            $obj = $_.PSObject.Copy()
            $name = $obj.Компьютер

            if ($obj."Онлайн" -ne "Да") {
                $obj | Add-Member -NotePropertyName "ПО" -NotePropertyValue "—" -Force
                return $obj
            }

            $foundSoftware = @()
            try {
                $session = New-CimSession -ComputerName $name -OperationTimeoutSec 15 -ErrorAction Stop

                $uninstallKeys = Get-CimInstance -CimSession $session -ClassName Win32_Product | 
                    Select-Object Name, Version

                foreach ($soft in $using:Software) {
                    $match = if ($using:Exact) {
                        $uninstallKeys | Where-Object { $_.Name -eq $soft }
                    } else {
                        $uninstallKeys | Where-Object { $_.Name -like "*$soft*" }
                    }

                    if ($match) {
                        $foundSoftware += "$($match.Name) ($($match.Version))"
                    }
                }

                Remove-CimSession -CimSession $session
            }
            catch {}

            $obj | Add-Member -NotePropertyName "ПО" -NotePropertyValue ($foundSoftware ? ($foundSoftware -join "; ") : "Не найдено") -Force
            $obj
        }

        $results
    }

    End { Write-Log "SoftwareCheck завершён" -Level Success }
}