[CmdletBinding()]
param(
    [string]$ModelSimPath = 'D:\Modelsim\modelsim_ase\win32aloem'
)

$ErrorActionPreference = 'Stop'

$root  = Split-Path -Parent $PSScriptRoot
$ram   = Join-Path $root 'sim\eram_spram_sim.v'
$src   = Join-Path $root 'user_source\hdl_source\isp\occ_gate_32.v'
$tb    = Join-Path $root 'sim\tb_occ_gate_32.sv'
$matrix = Join-Path $root 'sim\tb_occ_gate_32_matrix.sv'
$out   = Join-Path $root 'temp\modelsim\occ_gate_32'
$vlib  = Join-Path $ModelSimPath 'vlib.exe'
$vlog  = Join-Path $ModelSimPath 'vlog.exe'
$vsim  = Join-Path $ModelSimPath 'vsim.exe'

foreach ($path in @($ram, $src, $tb, $matrix, $vlib, $vlog, $vsim)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing required file: $path"
    }
}

New-Item -ItemType Directory -Force -Path $out | Out-Null
Push-Location $out
try {
    if (Test-Path -LiteralPath 'work') {
        Remove-Item -LiteralPath 'work' -Recurse -Force
    }
    & $vlib work
    if ($LASTEXITCODE -ne 0) { throw "vlib failed with exit code $LASTEXITCODE" }

    & $vlog -sv $ram $src $tb $matrix
    if ($LASTEXITCODE -ne 0) { throw "vlog failed with exit code $LASTEXITCODE" }

    foreach ($top in @('tb_occ_gate_32', 'tb_occ_gate_32_matrix')) {
        $lines = & $vsim -c -do "run -all; quit -f" "work.$top" 2>&1 |
                 ForEach-Object { $_.ToString() }
        $lines | ForEach-Object { Write-Host $_ }
        $text = $lines -join "`n"
        if (($LASTEXITCODE -ne 0) -or ($text -match '(?m)^# Errors:\s+[1-9]')) {
            throw "vsim failed for $top"
        }
    }
}
finally {
    Pop-Location
}
