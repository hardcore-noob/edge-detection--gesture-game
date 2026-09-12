<#
.SYNOPSIS
  跑 TD 综合 + 布局布线 + bitgen，并打印时序 / 资源 / bit 流汇总。

.DESCRIPTION
  与手工命令行流程完全一致（见 README 第 6 节、参考资料/TangDynasty_CLI编译流程.md）：
    syn_1：<run>\syn_1 下执行 td_commands_prompt.exe D:/TangDynasty/scripts/DefaultFlow.tcl
    phy_1：<run>\phy_1 下执行同一条命令（settings.cfg 里 parent=../syn_1、end_step=bitgen）
  两个要点：工作目录必须是 Run 目录；脚本路径必须用正斜杠，反斜杠会被 Tcl 当转义吃掉。

.PARAMETER Stage
  both（默认）= 综合 + 布局布线；syn = 只综合；phy = 只布局布线；summary = 不编译，
  只读现有报告打印汇总（改完代码前后对比数字时很方便）。

.EXAMPLE
  pwsh -NoProfile -File tools/build_td.ps1
  pwsh -NoProfile -File tools/build_td.ps1 -Stage summary
#>

[CmdletBinding()]
param(
    [ValidateSet('both', 'syn', 'phy', 'summary')][string]$Stage = 'both'
)

$ErrorActionPreference = 'Stop'

$root  = Split-Path -Parent $PSScriptRoot
$runs  = Join-Path $root 'td_project\camera_to_dsi_display_Runs'
$synD  = Join-Path $runs 'syn_1'
$phyD  = Join-Path $runs 'phy_1'
$exe   = 'D:\TangDynasty\bin\td_commands_prompt.exe'
$tcl   = 'D:/TangDynasty/scripts/DefaultFlow.tcl'

function Invoke-TdStage {
    param([string]$Name, [string]$Dir, [string]$Artifact)
    $start = Get-Date
    Write-Host "=== TD $Name  ($Dir)" -ForegroundColor Cyan
    $p = Start-Process -FilePath $exe -ArgumentList $tcl -WorkingDirectory $Dir -Wait -NoNewWindow -PassThru
    Write-Host ("EXIT={0}" -f $p.ExitCode)
    if ($p.ExitCode -ne 0) { throw "TD $Name 阶段失败，退出码 $($p.ExitCode)" }

    # TD 的退出码不反映源文件分析错误：分析失败时它会带着旧数据库继续往下跑，
    # 退出码照样是 0（2026-09-12 踩过：logger 里一个多余逗号导致 HDL-8007，整轮
    # 构建"成功"，但综合数据库和 bit 流全是上一版的）。所以必须自己验两件事：
    #   1) 本次生成的 td_*.log 里没有 ERROR；
    #   2) 本阶段的关键产物确实被这次运行更新过。
    $logs = Get-ChildItem -LiteralPath $Dir -Filter 'td_*.log' | Where-Object { $_.LastWriteTime -ge $start }
    if (-not $logs) { throw "TD $Name 阶段没有产生新的 td_*.log，八成根本没跑起来" }
    $errs = @()
    foreach ($l in $logs) { $errs += Select-String -LiteralPath $l.FullName -Pattern '\bERROR\b' -CaseSensitive }
    if ($errs.Count -gt 0) {
        $errs | Select-Object -First 8 | ForEach-Object { Write-Host ("    " + $_.Line.Trim()) -ForegroundColor Red }
        throw "TD $Name 阶段的日志里有 $($errs.Count) 条 ERROR（注意：TD 退出码仍是 0）"
    }
    $art = Join-Path $Dir $Artifact
    if (-not (Test-Path -LiteralPath $art)) { throw "TD $Name 阶段没有生成 $Artifact" }
    if ((Get-Item -LiteralPath $art).LastWriteTime -lt $start) {
        throw "$Artifact 没有被本次运行更新：后续阶段会拿旧网表继续跑，结果不可信"
    }
}

function Show-Summary {
    $phyTs   = Join-Path $phyD 'camera_to_dsi_display_phy.ts'
    $phyArea = Join-Path $phyD 'camera_to_dsi_display_phy.area'
    $bit     = Join-Path $phyD 'camera_to_dsi_display.bit'
    $cbit    = Join-Path $phyD 'camera_to_dsi_display_compress.bit'

    if (Test-Path -LiteralPath $phyTs) {
        Write-Host "--- 最终时序 (final)" -ForegroundColor Yellow
        Get-Content -LiteralPath $phyTs | ForEach-Object { "  $_" }
    }
    if (Test-Path -LiteralPath $phyArea) {
        $t = Get-Content -LiteralPath $phyArea -Raw
        Write-Host "--- 资源占用 (post-route)" -ForegroundColor Yellow
        foreach ($m in [regex]::Matches($t, '(?m)^\s*#(slice\*?|lut6|reg|eram|dram lut|shifter lut|feedthrough|dsp)\s+(.{0,40})$')) {
            "  {0,-14} {1}" -f $m.Groups[1].Value, $m.Groups[2].Value.Trim()
        }
        $mix = [regex]::Match($t, '(?m)^\|\s*u_hdmi_mixer\s*\|(.+)$')
        if ($mix.Success) { "  hdmi_mixer     " + ($mix.Groups[1].Value.Trim()) }
    }
    if (Test-Path -LiteralPath $bit) {
        Write-Host "--- bit 流（可直接烧录）" -ForegroundColor Yellow
        Get-ChildItem -LiteralPath $bit, $cbit -ErrorAction SilentlyContinue |
            ForEach-Object { "  {0}  {1} 字节  {2}" -f $_.Name, $_.Length, $_.LastWriteTime }
    } else {
        Write-Host "（还没有 bit 流，phy_1 阶段未跑或失败）" -ForegroundColor Red
    }
}

switch ($Stage) {
    'syn'     { Invoke-TdStage '综合 syn_1' $synD 'camera_to_dsi_display_gate.db' }
    'phy'     { Invoke-TdStage '布局布线 phy_1' $phyD 'camera_to_dsi_display.bit' }
    'both'    {
        Invoke-TdStage '综合 syn_1' $synD 'camera_to_dsi_display_gate.db'
        Invoke-TdStage '布局布线 phy_1' $phyD 'camera_to_dsi_display.bit'
    }
    'summary' { }
}

Show-Summary
