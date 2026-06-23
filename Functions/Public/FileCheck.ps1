<#
.SYNOPSIS
    Проверка наличия конкретных файлов/папок на целевых компьютерах
#>

function Add-FileCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObjects,
        
        [string[]]$Paths
    )

    Begin { Write-Log "Запуск FileCheck для путей: $($Paths -join ', ')" -Level Info }

    Process {
        $results = $InputObjects | ForEach-Object {
            $obj = $_.PSObject.Copy()
            $name = $obj.Компьютер

            if ($obj."Онлайн" -ne "Да") {
                $obj | Add-Member -NotePropertyName "Файлы" -NotePropertyValue "—" -Force
                return $obj
            }

            $found = @()
            try {
                $session = New-CimSession -ComputerName $name -OperationTimeoutSec 10 -ErrorAction Stop

                foreach ($path in $using:Paths) {
                    $exists = Invoke-CimMethod -CimSession $session -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "cmd.exe /c if exist `"$path`" echo FOUND" } -ErrorAction SilentlyContinue
                    if ($exists.ProcessId -and (Invoke-Command -ComputerName $name -ScriptBlock { param($p); Test-Path $p } -ArgumentList $path)) {
                        $found += $path
                    }
                }

                Remove-CimSession -CimSession $session
            }
            catch {
                # fallback
            }

            $obj | Add-Member -NotePropertyName "Файлы" -NotePropertyValue ($found ? ($found -join "; ") : "Не найдены") -Force
            $obj
        }

        $results
    }

    End { Write-Log "FileCheck завершён" -Level Success }
}