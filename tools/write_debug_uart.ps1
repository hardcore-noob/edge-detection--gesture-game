<#
  给 FPGA 发一条串口调参命令（ASCII，115200-8-N-1）。

  命令格式（uart_cmd.v）：`W <addr 2位hex> <data 4位hex>` + CR/LF，空格可有可无。

  用法示例：
    .\tools\write_debug_uart.ps1 -Port COM5 -View 4        # 切到"只看运动门"视图
    .\tools\write_debug_uart.ps1 -Port COM5 -View 5        # 切到"只看肤色门"视图
    .\tools\write_debug_uart.ps1 -Port COM5 -View 1        # 正常融合视图
    .\tools\write_debug_uart.ps1 -Port COM5 -Cmd "W 08 0001"
    .\tools\write_debug_uart.ps1 -Port COM5 -Cmd "W 02 0003","W 08 0001"

  视图号（recog_algo[15:12]，由 DIAG_MODE_SEL=1 的调试图解释）：
    0=原画面  1=融合+准星  2=背景帧预览  3=AWB前视图
    4=只看运动门(绿)  5=只看肤色门(红)  6=ROI框+融合  7=三色诊断

  预设档（同一个 recog_algo[15:12]，**只有 0..15 可寻址**，语义见 recog_top.v 顶部注释）：
    8=旧Y+d2>=0(基准)  9=新Y+d2>=5  10=旧Y+d2>=7(旧基线)  11=新Y+d2>=7
    12=新Y+d2>=6  13=新Y+d2>=0且d1>=-70  14=新Y+d2>=3  15=新Y+d2>=0
    (运动/锁存门已全面旁路)  写法 W 08 000N，N=档号的十六进制一位

  说明：-Rotate 是兜底——板子那路 UART 在个别 USB 桥下会整体偏一位，读脚本里也留了同样的
  兜底（rotate-right-1）。如果发命令没反应，试一次 -Rotate。
#>
param(
    [string]$Port = "",
    [int]$Baud = 115200,
    [int]$View = -1,
    [string[]]$Cmd = @(),
    [switch]$Rotate,
    [int]$SettleMs = 50
)

function Initialize-SerialPorts {
    if ("System.IO.Ports.SerialPort" -as [type]) { return $true }
    try { Add-Type -AssemblyName System.IO.Ports -ErrorAction Stop } catch { }
    if ("System.IO.Ports.SerialPort" -as [type]) { return $true }
    $candidates = @(
        (Join-Path $PSHOME 'System.IO.Ports.dll'),
        (Join-Path $env:WINDIR 'Microsoft.NET\assembly\GAC_MSIL\System.IO.Ports\v4.0_4.0.0.0__b03f5f7f11d50a3a\System.IO.Ports.dll')
    )
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path) {
            try { Add-Type -Path $path -ErrorAction Stop } catch { }
            if ("System.IO.Ports.SerialPort" -as [type]) { return $true }
        }
    }
    return $false
}

function Convert-RotateLeft1 {
    param([byte]$Byte)
    $v = [int]$Byte
    return [byte]((($v -shl 1) -bor ($v -shr 7)) -band 255)
}

if (-not (Initialize-SerialPorts)) {
    Write-Host "Cannot load System.IO.Ports. Run this script with Windows PowerShell 5.1 or PowerShell 7.4+."
    exit 1
}

$lines = New-Object System.Collections.Generic.List[string]
if ($View -ge 0) {
    if ($View -gt 15) { Write-Host "-View 只接受 0..15（recog_algo 只有 4 位，>15 会被截成低 4 位）"; exit 1 }
    $lines.Add(("W 08 {0:X4}" -f $View))
}
foreach ($c in $Cmd) { if ($c -and $c.Trim()) { $lines.Add($c.Trim()) } }

if ($lines.Count -eq 0) {
    Write-Host "没有要发的命令。用法："
    Write-Host "  .\tools\write_debug_uart.ps1 -Port COM5 -View 4"
    Write-Host "  .\tools\write_debug_uart.ps1 -Port COM5 -Cmd `"W 08 0001`""
    exit 1
}

if (-not $Port) {
    $names = @([System.IO.Ports.SerialPort]::GetPortNames())
    if (-not $names) {
        Write-Host "No serial port found. Connect the board Type-C USB cable and try again."
        exit 1
    }
    $described = @{}
    try {
        Get-CimInstance Win32_SerialPort -ErrorAction Stop |
            ForEach-Object { $described[$_.DeviceID] = $_.Name }
    }
    catch { }
    foreach ($n in $names) {
        if ($described.ContainsKey($n)) { Write-Host ("  {0}  {1}" -f $n, $described[$n]) }
        else                            { Write-Host ("  {0}" -f $n) }
    }
    $Port = Read-Host "COM port (for example COM3)"
}

$portObj = New-Object System.IO.Ports.SerialPort($Port, $Baud, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$portObj.ReadTimeout  = 500
$portObj.WriteTimeout = 1000

Write-Host "Opening $Port @ $Baud baud..."
try {
    $portObj.Open()
    Start-Sleep -Milliseconds 100      # USB 桥刚打开时的稳定时间
    foreach ($line in $lines) {
        $out = $line + "`r`n"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($out)
        if ($Rotate) { $bytes = @($bytes | ForEach-Object { Convert-RotateLeft1 $_ }) }
        $portObj.Write($bytes, 0, $bytes.Length)
        $portObj.BaseStream.Flush()
        $hex = ($bytes | ForEach-Object { "{0:X2}" -f $_ }) -join " "
        Write-Host ("sent: {0}    hex: {1}" -f $line, $hex)
        Start-Sleep -Milliseconds $SettleMs
    }
    Write-Host "done."
}
finally {
    if ($portObj -and $portObj.IsOpen) { $portObj.Close() }
    if ($portObj) { $portObj.Dispose() }
    Write-Host "Serial port closed."
}
