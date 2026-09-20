# A 线进度交接（每次会话先读、收工前追加）

> 规则：**只在文件末尾追加新段落**，不要改历史段落（避免多人/多会话冲突）。
> 新会话第一句建议："读 docs/A-进度交接.md 和 docs/A-识别支路任务清单.md，我们继续 M1。"

## 固定信息（不常变）

- **工作区**：A 线 worktree = `.worktrees/m1`，分支 `feat/m1-mask`（基于 `main @ 8fd7a0c`）。
  主 worktree（仓库根）跟 `main`，只做集成/同步/出正式 bit。
- **构建**：`pwsh -NoProfile -File tools/new_worktree_runs.ps1`（首次或合并带新模块的分支后）→
  `pwsh -NoProfile -File tools/build_td.ps1`
- **上板**：烧写由本人负责；串口日志 `.\tools\read_debug_uart.ps1 -Port COMx`
- **工作方式（2026-09-20 定）**：按 M1 五步走，**每一步都上板验证**；每一步都编译实测 + 记录。
- **交付**：只提交到 `feat/m1-mask`；`main` 由 C 合并。

## M1 五步计划（每步都要上板）

| 步 | 内容 | 上板验收物 | 状态 |
|----|------|-----------|------|
| 0 | 环境与基线：worktree 铺 Run 目录 + 复现 M0 基线（≈13481 slices / +876 ps） | 基线数字对上；用这份 bit 验证烧写链路 | **✅ 已完成（2026-09-20）** |
| 1 | 肤色掩码 `(B−Y)/(R−Y)` + 接到 `mask_stats`（先用现有 DBG 的 P/Q/R 看数） | 手/脸/木桌三组 P/Q/R 对比表 | 未开始 |
| 2 | 背景帧 80×45（2 块 ERAM）+ 阈值 → 运动掩码；与肤色按位与 → 融合掩码 | 手静止仍检出、类肤色背景不误锁、移开再回能重锁 | 未开始 |
| 3 | `mask_win_3x3.v` 开运算 + ROI 门控 + α-β 滤波/5 帧保持 | 准星平滑、出画 5 帧丢失、回画 3 帧重锁 | 未开始 |
| 4 | OSD 准星 + 包围盒叠加；一键示教（min/max 包络 + 两段式指示 + 超时） | 换光照 3 秒恢复、示教瞬间 A/G 进日志 | 未开始 |
| 5 | M1 收尾：编译实测 + 记录 + tag + 交 C 合并 | 门禁全过 | 未开始 |

## 记录模板

**编译记录**（每步一行）：

| 日期 | 提交 | slices | LUT6 | ERAM | DSP | final Setup WNS | feedthrough | 一次 PnR？ |
|------|------|--------|------|------|-----|-----------------|-------------|-----------|
| 2026-09-20 | `39ba9a3`（未改 RTL） | 13481（63.54%） | 11192 | 70 | 8 | **+876 ps**（Hold +20 ps，0 违例） | 6862 | ✅ 是 |

**上板记录**（每步一行，场景见任务清单 §7）：

| 日期 | bit SHA256 | 场景 | P | Q | R | H(新增) | 结论 |
|------|-----------|------|---|---|---|--------|------|
| | | | | | | | |

---

## 2026-09-20　会话记录

**做了什么**
- 同步队友最新 `main @ 8fd7a0c`（v1.8 规划：12 条审查修正，含肤色判定改差值法、背景帧改 80×45、
  quiet 门控背景更新、CTRL_SYNC 字义冻结、A 的 LUT6 分项 ≈1410）。
- 把 A 线任务清单更新到 v1.8（`docs/A-识别支路任务清单.md`）。
- 建好 A 线 worktree `.worktrees/m1`（分支 `feat/m1-mask`），并加 `AGENTS.md`（长期约定）。
- 定下工作方式：五步走、每步上板、烧写由本人负责。

**未决/待确认**
- M1 的 LUT6 分项合计 ≈1410，已超 A 的 1400 配额（直方图 300~500 未计入）→ 每步编译后要看余量，
  超了先砍可选直方图。
- Step 1 的肤色阈值必须在板上标定（不能抄教科书 Cb/Cr 数值），所以 Step 1 结束需要一次上板数据。
- 需要向 C 提的申请（后续累积）：DBG 新增字段（建议 `H` = 融合掩码像素数，16 位）。

**下一步**
- ✅ 基线已复现（见上表）→ 开始 Step 1：在 `isp/recog_top.v` 里做 `(B−Y)/(R−Y)` 肤色掩码，接到现成的 `mask_stats`。
- 上板（本人负责）：用本 worktree 的基线 bit 先验证烧写链路 + `read_debug_uart.ps1` 能收到 `DBG:` 行。

## 2026-09-20（第二次追加）　基线复现结果

- worktree：`.worktrees/m1`（分支 `feat/m1-mask`）；Run 目录由 `tools/new_worktree_runs.ps1` 生成
  （syn_1 / phy_1 各登记 68 条；脚本确认 `place opt_timing high` + `place max_fanout 250` 都在）。
- 构建：`pwsh -NoProfile -File tools/build_td.ps1` 全程 EXIT=0，无 ERROR。
- **结果与 M0 基线完全一致**：slice 13481（63.54%）、LUT6 11192、reg 14661、ERAM 70（64.81%）、
  DSP 8、feedthrough 6862、final Setup WNS **+876 ps** / Hold **+20 ps**，0 违例，一次布局布线成功。
- 最紧路径：`HDMI_PIXEL_CLK -> HDMI_SERIAL_CLK`，slack 0.876 ns，逻辑级数 1，延迟 1.595 ns（net 占 79%）
  —— 和队友记录的同一条（纯走线问题）。
- bit 产物（可直接烧录）：
  - `td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`，1789547 B，sha256 前 16 位 `995F7209907BBCD5`
  - `.../camera_to_dsi_display_compress.bit`，1481225 B，sha256 前 16 位 `95A127F2FFD366B8`

**结论**：A 线 worktree 环境可用，基线可信，可以开始写 M1 的 RTL。
