# AGENTS.md —— 本仓库的长期约定

安路 PH1P35（HX1P35A 开发板）FPGA 竞赛项目：MIPI 采集 → ISP → 边缘检测 → DDR2 → HDMI + OSD 已完成，
现在做**手势操控游戏**（规划见 `docs/手势游戏实现路线规划.md`）。M0（基础设施）已完成并上板验证，
tag `m0-infra-done`；当前进行 **M1 融合掩码跟踪链路**。

## 先读这些（按顺序）

1. `docs/A-进度交接.md` —— 当前状态、正在做什么、下一步、未决问题（**每次会话先读、收工前追加**）
2. `docs/A-识别支路任务清单.md` —— A 线（识别支路）的任务与边界，来源是规划文档 v1.8
3. `docs/手势游戏实现路线规划.md` —— 总规划（接口契约、资源账本、里程碑）
4. `README.md` §11 / §12 —— 资源现状与寄存器地址表

## 构建与验证

- 新 worktree 第一次：`pwsh -NoProfile -File tools/new_worktree_runs.ps1`（从仓库内 `tools/run_skeleton/` 铺 syn_1/phy_1，
  并按 `.al` 幂等补登记；会强制 `phy_1/settings.cfg` 带 `place opt_timing high` + `place max_fanout 250`）
- 构建：`pwsh -NoProfile -File tools/build_td.ps1`（约 10~15 分钟；脚本会检查日志 ERROR 与产物时间戳）
- 只打印现有报告：`pwsh -NoProfile -File tools/build_td.ps1 -Stage summary`
- 合并了带新模块的分支后：**必须** `pwsh -NoProfile -File tools/new_worktree_runs.ps1 -SyncOnly`
  （Run 目录不在版本库，`.prj` 不随合并走，漏了会报 `HDL-8007 black box`）
- TD 安装在 `D:\安路`；命令行通过 ASCII 联接 `D:\TangDynasty` 调用（TD 的 Tcl 不认中文路径）。
  许可证：`D:\安路\license\Anlogic.lic`（没有它 `optimize_rtl` 会失败，`elaborate` 仍可用）
- 串口日志：`.\tools\read_debug_uart.ps1 -Port COMx`（115200-8-N-1，脚本会追加写 `debug_uart.log`）

## 工作区与分支

- 主 worktree = 仓库根目录，跟 `main`：**只做集成、同步队友、出正式 bit**，永远保持能一次跑通构建。
- A 线 worktree = `.worktrees/m1`，分支 `feat/m1-mask`：识别支路的开发都在这里。
- 同一时刻只跑一个 TD 构建；每次上板记录 **worktree 路径 + 提交 + bit 的 SHA256**。
- `main` 只由 **C（队友）** 合并推进；我们提交只进 `feat/m1-mask`，交付前自己先跑一次完整构建。

## 文件所有权（改别人文件前先提需求）

| 归属 | 文件 |
|------|------|
| **A（我们）** | `user_source/hdl_source/isp/**`（含 `isp_top.v`、`edge_detect_96.v`、`recog_top.v`、`mask_stats.v`、`edge_win_3x3_96.v`、`ctrl_sync.v` 及新增模块） |
| **B** | `user_source/hdl_source/game/**` |
| **C** | `design_top_wrapper.v`、`hdmi_mixer.v`、模式寄存器模块、`debug_uart_logger.v`（只提字段申请）、`eram_spram.v`、`anlogic_logo_rom.v`、`osd_char_lib.v`、`shape_gen.v`、`td_project/**`（`.al`、`.prj`、`settings.cfg`、`.sdc`）、`user_source/constraints_source/**` |

DM 新增 `.v` 一律由 C 登记进 `.al` + 两个 `prj`；DBG 日志新增字段也向 C 提申请（字母 + 位宽 + 含义）。
目前已占用字母：`F A G T N B C M L D E W V K S P Q R U X Y`（`X/Y` 是 CTRL_SYNC 自检）。

## A 线的硬约束

- **只加 CSI 域（~59 MHz）逻辑**；不得新增 PLL/时钟；跨域只走 `ctrl_sync.v`（发送侧数据与 toggle 同拍锁存、
  接收侧两级同步 + 边沿检测后整包捕获）。TD 会忽略异步组之间的 `set_max_delay`，**不要指望 SDC 兜底**。
- 帧级统计相位：**计数按 valid、锁存按 tuser**（`awb.v` 的 tuser 是直通的，脉冲常落在 `valid=0` 的拍上）。
- 阈值/灵敏度等"魔法数字"一律走 PARAM_BUS（A 段 **0x40~0x7F**），禁止硬编码后重编译。
- 每个模块头必须写清：**延迟几拍 / 跨不跨域 / 要不要 SDC 约束 / 占多少 ERAM·DSP**。
- 资源纪律：A 的 LUT6 配额 1400、ERAM 8 块、**DSP 0**；肤色判定用 `(B−Y)/(R−Y)` 差值法，禁止改回逐像素矩阵乘法/距离平方。

## 交付配置（2026-09-27 起）

`user_source/hdl_source/isp/recog_top.v` 的**源码默认值就是交付配置**，不需要"编完再还原"：
`SKIN_ONLY=1`（运动/锁存门旁路）、`SOFT_TRACK=1`、`D2_MIN_DELIV=3`、真 luma `Y=(R+2G+B)/4`；
`isp_top.v` 的 `DIAG_MODE_SEL=0`（开机原画面，短按 KEY4 / `W 08 0001` 才出叠加）。
交付 bit 见 `bits/M1_DELIVERY_20260927_skin3.bit`（门禁：15329 slices / ERAM 70 / Setup +674 ps / 一次 PnR）。
8..15 是上板调参档（`W 08 000N`），调参时不需要改源码。

## 每个里程碑的门禁

编译实测（slices ≤85%，90% 红线）+ **final Setup WNS ≥ +300 ps** + feedthrough 不失控 + **一次布局布线成功**；
数据留档 + git tag 存档。板上验收按 `docs/A-识别支路任务清单.md` §7。
