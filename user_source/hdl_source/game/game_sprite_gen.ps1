# ============================================================================
# 生成 game_sprite.dat —— 切水果精灵 ROM 的初始化文件（4 种水果 × 32×32 × 8bit）
#
# 为什么是脚本而不是手写：位图要能复现、能改（换颜色/换轮廓），而且必须**穷举校验**
#   —— 与 tools/logo_rom_case_to_dat.ps1 同一套思路：生成后从文件回读，
#   逐地址与"内存里的位图"比对，任何一处不一致就报错退出。
#
# 地址映射（与 game_sprite_rom.v 的 I_addr 一致）：
#   addr = {pal[1:0], dy[4:0], dx[4:0]}（12 位，共 4096 单元）
#   行序 = 地址序，每行 8 个二进制字符、高位在前（TD 的 ERAM 初始化约定）。
#
# 颜色：RGB332（bits[7:5] = R、[4:2] = G、[1:0] = B），**8'h00 = 透明**。
#   透明色是硬约定：精灵外的像素必须为 0，否则水果外围会是一圈实心方块。
#
# 用法：pwsh -NoProfile -File tools/game_sprite_gen.ps1
#   -OutFile 默认 user_source/hdl_source/game/game_sprite.dat
# ============================================================================

[CmdletBinding()]
param(
    [string]$OutFile = "user_source/hdl_source/game/game_sprite.dat"
)

$ErrorActionPreference = "Stop"

$W   = 32
$H   = 32
$PAL = 4
$img = New-Object 'int[]' ($PAL * $W * $H)

function Set-Px {
    param([int]$Pal, [int]$X, [int]$Y, [int]$C)
    if ($X -ge 0 -and $X -lt $W -and $Y -ge 0 -and $Y -lt $H) {
        $script:img[$Pal * $W * $H + $Y * $W + $X] = $C
    }
}

# ---- 调色板（RGB332）-------------------------------------------------------
$C_TRANSPARENT = 0x00
# 0 苹果
$A_BODY = 0xC0; $A_EDGE = 0x80; $A_HI = 0xFA; $A_STEM = 0x68; $A_LEAF = 0x38
# 1 橙子
$O_BODY = 0xF4; $O_EDGE = 0xAC; $O_HI = 0xFF
# 2 葡萄
$G_BODY = 0x87; $G_EDGE = 0x62; $G_HI = 0xB9
# 3 西瓜
$M_RIND = 0x19; $M_STRIPE = 0x0C; $M_HI = 0x3F

# ---- pal 0：苹果（圆身 + 高光 + 茎 + 叶）-----------------------------------
for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
        $dx = $x - 16; $dy = $y - 17
        $r2 = $dx * $dx + $dy * $dy
        if ($r2 -le 169) {                                  # 半径 13
            $c = $A_BODY
            if ($r2 -ge 132) { $c = $A_EDGE }
            if ($r2 -le 20 -and $dy -lt 0) { $c = $A_HI }   # 左上高光
            Set-Px 0 $x $y $c
        }
    }
}
for ($y = 2; $y -le 7; $y++) { Set-Px 0 15 $y $A_STEM; Set-Px 0 16 $y $A_STEM }
for ($y = 2; $y -le 6; $y++) {
    for ($x = 17; $x -le 25; $x++) {
        $dx = $x - 21; $dy = $y - 4
        if (((($dx * $dx) / 16.0) + (($dy * $dy) / 4.0)) -le 1.0) { Set-Px 0 $x $y $A_LEAF }
    }
}

# ---- pal 1：橙子（横向椭圆 + 高光）-----------------------------------------
for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
        $dx = $x - 16; $dy = $y - 17
        $e = (($dx * $dx) / (14.0 * 14.0)) + (($dy * $dy) / (11.0 * 11.0))
        if ($e -le 1.0) {
            $c = $O_BODY
            if ($e -ge 0.78) { $c = $O_EDGE }
            if ($e -le 0.10) { $c = $O_HI }
            Set-Px 1 $x $y $c
        }
    }
}

# ---- pal 2：葡萄串（6 颗小球）---------------------------------------------
$grapes = @(
    @(11, 10), @(21, 10), @(16, 15), @(11, 20), @(21, 20), @(16, 25)
)
foreach ($g in $grapes) {
    $cx = $g[0]; $cy = $g[1]
    for ($y = ($cy - 6); $y -le ($cy + 6); $y++) {
        for ($x = ($cx - 6); $x -le ($cx + 6); $x++) {
            $dx = $x - $cx; $dy = $y - $cy
            $r2 = $dx * $dx + $dy * $dy
            if ($r2 -le 25) {                               # 半径 5
                $c = $G_BODY
                if ($r2 -ge 16) { $c = $G_EDGE }
                if ($r2 -le 4 -and $dy -lt 0) { $c = $G_HI }
                Set-Px 2 $x $y $c
            }
        }
    }
}

