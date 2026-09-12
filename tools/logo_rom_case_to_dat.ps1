# ============================================================================
# 把"case 版"的 anlogic_logo_rom.v 转成 PH1P_LOGIC_ERAM 用的初始化文件 .dat。
#
# 背景：官方 lab_ex3_osd 例程里的 anlogic_logo_rom 是一个 6387 条 case 的组合
# ROM，综合后要靠 LUT 逻辑解码地址，是 hdmi_mixer 里最大的一块逻辑。改成 ERAM
# 需要一份初始化文件（TD 的 ERAM 原语用 INIT_FILE 参数读它）。
#
# 用法：
#   pwsh -File tools/logo_rom_case_to_dat.ps1 -CaseFile tmp/logo_rom_case.v
# 其中 CaseFile 是 case 版源文件（可从 git 历史取出：
#   git show <commit>:user_source/hdl_source/anlogic_logo_rom.v > tmp/logo_rom_case.v )
#
# 地址映射（与 anlogic_logo_rom.v 里的说明一致）：
#   原始地址 = y * 160 + x；有内容的地址区间是 [5494, 20426]。
#   文件按 ROM_BASE = 4096 起算，共 ROM_DEPTH = 16384 行，行号 = 地址 - 4096。
#   区间外的地址在硬件里会被强制到第 0 行（该行内容为 0，即透明）。
#
# .dat 格式（TD 的 IP 生成器从 .mif 转换时就是这个格式）：
#   一行一个存储单元，行序 = 地址序，每行是 DATA_WIDTH 个二进制字符，高位在前。
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CaseFile,
    [string]$OutFile = "user_source/hdl_source/anlogic_logo_rom.dat",
    [int]$RomBase = 4096,
    [int]$RomDepth = 16384,
    [int]$DataWidth = 25
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CaseFile)) { throw "case 文件不存在: $CaseFile" }

# ---- 1. 解析 case 版：地址 -> 25 位数值 ----
$map = @{}
foreach ($line in (Get-Content -LiteralPath $CaseFile -Encoding UTF8)) {
    if ($line -match "^\s*15'd(\d+)\s*:\s*O_pixel\s*=\s*25'h([0-9a-fA-F]+)") {
        $map[[int]$matches[1]] = [convert]::ToInt64($matches[2], 16)
    }
}
if ($map.Count -eq 0) { throw "没能从 $CaseFile 里解析出任何 case 条目" }

$addrMin = ($map.Keys | Measure-Object -Minimum).Minimum
$addrMax = ($map.Keys | Measure-Object -Maximum).Maximum
Write-Host ("case 条目 {0} 条，地址区间 [{1}, {2}]" -f $map.Count, $addrMin, $addrMax)

$winLast = $RomBase + $RomDepth - 1
if ($addrMin -lt $RomBase -or $addrMax -gt $winLast) {
    throw ("位图超出 ERAM 窗口 [{0}, {1}]：内容在 [{2}, {3}]。`n" +
           "需要把 RomBase/RomDepth 调大，并同步改 anlogic_logo_rom.v 里的同名常量。") -f `
          $RomBase, $winLast, $addrMin, $addrMax
}

# ---- 2. 生成 .dat：一行一个单元，二进制、高位在前 ----
$lines = New-Object 'string[]' $RomDepth
$nonZero = 0
for ($i = 0; $i -lt $RomDepth; $i++) {
    $addr = $RomBase + $i
    $v = 0
    if ($map.ContainsKey($addr)) { $v = $map[$addr] }
    if ($v -ne 0) { $nonZero++ }

    $chars = New-Object 'char[]' $DataWidth
    for ($b = 0; $b -lt $DataWidth; $b++) {
        # bit (DataWidth-1) 写在第 0 列
        $bit = ($v -shr ($DataWidth - 1 - $b)) -band 1
        $chars[$b] = if ($bit -eq 1) { '1' } else { '0' }
    }
    $lines[$i] = -join $chars
}

$outFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutFile))
[System.IO.File]::WriteAllLines($outFull, $lines)
Write-Host ("写出 {0}：{1} 行 x {2} 位，非零 {3} 行" -f $outFull, $RomDepth, $DataWidth, $nonZero)

# ---- 3. 穷举校验：按"硬件真正的读法"逐步比对，必须与 case 版逐地址一致 ----
# 硬件读法：行号 = 地址在 [RomBase, RomBase+RomDepth-1] 内 ? 地址-RomBase : 0；
#           输出 = 该行的 25 位内容（.dat 按行序、高位在前解析）。
# 因此这里从文件回读，逐地址与 case 版比较（case 里没有的地址按 0，即原 default 分支）。
$mismatch = 0
$firstBad = -1
$readBack = [System.IO.File]::ReadAllLines($outFull)
if ($readBack.Count -ne $RomDepth) { throw ("回读行数 {0} != {1}" -f $readBack.Count, $RomDepth) }
for ($a = 0; $a -lt 32768; $a++) {
    $expect = 0
    if ($map.ContainsKey($a)) { $expect = $map[$a] }

    $row = 0
    if ($a -ge $RomBase -and $a -le $winLast) {
        $row = $a - $RomBase
    }
    $got = 0
    foreach ($ch in $readBack[$row].ToCharArray()) { $got = ($got -shl 1) -bor [int]([string]$ch) }

    if ($got -ne $expect) {
        $mismatch++
        if ($firstBad -lt 0) { $firstBad = $a }
    }
}

Write-Host ("穷举校验（地址 0..32767，含窗口外强制第 0 行）：不一致 {0} 处，首个不一致地址 {1}" -f $mismatch, $firstBad)
if ($mismatch -ne 0) { throw "校验失败：新 ROM 与原 case 版行为不一致" }
Write-Host "OK"
