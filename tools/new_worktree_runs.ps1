<#
.SYNOPSIS
  为一台新的 worktree 铺好 TD Run 目录（syn_1 / phy_1），并把源文件登记同步到最新。

.DESCRIPTION
  Run 目录被 .gitignore 排除，新 worktree 必须重新生成；历史上为此踩过两次坑：
    1) 新加的 .v 漏登记进两个 camera_to_dsi_display.prj → 综合报 HDL-8007 black box
        （eram_spram.v 就是这么丢的）；
    2) phy_1/settings.cfg 缺 `set phyWildParams {place opt_timing high}` → 布局的时序
       优化退回默认 medium，final Setup WNS 从 +820 ps 掉到 +226 ps 量级。
  本脚本把这两件事变成"每次都自动做"：

  * 骨架来自**仓库内**的 tools/run_skeleton/{syn_1,phy_1}/（settings.cfg、.prj、.tcl、
    run.bat，phy_1 另加 .bitgen_param.f）——不依赖任何机器上的其它 worktree，clone 下来
    就能用；run.bat 里的 __TD_PATH__ 会换成 -TdPath（默认 D:/TangDynasty）。
  * 以 td_project/camera_to_dsi_display.al 的 <Source_Files> 列表为唯一事实源，把两个
    prj 里缺失的 user_source 条目幂等补齐（.al 里是 ../user_source/...，Run 目录在
    td_project/.../syn_1/ 下，所以要用三跳 ../../../user_source/...）。以后新增模块只要
    按规矩登记进 .al，跑一次 -SyncOnly 就同步到两个 Run 目录，不用手改 XML。

  为什么模板放 tools/ 而不是直接把 Run 目录纳入版本库：TD 每次构建都会改写 Run 目录里的
  settings.cfg / .prj（时间戳、行尾、CompileOrder 都会动），纳入版本库会让工作区每次
  构建后都变脏，而且 .prj 正是"只能由一个人登记"的那个文件，最容易冲突。模板在 tools/
  下不参与 TD 读写，既进版本库又不脏。

.PARAMETER SourceWorktree
  可选：从某个已有 worktree 的 Run 目录复制骨架（想抄一台"已知可用"的 Run 目录时用）。
  不给就用仓库内的 tools/run_skeleton/。只复制 settings.cfg / .prj / .tcl / run.bat
  （phy_1 另加 .bitgen_param.f），不复制几 MB 的数据库与日志。

.PARAMETER TdPath
  TangDynasty 安装路径，默认 D:\TangDynasty。用来替换骨架 run.bat 里的 __TD_PATH__，
  并检查 td_commands_prompt.exe 是否存在。

.PARAMETER SyncOnly
  不复制，只做登记同步与已知补丁检查。新增 .v 并登记进 .al 之后跑这个即可。

.EXAMPLE
  pwsh -NoProfile -File tools/new_worktree_runs.ps1
  pwsh -NoProfile -File tools/new_worktree_runs.ps1 -SyncOnly
#>

[CmdletBinding()]
param(
    [string]$SourceWorktree = '',
    [string]$TdPath = 'D:\TangDynasty',
    [switch]$SyncOnly
)

$ErrorActionPreference = 'Stop'

# 这几个文件全是 UTF-8 无 BOM + CRLF；写成 UTF-8 BOM 会让 TD 的解析器认出多余的
# 字符，所以显式用无 BOM 的编码回写。
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$root    = Split-Path -Parent $PSScriptRoot
$runsDir = Join-Path $root 'td_project\camera_to_dsi_display_Runs'
$alPath  = Join-Path $root 'td_project\camera_to_dsi_display.al'
$repoSkeleton = Join-Path $PSScriptRoot 'run_skeleton'

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
    # 骨架源：显式给了 -SourceWorktree 就用那台 worktree，否则用仓库内的模板
    $useExternal = ($SourceWorktree -ne '')
    $srcRoot = if ($useExternal) { Join-Path $SourceWorktree 'td_project\camera_to_dsi_display_Runs' } else { $repoSkeleton }
    $tdExe   = Join-Path $TdPath 'bin\td_commands_prompt.exe'
    if (-not (Test-Path -LiteralPath $tdExe)) {
        Write-Host "提示：$tdExe 不存在——run.bat 仍会按 -TdPath 生成，但本机跑不了 TD。" -ForegroundColor Yellow
    }

    foreach ($dir in $skeletonFiles.Keys) {
        $srcDir = Join-Path $srcRoot $dir
        $dstDir = Join-Path $runsDir $dir
        if (-not (Test-Path -LiteralPath $srcDir)) { throw "骨架源目录不存在：$srcDir" }
        if (-not (Test-Path -LiteralPath $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }
        foreach ($f in $skeletonFiles[$dir]) {
            $s = Join-Path $srcDir $f
            if (-not (Test-Path -LiteralPath $s)) { throw "骨架文件缺失：$s" }
            Copy-Item -LiteralPath $s -Destination (Join-Path $dstDir $f) -Force
            $copied += "$dir\$f"
        }

        # run.bat 里的 TD 路径按 -TdPath 落地（模板里写的是 __TD_PATH__ 占位符）
        $dstBat = Join-Path $dstDir 'run.bat'
        $bat = [IO.File]::ReadAllText($dstBat)
        if ($bat.IndexOf('__TD_PATH__') -ge 0) {
            $bat = $bat.Replace('__TD_PATH__', ($TdPath -replace '\\', '/'))
            [IO.File]::WriteAllText($dstBat, $bat, $utf8NoBom)
        }
    }
    $copied += "（骨架源：$(if ($useExternal) { $SourceWorktree } else { 'tools\run_skeleton' })）"
}

