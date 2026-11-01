[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$work = Join-Path $root 'temp\modelsim_game'
$lib  = Join-Path $work 'game_sim'

foreach($tool in @('vlib', 'vlog', 'vsim')) {
    if(-not (Get-Command $tool -ErrorAction SilentlyContinue))
        { throw "找不到 ModelSim 工具：$tool" }
}

New-Item -ItemType Directory -Force -Path $work | Out-Null
if(-not (Test-Path -LiteralPath $lib)) {
    vlib $lib | Out-Null
    if($LASTEXITCODE -ne 0) { throw "vlib 失败：$lib" }
}

$sources = @(
    'user_source\hdl_source\param_ctrl.v',
    'user_source\hdl_source\game\game_score.v',
    'user_source\hdl_source\game\game_render.v',
    'user_source\hdl_source\game\game_fruit.v',
    'user_source\hdl_source\game\game_catch.v',
    'sim\tb_game_score.sv',
    'sim\tb_param_ctrl.sv',
    'sim\tb_game_render.sv',
    'sim\tb_game_fruit.sv',
    'sim\tb_game_catch.sv'
) | ForEach-Object { Join-Path $root $_ }

$vlogArgs = @('-sv', '-work', $lib) + $sources
vlog @vlogArgs
if($LASTEXITCODE -ne 0) { throw 'ModelSim 编译失败' }

Push-Location $work
try {
    foreach($tb in @('tb_param_ctrl', 'tb_game_score', 'tb_game_render', 'tb_game_fruit', 'tb_game_catch')) {
        $output = & vsim -c -work $lib $tb -do 'run -all; quit -f' 2>&1
        $output
        if($LASTEXITCODE -ne 0 -or -not ($output -match 'PASS:'))
            { throw "$tb 未通过" }
    }
}
finally {
    Pop-Location
}

Write-Host 'PASS: all fruit gameplay simulations completed'
