<#
.SYNOPSIS
  为一台新的 worktree 铺好 TD Run 目录（syn_1 / phy_1），并把源文件登记同步到最新。

.DESCRIPTION
  Run 目录被 .gitignore 排除，新 worktree 必须从别处复制；历史上为此踩过两次坑：
    1) 新加的 .v 漏登记进两个 camera_to_dsi_display.prj → 综合报 HDL-8007 black box
       （eram_spram.v 就是这么丢的）；
    2) phy_1/settings.cfg 缺 `set phyWildParams {place opt_timing high}` → 布局的时序
       优化退回默认 medium，final Setup WNS 从 +820 ps 掉到 +226 ps 量级。
  本脚本把这两件事变成"每次都自动做"：从 -SourceWorktree 复制 Run 目录骨架文件，然后
  以 td_project/camera_to_dsi_display.al 的 <Source_Files> 列表为唯一事实源，把两个
  prj 里缺失的 user_source 条目幂等补齐（.al 里是 ../user_source/...，Run 目录在
  td_project/.../syn_1/ 下，所以要用三跳 ../../../user_source/...）。以后新增模块只要
  按规矩登记进 .al，跑一次 -SyncOnly 就同步到两个 Run 目录，不用手改 XML。

.PARAMETER SourceWorktree
  从哪个已有 worktree 复制 Run 目录骨架文件。默认主 worktree（有已知可用的 Run 目录）。
  只复制 settings.cfg / .prj / .tcl / run.bat（phy_1 另加 .bitgen_param.f），不复制
  几 MB 的数据库与日志。

.PARAMETER SyncOnly
  不复制，只做登记同步与已知补丁检查。新增 .v 并登记进 .al 之后跑这个即可。

.EXAMPLE
  pwsh -NoProfile -File tools/new_worktree_runs.ps1
  pwsh -NoProfile -File tools/new_worktree_runs.ps1 -SyncOnly
#>

[CmdletBinding()]
param(
    [string]$SourceWorktree = 'D:\competition\example\lab_ex4_integrated\lab_ex4_integrated',
    [switch]$SyncOnly
)

$ErrorActionPreference = 'Stop'

# 这几个文件全是 UTF-8 无 BOM + CRLF；写成 UTF-8 BOM 会让 TD 的解析器认出多余的
# 字符，所以显式用无 BOM 的编码回写。
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$root    = Split-Path -Parent $PSScriptRoot
$runsDir = Join-Path $root 'td_project\camera_to_dsi_display_Runs'
$alPath  = Join-Path $root 'td_project\camera_to_dsi_display.al'

$skeletonFiles = @{
    'syn_1' = @('settings.cfg', 'camera_to_dsi_display.prj', 'camera_to_dsi_display.tcl', 'run.bat')
    'phy_1' = @('settings.cfg', 'camera_to_dsi_display.prj', 'camera_to_dsi_display.tcl', 'run.bat', '.bitgen_param.f')
}

