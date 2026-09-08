param(
    [string]$Port = "",
    [int]$Baud = 115200,
    [string]$LogFile = "debug_uart.log"
)

Add-Type -AssemblyName System.IO.Ports

function Convert-RotateRight1 {
    param([byte]$Byte)
    $v = [int]$Byte
    return [byte]((($v -shr 1) -bor (($v -band 1) -shl 7)) -band 255)
}

function Read-OneLine {
    param($SerialPort)
    $bytes = New-Object System.Collections.Generic.List[byte]
    while ($true) {
        try {
            $next = $SerialPort.ReadByte()
        }
        catch [System.TimeoutException] {
            if ($bytes.Count -eq 0) {
                return $null
            }
            continue
        }
        if ($next -eq 0x0A) {
            if ($bytes.Count -gt 1 -and $bytes[$bytes.Count - 1] -eq 0x0D) {
                $bytes.RemoveAt($bytes.Count - 1)
            }
            break
        }
        $bytes.Add([byte]$next)
    }
    $text = -join ($bytes | ForEach-Object { [char]$_ })
    if (-not $text.StartsWith("DBG:")) {
        $text = -join ($bytes | ForEach-Object { [char](Convert-RotateRight1 $_) })
    }
    return $text
}

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
        $line = Read-OneLine $portObj
        if ($line) {
            Write-Host $line
            Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
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
