function Add-PortCheck {
    param(
        [PSObject[]]$InputObjects,
        [int[]]$Ports
    )

    Write-Host "Проверка портов: $($Ports -join ', ')" -ForegroundColor Cyan

    foreach ($obj in $InputObjects) {
        $name = $obj.Компьютер
        foreach ($p in $Ports) {
            try {
                $test = Test-NetConnection -ComputerName $name -Port $p -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                $obj | Add-Member -NotePropertyName "Port_$p" -NotePropertyValue ($test.TcpTestSucceeded ? "Открыт" : "Закрыт") -Force
            }
            catch {
                $obj | Add-Member -NotePropertyName "Port_$p" -NotePropertyValue "Ошибка" -Force
            }
        }
    }
    return $InputObjects
}