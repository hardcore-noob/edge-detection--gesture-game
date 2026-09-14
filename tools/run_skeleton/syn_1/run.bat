@echo off

rem 这个文件是 tools/run_skeleton/ 里的模板，tools/new_worktree_runs.ps1 会把它复制到
rem Run 目录，并把 __TD_PATH__ 换成实际的 TangDynasty 安装路径（默认 D:/TangDynasty）。
rem 平时我们走 tools/build_td.ps1 直接调 TD，不需要点这个 bat；它只是留一条"手工双击
rem 也能跑"的路子。

set HD_SDIR=%~dp0
cd /d "%HD_SDIR%"
"__TD_PATH__/bin/td_commands_prompt.exe" "__TD_PATH__/scripts/DefaultFlow.tcl"
pause