# ---- 3. 把 prj 里缺失的登记幂等补齐 -------------------------------------------
$added = @{}
foreach ($dir in $skeletonFiles.Keys) {
    $prj = Join-Path (Join-Path $runsDir $dir) 'camera_to_dsi_display.prj'
    if (-not (Test-Path -LiteralPath $prj)) {
        throw "缺少 $prj —— 先不带 -SyncOnly 跑一次，把 Run 目录骨架复制过来"
    }

    $text = [IO.File]::ReadAllText($prj)

    # 已经登记过就不动它，且**必须按原样保留所在段落**：prj 里不同后缀的文件分属不同
    # 段（.v/.sv 在 <Verilog>、.xml/.ipc 在 <IP_FILE>、.adc 在 <ADC_FILE>、.sdc 在
    # <SDC_FILE>）。把 .xml 之类搬进 <Verilog> 会被 TD 拒绝，2026-09-14 的自愈逻辑
    # 就是这么踩的坑——所以这里只做"缺什么补什么"，不移动已有条目。
    $missing = @()
    foreach ($p in $wantPaths) {
        $n = ([regex]::Matches($text, [regex]::Escape('<File Path="' + $p + '">'))).Count
        if ($n -eq 0) { $missing += $p }
        elseif ($n -gt 1) { throw "$prj 里 $p 登记了 $n 次，先手工去掉重复条目" }
    }
    if ($missing.Count -eq 0) { continue }

    # 新条目只可能是 Verilog 源（.v）：<Verilog> 段里逐条登记。放进 </Source_Files>
    # 之前会落到 <IP_FILE> 段外，TD 报 `PRJ-8641 ERROR: XML tag File is invalid`。
    $nonVerilog = @($missing | Where-Object { -not $_.EndsWith('.v') })
    if ($nonVerilog.Count -gt 0) {
        throw ("这些新条目不是 .v，脚本不知道它们该进哪一段，请手工登记：`n  " + ($nonVerilog -join "`n  "))
    }

    $nl     = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $vStart = $text.IndexOf('<Verilog>')
    $vEnd   = $text.IndexOf('</Verilog>')
    if ($vStart -lt 0 -or $vEnd -le $vStart) { throw "$prj 里找不到 <Verilog> 段，格式与预期不一致" }

    $head = $text.Substring(0, $vStart)
    $body = $text.Substring($vStart, $vEnd - $vStart).TrimEnd("`r", "`n", " ") + $nl
    $tail = $text.Substring($vEnd)

    # 版本段里每一个设计源条目都带 BelongTo + CompileOrder，两个 Attr 缺一不可：
    # 只写 UsedInSyn/UsedInP&R 时 TD 不报具体原因，只说
    # `PRJ-8640 ERROR: Open project file ... failed because of previous error(s)`
    # （2026-09-14 用只做 open_project 的探针逐个变体试出来的）。
    # CompileOrder 取现有最大值 +1 后逐条递增。
    $maxOrder = 0
    foreach ($m in [regex]::Matches($text, 'CompileOrder" Val="(\d+)"')) {
        $v = [int]$m.Groups[1].Value
        if ($v -gt $maxOrder) { $maxOrder = $v }
    }

    $blocks = ''
    foreach ($p in $missing) {
        $maxOrder++
        $blocks += "            <File Path=""$p"">$nl" +
                   "                <FileInfo>$nl" +
                   "                    <Attr Name=""UsedInSyn"" Val=""true""/>$nl" +
                   "                    <Attr Name=""UsedInP&R"" Val=""true""/>$nl" +
                   "                    <Attr Name=""BelongTo"" Val=""design_1""/>$nl" +
                   "                    <Attr Name=""CompileOrder"" Val=""$maxOrder""/>$nl" +
                   "                </FileInfo>$nl" +
                   "            </File>$nl"
    }

    $newText = $head + $body + $blocks + $tail
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
               "# 布局参数（2026-09-14 参数实验选出的最优组合，见 CHANGELOG《参数实验》）：`r`n" +
               "#   opt_timing high + max_fanout 250`r`n" +
               "set phyWildParams {place opt_timing high place max_fanout 250}`r`n"
        [IO.File]::WriteAllText($phySettings, $cfg, $utf8NoBom)
        $patched = $true
    }
}

# ---- 5. 汇报 ------------------------------------------------------------------
if ($copied.Count -gt 0) {
    Write-Host "已复制 Run 目录骨架：" -ForegroundColor Cyan
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