# ---- pal 3：西瓜（绿皮 + 深色条纹 + 高光）----------------------------------
for ($y = 0; $y -lt $H; $y++) {
    for ($x = 0; $x -lt $W; $x++) {
        $dx = $x - 16; $dy = $y - 16
        $r2 = $dx * $dx + $dy * $dy
        if ($r2 -le 196) {                                  # 半径 14
            $c = $M_RIND
            if ((($x % 7) -lt 2) -or (($y % 9) -lt 1)) { $c = $M_STRIPE }
            if ($r2 -ge 156) { $c = $M_STRIPE }
            if ($r2 -le 16 -and $dy -lt 0) { $c = $M_HI }
            Set-Px 3 $x $y $c
        }
    }
}

# ---- 写 .dat：一行一个单元，二进制、高位在前 -------------------------------
$lines = New-Object 'string[]' ($PAL * $W * $H)
for ($a = 0; $a -lt $lines.Count; $a++) {
    $v = $img[$a]
    $chars = New-Object 'char[]' 8
    for ($b = 0; $b -lt 8; $b++) {
        $bit = ($v -shr (7 - $b)) -band 1
        $chars[$b] = if ($bit -eq 1) { '1' } else { '0' }
    }
    $lines[$a] = -join $chars
}

$outFull = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutFile))
[System.IO.File]::WriteAllLines($outFull, $lines)
Write-Host ("写出 {0}：{1} 行 x 8 位" -f $outFull, $lines.Count)

# ---- 穷举校验：从文件回读，逐地址与内存位图比对 ----------------------------
$back = [System.IO.File]::ReadAllLines($outFull)
if ($back.Count -ne $lines.Count) { throw ("回读行数 {0} != {1}" -f $back.Count, $lines.Count) }
$mismatch = 0
$firstBad = -1
for ($a = 0; $a -lt $lines.Count; $a++) {
    $got = 0
    foreach ($ch in $back[$a].ToCharArray()) { $got = ($got -shl 1) -bor [int]([string]$ch) }
    if ($got -ne $img[$a]) {
        $mismatch++
        if ($firstBad -lt 0) { $firstBad = $a }
    }
}
Write-Host ("穷举校验（全部 {0} 个地址）：不一致 {1} 处，首个 {2}" -f $lines.Count, $mismatch, $firstBad)
if ($mismatch -ne 0) { throw "校验失败：.dat 与内存位图不一致" }

# ---- 结构自检（防止"看着是圆其实是方块"这种静默错误）------------------------
for ($p = 0; $p -lt $PAL; $p++) {
    $nz = 0
    for ($i = 0; $i -lt ($W * $H); $i++) { if ($img[$p * $W * $H + $i] -ne 0) { $nz++ } }
    if ($nz -lt 150) { throw ("水果 {0} 非零像素只有 {1}，位图几乎是空的" -f $p, $nz) }
    # 四边必须全透明，否则上屏会出现方框边
    for ($x = 0; $x -lt $W; $x++) {
        foreach ($y in @(0, ($H - 1))) {
            if ($img[$p * $W * $H + $y * $W + $x] -ne 0) { throw ("水果 {0} 的边界 ({1},{2}) 不是透明" -f $p, $x, $y) }
        }
    }
    for ($y = 0; $y -lt $H; $y++) {
        foreach ($x in @(0, ($W - 1))) {
            if ($img[$p * $W * $H + $y * $W + $x] -ne 0) { throw ("水果 {0} 的边界 ({1},{2}) 不是透明" -f $p, $x, $y) }
        }
    }
    Write-Host ("  pal {0}：非零像素 {1}" -f $p, $nz)
}

# 4 种水果必须互不相同（防止选错 pal 却看不出来）
for ($a = 0; $a -lt $PAL; $a++) {
    for ($b = ($a + 1); $b -lt $PAL; $b++) {
        $same = $true
        for ($i = 0; $i -lt ($W * $H); $i++) {
            if ($img[$a * $W * $H + $i] -ne $img[$b * $W * $H + $i]) { $same = $false; break }
        }
        if ($same) { throw ("水果 {0} 与 {1} 位图完全相同" -f $a, $b) }
    }
}
Write-Host "OK"