# ---- 1. 解析 .al，算出 Run 目录里应该有的 user_source 条目 ---------------------
if (-not (Test-Path -LiteralPath $alPath)) { throw "找不到 $alPath" }
$alText    = [IO.File]::ReadAllText($alPath)
$alEntries = [regex]::Matches($alText, '<File Path="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }

$wantPaths = @()
foreach ($e in $alEntries) {
    if ($e -like '../user_source/*') { $wantPaths += ('../../../' + $e.Substring(3)) }
}
$wantPaths = @($wantPaths | Sort-Object -Unique)
if ($wantPaths.Count -eq 0) { throw "没从 $alPath 里解析出 user_source 条目，检查文件格式是否变了" }

# ---- 2. 复制 Run 目录骨架 ------------------------------------------------------
$copied = @()
if (-not $SyncOnly) {
    foreach ($dir in $skeletonFiles.Keys) {
        $srcDir = Join-Path (Join-Path $SourceWorktree 'td_project\camera_to_dsi_display_Runs') $dir
        $dstDir = Join-Path $runsDir $dir
        if (-not (Test-Path -LiteralPath $srcDir)) { throw "源 Run 目录不存在：$srcDir" }
        if (-not (Test-Path -LiteralPath $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        foreach ($f in $skeletonFiles[$dir]) {
            $s = Join-Path $srcDir $f
            if (-not (Test-Path -LiteralPath $s)) { throw "源文件缺失：$s" }
            Copy-Item -LiteralPath $s -Destination (Join-Path $dstDir $f) -Force
            $copied += "$dir\$f"
        }
    }
}

# ---- 3. 把 prj 里缺失的登记幂等补齐 -------------------------------------------
$added = @{}
foreach ($dir in $skeletonFiles.Keys) {
    $prj = Join-Path (Join-Path $runsDir $dir) 'camera_to_dsi_display.prj'
    if (-not (Test-Path -LiteralPath $prj)) {
        throw "缺少 $prj —— 先不带 -SyncOnly 跑一次，把 Run 目录骨架复制过来"
    }

    $text    = [IO.File]::ReadAllText($prj)
    $missing = @()
    foreach ($p in $wantPaths) {
        if ($text.IndexOf('<File Path="' + $p + '">') -lt 0) { $missing += $p }
    }
    if ($missing.Count -eq 0) { continue }

    $nl  = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $idx = $text.IndexOf('</Source_Files>')
    if ($idx -lt 0) { throw "$prj 里找不到 </Source_Files>，格式与预期不一致" }

    # 插在 </Source_Files> 那一行之前，保持 TD 自己的缩进风格。
    $lineStart = $text.LastIndexOf($nl, $idx)
    $lineStart = if ($lineStart -lt 0) { 0 } else { $lineStart + $nl.Length }

    $blocks = ''
    foreach ($p in $missing) {
        $blocks += "            <File Path=""$p"">$nl" +
                   "                <FileInfo>$nl" +
                   "                    <Attr Name=""UsedInSyn"" Val=""true""/>$nl" +
                   "                    <Attr Name=""UsedInP&R"" Val=""true""/>$nl" +
                   "                </FileInfo>$nl" +
                   "            </File>$nl"
    }

    $newText = $text.Substring(0, $lineStart) + $blocks + $text.Substring($lineStart)
    [IO.File]::WriteAllText($prj, $newText, $utf8NoBom)
    $added[$dir] = $missing
}

# ---- 4. 已知补丁：phy_1 的 place opt_timing high ------------------------------
$phySettings = Join-Path $runsDir 'phy_1\settings.cfg'
$patched     = $false
if (Test-Path -LiteralPath $phySettings) {
    $cfg = [IO.File]::ReadAllText($phySettings)
    if ($cfg.IndexOf('phyWildParams') -lt 0) {
        $cfg = $cfg.TrimEnd("`r", "`n") + "`r`n" +
               "# 布局时序优化提到 high（2026-09-12）：TD 默认 medium，TMDS 串行域有一条 91% 走线的路径`r`n" +
               "set phyWildParams {place opt_timing high}`r`n"
        [IO.File]::WriteAllText($phySettings, $cfg, $utf8NoBom)
        $patched = $true
    }
}

# ---- 5. 汇报 ------------------------------------------------------------------
if ($copied.Count -gt 0) {
    Write-Host "已复制 Run 目录骨架（源：$SourceWorktree）：" -ForegroundColor Cyan
    $copied | ForEach-Object { "  $_" }
}
foreach ($dir in $added.Keys) {
    Write-Host "已补登记 $dir（$($added[$dir].Count) 条）：" -ForegroundColor Yellow
    $added[$dir] | ForEach-Object { "  $_" }
}
if ($patched) { Write-Host '已给 phy_1/settings.cfg 补上 set phyWildParams {place opt_timing high}' -ForegroundColor Yellow }

$total = 0
foreach ($dir in $skeletonFiles.Keys) {
    $prj = Join-Path (Join-Path $runsDir $dir) 'camera_to_dsi_display.prj'
    if (Test-Path -LiteralPath $prj) {
        $n = ([regex]::Matches([IO.File]::ReadAllText($prj), '<File Path="')).Count
        $total += $n
        Write-Host ("{0}: prj 登记 {1} 条" -f $dir, $n)
    }
}
Write-Host ("期待条目 {0} 条；两个 prj 合计 {1} 条" -f $wantPaths.Count, $total) -ForegroundColor Cyan
if ($copied.Count -eq 0 -and $added.Count -eq 0 -and -not $patched) {
    Write-Host '无需改动：Run 目录骨架与登记都已经是同步状态。' -ForegroundColor Green
}
