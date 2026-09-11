<#
  读取 FPGA 的 DBG: 日志（115200-8-N-1）。

  用法：
    .\tools\read_debug_uart.ps1                       # 列出串口后交互选择
    .\tools\read_debug_uart.ps1 -Port COM3            # 直接读，Ctrl+C 停止
    .\tools\read_debug_uart.ps1 -Port COM3 -ProbeSec 5  # 只看 5 秒原始字节（排查用）

  说明：System.IO.Ports 在部分环境（Windows PowerShell 5.1、PowerShell 7.0~7.3）下
  用 Add-Type -AssemblyName 会报 ASSEMBLY_NOT_FOUND，但类型本身通常已经可用，所以这里
  先探测类型，再考虑按路径加载，最后才报错——不要无条件 Add-Type。
#>
param(
    [string]$Port = "",
    [int]$Baud = 115200,
    [string]$LogFile = "debug_uart.log",
    [int]$SilentWarnSec = 5,
    [int]$ProbeSec = 0
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

if (-not (Initialize-SerialPorts)) {
    Write-Host "Cannot load System.IO.Ports. Run this script with Windows PowerShell 5.1 or PowerShell 7.4+."
    exit 1
}

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
    # GetPortNames() 在任何环境都可用；CIM 只是用来补描述，拿不到也不影响选口。
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
        if ($described.ContainsKey($n)) {
            Write-Host ("  {0}  {1}" -f $n, $described[$n])
        }
        else {
            Write-Host ("  {0}" -f $n)
        }
    }
    $Port = Read-Host "COM port (for example COM3)"
}

$portObj = New-Object System.IO.Ports.SerialPort($Port, $Baud, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$portObj.ReadTimeout = 1000

Write-Host "Opening $Port @ $Baud baud...  Ctrl+C to stop."

try {
    $portObj.Open()

    if ($ProbeSec -gt 0) {
        # 只做体检：区分"线上一个字节都没有"和"收到了乱码/波特率不对"。
        $portObj.ReadTimeout = 300
        $total = 0
        $head = New-Object System.Collections.Generic.List[byte]
        $sw = [Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $ProbeSec) {
            try {
                $b = $portObj.ReadByte()
                $total++
                if ($head.Count -lt 64) { $head.Add([byte]$b) }
            }
            catch [System.TimeoutException] { }
        }
        $hex = ($head | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
        $txt = -join ($head | ForEach-Object { if ($_ -ge 32 -and $_ -lt 127) { [char]$_ } else { '.' } })
        Write-Host ("{0} 秒收到 {1} 字节" -f $ProbeSec, $total)
        if ($total -gt 0) {
            Write-Host ("hex: {0}" -f $hex)
            Write-Host ("txt: {0}" -f $txt)
        }
        else {
            Write-Host "一个字节都没有：FPGA 没在发（未配置/未上电/不是这个口），或波特率相差过大。"
        }
        return
    }

    $warned = $false
    $openedAt = Get-Date
    while ($true) {
        $line = Read-OneLine $portObj
        if ($line) {
            Write-Host $line
            Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
            $warned = $false
            continue
        }
        if (-not $warned -and ((Get-Date) - $openedAt).TotalSeconds -ge $SilentWarnSec) {
            Write-Host ("[{0}] 还没有收到任何数据。检查：板子已上电且已重新下载 bitstream（配置掉电易失）、" -f (Get-Date -Format HH:mm:ss))
            Write-Host "       端口就是板子那路（拔掉板子 USB 后该口应消失）、摄像头/HDMI 已正常工作。"
            $warned = $true
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
