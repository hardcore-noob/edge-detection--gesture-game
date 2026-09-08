param(
    [string]$Port = "",
    [int]$Baud = 115200,
    [string]$LogFile = "debug_uart.log"
)

Add-Type -AssemblyName System.IO.Ports

if (-not $Port) {
    $ports = Get-CimInstance Win32_SerialPort |
        Select-Object DeviceID, Name, Description
    if (-not $ports) {
        Write-Host "No serial port found. Connect the board Type-C USB cable and try again."
        exit 1
    }
    $ports | Format-Table -AutoSize
    $Port = Read-Host "COM port (for example COM3)"
}

$portObj = New-Object System.IO.Ports.SerialPort($Port, $Baud, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$portObj.ReadTimeout = 1000

Write-Host "Opening $Port @ $Baud baud...  Ctrl+C to stop."

try {
    $portObj.Open()
    while ($true) {
        try {
            $line = $portObj.ReadLine()
            Write-Host $line
            Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
        }
        catch [System.TimeoutException] {
            # No data received within the timeout; keep waiting.
        }
    }
}
finally {
    if ($portObj.IsOpen) {
        $portObj.Close()
    }
    $portObj.Dispose()
    Write-Host "Serial port closed."
}
