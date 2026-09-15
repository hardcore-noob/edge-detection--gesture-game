# 开发记录（CHANGELOG）

> 这不是发布版本号，而是按日期记录“改了什么、为什么、实测多少、上板结论如何”的开发日志。
> README 只保留**当前状态 + 操作 + 规则**；过程数据、被否掉的方案和踩坑原因放这里。
>
> 记录原则：只写从代码和 `git log` 看不出来的东西——实测数字（WNS / slices / ERAM）、
> 上板结论（哪天哪版烧过、画面表现）、被否掉的方案及原因、失败与调试过程。
>
> 下面的《资源优化》《串口日志》小节沿用 README 原来的编号（11.1.x、第 7 节），方便和提交对照。

## 资源优化

汇总：slices 16957（79.93%，`main` @ `0ec7385`）→ **13214（62.28%）**，final Setup WNS
+242 ps → **+820 ps**（都 0 违例）。2026-09-12 在 `feat/resource-opt` 上分五步完成并合并
进 `main`（`4b1ec22`）：Logo ROM 搬 ERAM（−2378）、logger 精简（−120）、边缘行缓存搬
ERAM（−1457）、place `opt_timing high`（+226 → +866 ps，不改 RTL）、FIFO 观测增强
（+227）。选型依据与余量规则见 README 第 11 节。

### 11.1.1 资源优化第一版：Logo ROM 搬 ERAM（`feat/resource-opt` @ `0aa5c25`）

2026-09-12 的构建（`pwsh -NoProfile -File tools/build_td.ps1`，综合 + 布局布线 +
bitgen 一次通过）：

| 资源              | 优化前（`main` @ `0ec7385`） | 优化后（本分支）          | 变化    |
| --------------- | ----------------------- | ----------------- | ----- |
| slices          | 16957（79.93%）           | **14579（68.72%）** | −2378 |
| LUT6            | 14972                   | 12306（58.00%）     | −2666 |
| ERAM            | 39                      | 64（59.26%）        | +25   |
| 触发器             | 14356                   | 14617             | +261  |
| 分布式 RAM         | 1448 LUTRAM + 112 SRL   | 1448 + 112        | 不变    |
| feedthrough     | 6809                    | 6693              | −116  |
| final Setup WNS | +242 ps（0 违例）           | **+733 ps（0 违例）** | 余量变大  |
| final Hold WNS  | +20 ps（0 违例）            | +20 ps（0 违例）      | —     |

层次面积表（`phy_1/camera_to_dsi_display_phy.area` 的 `Report Hierarchy Area`）印证了
收益来源：`u_hdmi_mixer` 的 logic lut 从 **2633 → 262**，其中新的子模块
`u_anlogic_logo_rom` 只占 7 个 LUT + **25 块 ERAM** —— 省下来的就是原来那块
6387 条 case 的组合 ROM。bitstream：
`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`
（1,789,547 字节；`_compress.bit` 1,454,409 字节）。

**已上板确认（2026-09-12）**：这一版 bitstream 烧进去后画面与 Logo 均正常，
RAW/EDGE 与 OSD 表现与优化前一致 —— 也就是说这次省下 2378 个 slice 没有付任何
画面代价。

两点代价要记住：ERAM 从 36% 涨到 59%（还剩 44 块，够用，但"把每一级延迟线都搬
ERAM"这种打法要算着用）；触发器 +261，来自 ERAM 输出/地址这一级流水。

### 11.1.2 资源优化第二版：精简调试/观测逻辑（第一批，2026-09-12）

只做了"语义不变"的那一半，第二批（T 字段瘦身）和第三批（N/B/C 抽样、删 A/G）
因为性价比太低被用户否掉，不再做。这一批改了两处：

1. **删掉 logger 的 9 组输入双寄存器**（约 300 个 FF）。`debug_uart_logger` 的
   `I_clk` 就是统计计数器所在的 `S_hdmi_pixel_clk`，字段本来就在同一时钟域，
   两级寄存器只是延迟、不提供同步；真正跨域的只有 M（RAW10 峰值），它在
   `design_top_wrapper` 里已经用 `S_dbg_raw_max_sync1/2` 同步过并锁存在 `_hold`
   里（整帧稳定）。原写法是从"logger 跑在另一个时钟域"的年代留下来的。
2. **行模板拆成"常量字节表 + nibble 源表 + 一份 hex 编码器"**：原来 70 分支的
   case 把 4->8 位 hex 编码写在 38 个数字分支里，现在编码只有一份，两个调用点
   也共用同一个组合结果（`S_next_idx` 选下一字节）。

| 指标                    | 改前（11.1.1）       | 改后                  | 变化                  |
| --------------------- | ---------------- | ------------------- | ------------------- |
| slices                | 14579（68.72%）    | **14459（68.15%）**   | −120                |
| LUT6                  | 12306            | 12219（57.59%）       | −87                 |
| 触发器                   | 14617            | **14350**           | −267                |
| `u_debug_uart_logger` | 201 LUT / 351 FF | **105 LUT / 78 FF** | −96 LUT / −273 FF   |
| final Setup WNS       | +733 ps          | +522 ps（0 违例）       | 落点变了，仍在 +300ps 基线之上 |
| final Hold WNS        | +20 ps           | +20 ps（0 违例）        | —                   |

日志的字段、顺序、编码完全没变：行模板由脚本对 70 个位置逐项比对（含 20 组随机
字段值重建整行）确认与旧实现逐字节一致，所以 `tools/read_debug_uart.ps1` 和
第 7 节的字段说明都不用改。

### 11.1.3 资源优化第三版：行缓存搬 ERAM（2026-09-12）

11.3 表里剩下最大的一块：`edge_detect_96` 的三块行缓存（面积表 `dram lut = 1152`）。
做法与 Logo ROM 同一套路 —— TD 不认 `ram_style` 属性，必须显式例化
`PH1P_LOGIC_ERAM`；这次把它收成通用封装 `user_source/hdl_source/eram_spram.v`
（单口、1 拍读延迟、`FILL_ALL("0")`），三块缓存各例化一个。

时序上是"纯换存储介质"：原写法 `mid_r <= line_memN[x_grp]` 本来就是"地址寄存 + 数据
打一拍"，正好等于 ERAM 的 `REGMODE_A="OUTREG"`，所以改动只在于：

- `mid_r` / `top_r` 从寄存器改成直接引 ERAM 输出（**不再多打一拍**）；
- 读侧选择用**上一拍**的轮转相位（`row_phase_d1`），因为地址是在那一拍给出的；
- 写数据 `sm0..sm3` / `win_cur` 从 always 块里的变量提成显式线网 `S_sm0..S_sm3` /
  `S_win_cur`（否则写数据可能被当成寄存器、比写地址晚一拍，行缓存整体错 4 个像素）；
- 写使能带上 `I_rst_n`（原实现的写操作在 always 块的"非复位"分支里）。

**流水线深度与逐拍对齐完全没变**，理论上画面应与改前逐像素一致。

| 指标 | 改前（11.1.2） | 改后 | 变化 |
|------|----------------|------|------|
| slices | 14459（68.15%） | **13002（61.28%）** | −1457 |
| LUT6 | 12219 | 10743（50.64%） | −1476 |
| 触发器 | 14350 | 14032 | −318 |
| 分布式 RAM（LUTRAM） | 1448 | **296** | −1152 |
| ERAM | 64（59.26%） | 70（64.81%） | +6 |
| feedthrough | 6724 | 6626 | −98 |
| final Setup WNS | +522 ps | **+226 ps**（0 违例） | 余量变小，见下 |
| final Hold WNS | +20 ps | +20 ps（0 违例） | — |

层次面积表印证：`u_edge_detect_96` 的 `eram = 6`、`dram lut = 0`，三块
`u_line_mem0/1/2`（`eram_spram`）各占 2 块 —— 48 位宽被拆成 40+8 两列。

ERAM 用掉 6 块后还剩 38 块（共 108）。Setup 余量从 +522 掉到 +226 ps：0 违例，但
低于第 11.4 节建议的 +300 ps 基线，可能因为 ERAM 是固定列资源、ISP 逻辑落点被牵动；
后面再动 ISP 之前先重新确认这个数字。

### 11.1.4 时序余量：place 的 opt_timing 提到 high（2026-09-12）

11.1.3 之后全局 WNS 掉到 +226 ps。用 `tools/build_td.ps1` 新加的"分时钟域余量"一看，
紧的根本不是我们写的逻辑：

| 路径组 | medium | high（本次） |
|--------|--------|--------------|
| HDMI_SERIAL_CLK -> 自身（375 MHz） | **0.226 ns** | 1.120 ns |
| HDMI_PIXEL_CLK -> HDMI_SERIAL_CLK | 0.876 ns | 1.086 ns |
| HDMI_PIXEL_CLK -> 自身（75 MHz，我们的逻辑） | 1.057 ns | 1.560 ns |
| MIPI_RX_BYTE_CLK / DDR usr_clk 等 | 5.0 ~ 37.8 ns | 5.0 ~ 37.4 ns |

最紧那条路径是 `u0_lane_lvds_8_1` 里从一个触发器到 IO 里 ODDR 输入：
**延迟 2.221 ns 里 net 占 2.006 ns（91%）、逻辑级数 0** —— 发射触发器被布局器摆到了
离 ODDR 13 列远的地方，纯走线问题。所以"拆大 mux / 打通全局拥挤"对它没用（没有逻辑
可拆，全局利用率也只有 61%），真正的杠杆是**落点**。

改法：Run 目录 `settings.cfg` 里加 `set phyWildParams {place opt_timing high}`
（默认 medium，见第 6 节）。一次布局布线之后：

| 指标 | medium | high |
|------|--------|------|
| 全局 final Setup WNS | +226 ps | **+866 ps** |
| slices | 13002（61.28%） | 12987（61.21%） |
| LUT6 / 触发器 | 10743 / 14032 | 10738 / 14036 |
| feedthrough | 6626 | 6513 |
| final Hold WNS | +20 ps（0 违例） | +20 ps（0 违例） |
| place / route 耗时 | 2m04s / 58s | 2m08s / 57s |

**结论**：遇到"余量薄"先看分时钟域余量和最紧路径的 net 占比，再决定是改逻辑还是改
落点。这条路径靠落点修，代价接近零；反过来，为了它去动全局打包/feedthrough 是白费力气。

> 说明：这次只改了布局参数、RTL 与综合网表都没动，所以逻辑功能与 11.1.3 那版逐位
> 一致，只是重新布局布线后的 bitstream。

### 11.1.5 观测增强：FIFO 丢写与占用进 DBG 行（2026-09-12，`4b1ec22`）

`video_in` / `video_out` 的 FIFO 原来在写满时**静默丢数据**，光看画面很难发现。这一版
把两边 FIFO 的丢写计数和每帧最大占用同步到显示域，按帧差上报成 DBG 行的
`D` / `E` / `W` / `V` 四个字段（读法见第 7 节）：`D`/`E` 非 0 就说明真的丢过数据，
`W`/`V` 接近 `0x1FF` 说明离写满很近。

| 指标 | 11.1.4 | 本次（当前 `main`） | 变化 |
|------|--------|------------------|------|
| slices | 12987（61.21%） | **13214（62.28%）** | +227 |
| LUT6 | 10738 | 10809（50.95%） | +71 |
| 触发器 | 14036 | 14256 | +220 |
| feedthrough | 6513 | 6767 | +254 |
| final Setup WNS | +866 ps | **+820 ps**（0 违例） | 略降 |
| final Hold WNS | +20 ps | +20 ps（0 违例） | — |

bitstream：`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`

### 附：Logo 地址的 DSP 乘法器（2026-09-10 前后）

Logo 的 ROM 地址原来是 `S_logo_y * LOGO_W`，会被综合成一个 DSP 乘法器，而
`mult0 → Logo ROM → O_hdmi_data_reg` 正好是 75MHz 像素域上最紧的一条路径（TD 报
Setup 差 99 ps 就落在它上面）。`LOGO_W = 160 = 128 + 32`，现在写成移位加法
`((y<<7) + (y<<5)) + x`，数值完全等价、少用一个 DSP，这条路径也不再是瓶颈。

## 串口日志

字段语义与脚本用法见 README 第 7 节；这里记成因、改法和上板验证数据。

### 1. 分频位宽：9 位装不下 651 的分频值

日志模块里的两个位宽都从参数推导（`debug_uart_logger.v` 的 `CLK_PER_BIT_W`、
`LOG_TICKS_W` 用 `$clog2` 算），**不要写死**——720P 升级把 `CLK_HZ` 从 52 MHz 改成
75 MHz 时踩过这个坑：

- 115200 的分频值是 651，而 `S_tx_div` 当时只有 9 位（0..511），比较永不成立，
  状态机进 `TX_START` 后就停在起始位、TXD 恒低，日志完全不再输出；
- `TIMEOUT_CNT` 当时写死 26 位，74,999,999 被截断成 7,891,135；即使修好分频，
  日志周期也只有 0.105 s 而不是 1 s。

分频值同时从 `ceil` 改成四舍五入（651，误差 +0.006%；`ceil` 得到的 652 是 -0.15%）。
同一个函数里 `F_line_byte` 的 case 标签也必须写成 `7'd64..7'd68`：写成 6 位字面量
时值会退化成 0..4 并落进 `default`，`L` 字段整段发的是空格、CR 也没了。
这一版已在板上确认：日志恢复正常输出，分频、1 s 周期和 `L` 字段都对。

### 2. 帧首锁存与 PowerShell 脚本

2026-09-12 又补了两个后来才发现的坑（都先在 `feat/edge-denoise` 分支上修好，再摘到
`main`）：

- **同一行的字段必须取自同一帧**。一行 70 字节按 115200-8-N-1 要发约 6 ms，而一帧
  只有 16.5 ms，1 s 的日志节拍又和 60.6 fps 不同步：以前 `N/B/C/M/L` 是边发边采样的，
  落在帧内不同时刻——板上出现过 `B > N`（同一个快照不可能），`M` 在相邻行之间
  1023/247/1023 反复跳。现在 `design_top_wrapper.v` 在帧首（显示器帧 `S_hdmi_user`、
  相机帧 `S_raw_tuser`）先把计数器搬进 `*_hold` 寄存器再清零，日志只报上一完整帧。
- **`tools/read_debug_uart.ps1` 在 Windows PowerShell 5.1 上会先报错再正常工作**：
  脚本原来无条件执行 `Add-Type -AssemblyName System.IO.Ports`，而 5.1、PowerShell
  7.0~7.3 下这个程序集找不到（`ASSEMBLY_NOT_FOUND`），类型本身却已经可用。现在改成
  先探测类型、再按路径加载、最后才报错；选口改用
  `[System.IO.Ports.SerialPort]::GetPortNames()`（`Win32_SerialPort` 在部分环境查不到，
  会误报 No serial port found），并新增 `-ProbeSec` 体检模式（打印原始字节数与 hexdump，
  用来区分“线上一个字节都没有”和“收到乱码”）；脚本保存为带 BOM 的 UTF-8，否则
  PowerShell 5.1 会把里面的中文按 GBK 解码。

这两处的 TD 结果：**final Setup WNS +242 ps / TNS 0 / 0 违例，Hold +20 ps / 0 违例，
slices 16957（79.93%）**；脚本已在 PowerShell 5.1 实测不再报错。

**帧首锁存已在板上确认（2026-09-12，同一画面的 12 行日志）**：

- `N` 在 19634~20018（±1%）、`B` 2588~2667、`C` 645~666、`M` 722~831 之间小幅波动，
  相邻行不再成倍跳变；此前出现过的 `B > N`（892294 > 790449）彻底消失，`N` 也不再
  在 4633~33109 之间乱窜——说明一行里的字段确实取自同一个完整帧。
- `F` 每行递增 60~61（0x3C / 0x3D），与 60.6 fps、1 s 节拍一致；`L=FF` 正常输出，
  分频 / 周期 / `L` 字段那三个修复同时得到确认。

## 边缘算法调参

### 幅度对比（1024x600 + 旧灰度公式的历史数据）

幅度对比（下表是 **1024x600 + 旧灰度公式** 下的历史数据，用来比较“组平均 vs 全
分辨率”的几何差异，不代表当前配置的数值）：

| 竖线宽度  | 官方组平均版 | 原 `EDGE_TH=132` | 全分辨率版（门限 16） |
| ----- | ------ | --------------- | ------------ |
| 1 像素  | 40     | 消失              | 168          |
| 2 像素  | 84     | 消失              | 252          |
| ≥3 像素 | ≥124   | 3 像素仍消失         | ≥252         |

上表是 Sobel 幅度本身（旧公式的压缩域）。两版的局部差分基本一致，所以新公式下
这些幅度也差不多；旧公式多出来的 ±85 假跳变会让部分区域直接饱和成白块，这正是
旧版图里那些成片白色细节的来源。

### 上板 A/B 结论与历史配置

上板 A/B 对比（第一步：组平均 + 增益 2 / 第二步：全分辨率 + 增益 0）的结论：
**第一步的笔画更粗，但两版明暗肉眼分辨不出**。粗笔画说明第一步那种"更好看"
有相当一部分来自组平均把边缘摊成 4 像素的副作用；明暗无差异说明真实笔画宽度多在
3 像素以上、两版都已接近饱和。因此保留全分辨率几何，把增益调回 1。

历史配置（全分辨率 + 旧公式 + 增益 1 + 门限 16）在 1024x600 与 720P 两种分辨率下
都已上板测试、细笔画效果良好。当前配置（全分辨率 + 官方 luma 公式 + 增益 0 +
门限 16）已通过 TD（`main` @ `f6903de`，final Setup WNS +596 ps / Hold +20 ps、
0 违例），bitstream 在
`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`；
**已上板确认（2026-09-12），效果优秀**：原先的观察重点（弱边缘/印刷细节是否与旧版
相当、旧公式那种回绕假边是否消失）都已合格，这一版就是当前基线。

## 构建记录

历次构建的时序与资源（同一器件、同一工程，TD Release_2026.1_SP2）：

| 日期 / 版本 | 说明 | final Setup WNS | slices | 备注 |
|------------|------|-----------------|--------|------|
| 2026-09-09 及之前 | 1024x600 基线 | 早期曾 −8466 ps，修正后转正 | 15852 ~ 16324 | 细节见 git 历史 |
| 2026-09-10 `feat/720p` 首版 | 1024x600 → 720P | +271 ps | 16101 | 已上板确认画面/按键/OSD |
| 2026-09-11 `feat/edge-luma` | 官方 luma 公式 + TH16 + 增益 0 | +9 ps | 16092 | 余量极薄；同设计的 TH48 版是 +728 ps |
| 2026-09-11 `main` @ `f6903de` | 修 UART 分频 / 周期 / `L` 字段 | +596 ps | 16627 | 上板确认日志恢复 |
| 2026-09-12 `main` @ `0ec7385` | 加帧首锁存 | +242 ps | 16957（79.93%） | 上板确认统计稳定 |
| 2026-09-12 `main` @ `4b1ec22` | 资源优化 4 轮 + FIFO 观测 | **+820 ps** | **13214（62.28%）** | 当前基线 |

下面这条是 `0ec7385` 那版的完整记录（其余各版的细节见 README 第 10、11 节与各自的提交）：

构建结果（TD Release_2026.1_SP2，`main` @ `0ec7385`，新公式 + TH16 + 增益 0，含第 7
节的串口日志修复与帧首锁存）：**final Setup WNS +242 ps / TNS 0 / 0 违例，
Hold WNS +20 ps / 0 违例**，slices 16957（79.93%）、RAM 39、DSP 8。时序余量对
布线落点很敏感（同一设计的 TH48 版 +728 ps、`feat/720p` 首版 +271 ps、
`feat/edge-luma` 那版 +9 ps、帧首锁存前的 `main` +596 ps），但都 0 违例。bitstream：
`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`。

两点经验：

1. **时序余量对布线落点极敏感**：同一套逻辑从 +728 ps 到 +9 ps 都出现过，所以“这次能过”不等于“下次也能过”，改动后必须重新跑构建。
2. **遇到余量薄，先看分时钟域余量和最紧路径的 net 占比**（`tools/build_td.ps1` 会打印），再决定是改逻辑还是改落点——`place opt_timing high` 那次纯靠落点把 375 MHz 域从 0.226 ns 拉到 1.120 ns，代价接近零。

## 手势游戏 M0（2026-09-14）

### 阶段 1：基线复现与存档（分支 `feat/m0-infra`）

本 worktree（`D:\vibe coding_worktree\2190\lab_ex4_integrated`）开始时没有 Run 目录
（被 `.gitignore` 排除），先用新写的 `tools/new_worktree_runs.ps1` 从主 worktree 复制
骨架并同步登记，再跑 `pwsh -NoProfile -File tools/build_td.ps1`（syn 1m44s + phy 3m30s，
一次通过、0 违例）复现基线：

| 指标                          | 本次实测（2026-09-14） | 2026-09-13 复现值 | README §11.1 |
| --------------------------- | --------------- | -------------- | ------------ |
| slices                      | **13214（62.28%）** | 13214（62.28%）  | 一致           |
| LUT6 / 触发器                  | 10809 / 14256   | 10809 / 14256  | 一致           |
| 分布式 RAM（dram lut / shifter） | 296 / 112       | —              | 一致           |
| ERAM / DSP                  | 70（64.81%）/ 8  | 70 / 8         | 一致           |
| feedthrough                 | 6767            | 6767           | 一致           |
| final Setup WNS             | **+820 ps**     | +820 ps        | 一致           |
| final Hold WNS              | +20 ps          | +20 ps         | 一致           |

最紧路径与上次同一条：`u_hdmi_mixer/S_x_2d_reg[2]` → `u_hdmi_mixer/O_hdmi_data_reg[8]`，
15 级逻辑、cell 42% / net 58%。TD 的布局布线是确定性的，这次逐项复现正是证据。

回退镜像（本地、被 `.gitignore` 排除）与校验和：

- `tmp/m0-baseline/camera_to_dsi_display.bit`（1789547 B）
  SHA256 `8A0C36C6F2CCC672A1BF16855ED42FBE3A48E50A608215B6352546086DB2CE1A`
- `tmp/m0-baseline/camera_to_dsi_display_compress.bit`（1478281 B）
  SHA256 `DCC307E91D70CB6F68F2C7C77A5AA15500C69DC7E209BC1E1538DB7FE0C8C581`
- 同目录另存 `camera_to_dsi_display_phy.ts` / `_phy.area` / `_gate.area` 作为这次构建的原始证据。
- git tag：`m0-baseline-13214`。

**操作坑（写脚本时踩到）**：在交互式终端（PTY）里跑 `td_commands_prompt.exe`，流程
跑完后 TD 会停在 `td >` 提示符不退出，`tools/build_td.ps1` 的 `Start-Process -Wait`
就会一直等；此时给终端发一行 `exit` 即可让流程收尾并打印汇总。后台/重定向方式运行时
stdin 是 EOF，没这个问题。

### 阶段 2：3x3 窗口生成器拆分（重构，等价性）

`edge_detect_96.v` 拆成两个模块，**端口、延迟、输出格式逐拍不变**（`isp_top` 的例化
一个字都没改）：

- 新增 `user_source/hdl_source/isp/edge_win_3x3_96.v`：灰度（`R/4+G/2+B/4`）→ 逐像素
  `[1 2 1]/4` 平滑 → 3 块 48bit×320 ERAM 行轮转 → 6 列×3 行窗口 + 与之对齐的
  `O_x/O_y/O_valid/O_user/O_last`；1 拍延迟。
- `edge_detect_96.v` 只留 Sobel 级：消费窗口 + `I_thresh` + `EDGE_GAIN_SHIFT`，输出
  与拆分前一致（总延迟仍是 2 拍，输出仍是列 4k-1..4k+2）。
- **等价性论证**（逐拍映射）：`gray0..3`、`S_sm0..3`、`S_win_cur`、三块 `eram_spram`
  实例、`mid_r/top_r` 的相位选择、以及原来第一个 `always` 块里的每一个赋值
  （`x_grp/y_pos/row_phase/row_phase_d1/gray_h1,h2/sm_h1,h2/cur_r/x_r/y_r/valid_d1/...`）
  都按原表达式照搬，只是搬到了新模块的端口上；Sobel 级只把 `top_r/mid_r/cur_r/x_r/y_r/valid_d1`
  换成了对应端口名，没有动任何表达式与位宽。

层次面积表（`syn_1/camera_to_dsi_display_rtl.area` 与 `phy_1/*_phy.area`）确认 ERAM
归属正确：`u_edge_win_3x3_96` 下挂 `u_line_mem0/1/2` 三块 `eram_spram`（每块 2 个
ERAM20K，合计 6 块），`u_edge_detect_96` 只剩纯逻辑（phy 级 `u_edge_win_3x3_96`
119 LUT / 132 FF，`u_edge_detect_96` 合计 397 LUT / 174 FF）。

重构后完整构建（2026-09-14 19:23 起，一次通过，0 违例）：

| 指标                | 基线（tag `m0-baseline-13214`） | 重构后      | 变化    |
| ----------------- | ------------------------- | -------- | ----- |
| slices            | 13214（62.28%）             | 13217（62.30%） | +3    |
| LUT6 / 触发器        | 10809 / 14256             | 10825 / 14270 | +16 / +14 |
| ERAM / DSP        | 70 / 8                    | 70 / 8   | 0 / 0 |
| feedthrough       | 6767                      | 6788     | +21   |
| final Setup WNS   | +820 ps                   | **+621 ps** | −199 ps |
| final Hold WNS    | +20 ps                    | +20 ps   | 0     |

WNS 从 +820 ps 掉到 +621 ps 不是逻辑变多（只 +16 LUT），而是**最紧路径换了地方**：
基线是 `u_hdmi_mixer/S_x_2d_reg[2] → O_hdmi_data_reg[8]`（15 级、net 58%），这次是
`u_hdmi_tx/.../S_load_en_1d_reg → S_oddr_data_reg[0]`（0 级逻辑、net 89%，TMDS 串行域）。
层次变了之后 TD 的落点跟着变，这在 README 第 9 节记过是常态；仍高于 M0 门禁的
+300 ps。

**边缘质量证据按方案 c（不做逐像素对比）**：拆分是纯结构搬移 + 上表 + 层次面积表，
再加上板后的 `DBG:` 计数器 A/B（同一固定文字目标、同光照、固定曝光，各采 10 行取中
位数，要求 `N/B/C` 相对差 ≤1%、`M/L` 无数量级偏差）。上板结论由用户回填到本节；
README 第 9 节那条"整幅边缘图数值对比"欠账据此改写成"降级为计数器级对比"。

### 阶段 3：四个插座 + 模式框架 + 在线调参（新增功能）

新增 9 个模块（都在 M0 里冻结了接口，后续里程碑只填内容、不再改插座）：

| 模块 | 位置 | 作用 |
|---|---|---|
| `isp/recog_top.v` | CSI 域 | VIDEO_TAP 消费者：tap 每帧字数监视 + 掩码统计 + CTRL_SYNC 上行端点 |
| `isp/mask_stats.v` | CSI 域 | 通用二值掩码统计（像素数 / 包围盒 / Σ列Σ行），掩码源由调用方 mux |
| `isp/ctrl_sync.v` | 跨域 | CTRL_SYNC 的单字传输（toggle 握手 + 两级同步），上下行各一个实例 |
| `game/game_top.v` | 像素域 | RENDER_SLOT：DDR 读回与 OSD 之间的游戏层（M0 为直通空壳 + 每帧测试字） |
| `key_event.v` | 像素域 | 20 ms 消抖 + 1 s 长按的按键事件（KEY1 / KEY4 各一个实例） |
| `param_ctrl.v` | 像素域 | PARAM_BUS 寄存器文件 + 写仲裁（UART > KEY4 长按 > KEY4 短按 > KEY1 > 拨码）+ LED |
| `mode_sync.v` | 跨域 | 模式寄存器 → CSI 域的**相机帧首提交**（消撕裂），提交后回执 |
| `uart_rx.v` / `uart_cmd.v` | 像素域 | 115200-8-N-1 接收 + ASCII 命令 `W <addr> <data>`（只写不回显） |

集成改动：`isp_top` 增加 `I_edge_th`（运行时门限）与 tap/CTRL_SYNC 端口；顶层端口扩到
`I_button[3:0]` + `I_switch[3:0]` + `I_uart_rx` + `O_led[3:0]` + `O_buzzer`；
`alg_switch` 被 `key_event + param_ctrl + mode_sync` 取代（KEY1 也走模式寄存器，于是
README 第 5 节记的"切换瞬间撕裂"从设计上消失）；`hdmi_mixer` 的状态字扩成三态
RAW / EDGE / GES；`debug_uart_logger` 追加 8 个字段（K/S/P/Q/R/U/X/Y，行长 96 → 152
字节，115200 下约 13.2 ms）。

构建结果（2026-09-14 19:38 起，一次通过、0 违例）：

| 指标              | 基线      | 阶段 2 重构后 | **M0（阶段 3）** | 变化 vs 基线 |
| --------------- | ------- | --------- | ------------ | -------- |
| slices          | 13214（62.28%） | 13217     | **13693（64.54%）** | +479     |
| LUT6 / 触发器      | 10809 / 14256 | 10825 / 14270 | **11351 / 15094** | +542 / +838 |
| ERAM / DSP      | 70 / 8  | 70 / 8    | **70 / 8**   | 0 / 0    |
| feedthrough     | 6767    | 6788      | **7036**     | +269     |
| final Setup WNS | +820 ps | +621 ps   | **+589 ps**  | −231 ps  |
| final Hold WNS  | +20 ps  | +20 ps    | +20 ps       | 0        |

gate 阶段（综合后、布局前）：registers 14530 → 15094（+564）、luts 11151 → 11686（+535）、
RAMs 70（未变）、DSPs 8（未变）——**没有新增 ERAM**，掩码统计器与四个插座纯逻辑实现。

三个踩坑（都写进注释了）：

1. **prj 的登记格式**：`.v` 必须登记在 `<Verilog>` 段内、且条目要带
   `BelongTo="design_1"` + `CompileOrder`。插到 `</Source_Files>` 之前会落到
   `<IP_FILE>` 段外（`PRJ-8641 ERROR: XML tag File is invalid`）；只写
   UsedInSyn/UsedInP&R 两个 Attr 则报 `PRJ-8640 ... failed because of previous
   error(s)`，且不给具体原因——最后是用只做 `open_project` 的探针脚本（`tmp/` 下，
   秒级）逐个变体试出来的。
2. `S_alg_status_hdmi_3d` 在旧代码里除了 OSD 还有一处"模式变化就清 video-nonzero
   标志"的用法，删信号时要一起改（TD 报 `HDL-8007 '...' is not declared`）。
3. `param_ctrl` 里 `S_sw_seen` 一度在两个 always 块里都赋值（复位 + 写入），TD 报
   `HDL-8007 net 'S_sw_seen[3]' is constantly driven from multiple places`——寄存器的
   复位只能出现在驱动它的那一个块里。

**M0 待烧录镜像**（2026-09-14 19:43 生成）：

- `td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`（1789547 B）
  SHA256 `4B22F4901CFFD523C186D605B8198BDDAF3EAE7458DA34102865571CC8A3E4A4`
- 回退镜像仍可用：`tmp/m0-baseline/camera_to_dsi_display.bit`（见阶段 1 的 SHA256），
  git tag `m0-baseline-13214`

上板自检清单见 README 第 12.4 节（基础四项 + 8 个新字段的期望值 + 拨码/串口/KEY4 三项
在线调参）；本节的上板结论待用户回填。

### 阶段 4：KEY1 切到 EDGE 但画面不变——提交字位序取反（2026-09-14 上板发现并修复）

**现象**：按 KEY1 后右上角字样变成 `EDGE`，但画面仍是 RAW。

**根因**：模式提交字是 `{display_mode[3:0], edge_th_sel[3:0]}`（display_mode 在高 4 位），
而顶层消费侧写成按 `bit0` 取算法位、按 `bit7:4` 取门限档位——**两段正好取反**：
alg mux 拿到的是"门限档位的最低位"，默认恒 0，所以无论怎么按都停在 RAW；OSD 用的是
像素域的**请求值** `display_mode`，所以字样照常翻转。同一个错误也让"生效门限"取错
（`S` 字段会跟着 display_mode 走）。

**修法**：

- 顶层引入具名线网 `S_committed_display = S_mode_committed[7:4]`、
  `S_committed_th_sel = S_mode_committed[3:0]`，所有消费者（alg mux、生效门限、
  DBG 的 S 字段）改用它们，不再手写下标；
- `mode_sync.v` 头注释里把布局写死（哪一段在哪几位、谁该取哪几位）；
- 顺手加固：**OSD 状态字与 T 位图 bit3 改用已提交的 display_mode**（不是请求值），
  这样"右上角字样"永远等于屏幕上真正在放的那一路——以后即使提交通路出问题，也会
  表现为"字样不跟着按键变"，而不是这次这种"字样变、画面不变"的误导。

**这个 bug 只有上板才看得见**：`U`/`X`/`Y` 那些自检字段全是对的信号（它们不经过
模式字），构建、时序、资源也都正常。教训：跨域提交这种"两边各取一半"的地方，一定
要用具名线网拆位并在模块头注明布局，别在两处各写一遍下标。

构建（2026-09-14 20:03，一次通过、0 违例）：slices **13678（64.47%）**、LUT6 11355、
ERAM 70 / DSP 8（未变）、feedthrough 7021、final Setup WNS **+654 ps**、Hold +20 ps。

**修复后的镜像**：

- `td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`（1789547 B）
  SHA256 `074403707B7C5508705F0565F77AD401C821DF953A2D634D5A96C1BADA209400`
  （上面阶段 3 记的 `4B22F490…` 那版有同一个 bug，别再用）

### 阶段 5：参数实验与 RTL 瘦身（2026-09-14）

M0 初版实测 +546 LUT6、feedthrough +254、WNS 从 +820 掉到 +654 ps，而规划里 M0 的
预算只写了 +0~100 LUT6。这一轮做了三件事：先记账，再用减法把能省的省回来，最后用
布局参数把落点和 feedthrough 拉回。

**① RTL 减法（不改变任何对外行为）**

| 改动 | 省下 |
|---|---|
| `key_event` 加 `HAS_LONG` 参数，KEY1 实例不再生成 1 s 长按计数器与比较器 | 21 LUT / 29 FF（该实例 39→18 LUT、55→26 FF） |
| CSI→像素域的 4 个观测值（tap/掩码/包围盒）从"逐位两级同步"改成"每帧 toggle + 整包捕获" | 约 60 FF、若干跨区走线（`recog_top` 167→155 FF、logger 83→76 FF） |
| 观测字段位宽按实际取值收窄（tap 12 位、bbox_x 14 位、bbox_y 12 位，不再一律 16 位） | 十余 FF |
| LED 心跳/事件闪烁从 2 个 25 位分频计数器改成"显示帧计数派生" | 41 FF（`param_ctrl` 93→52 FF） |

**② 修掉一条被掩盖的 0.268 ns 路径（这才是初版 WNS 掉的真正原因之一）**

初版把 logger 行模板从 96 字节加长到 152 字节后，24 MHz 的曝光值 `A`/`G` 变成
`u_ae_set/r_ae_reg → logger 模板组合逻辑 → S_tx_byte` 这样一条 **6 级组合**的长路径，
卡在 SDC 里原有的 `set_max_delay -datapath_only 5.000 -from pll_clk_24m -to HDMI_PIXEL_CLK`
上，slack 只剩 **0.268 ns**，成了全设计最差 setup，把真正的片内最差路径盖住了。
修法：在顶层把 `S_ae`/`S_ag` 先在像素域打一拍再送 logger，那条跨域路径退回 FF→FF。

**顺带纠正一条 SDC 认知（重要，别再踩）**：我一开始给新加的 CSI↔像素域通路也写了
`set_max_delay -datapath_only 5.000`，实测**TD 直接忽略**——报告
`camera_to_dsi_display_exception.timing` 里这两条被标成 `Set Max Delay (Ignored)`，
把 5.000 改成 15.000 后**所有时序数字一个都没变**。原因是这两个时钟在 SDC 开头就是
两个异步组，组间路径本来就被切断。也就是说：**CSI 域 ↔ 像素域之间的时序 TD 根本不查**，
那两条约束现在只起"记录意图"的作用（万一以后取消异步组就立刻生效），真正的保障只能是
握手设计本身（toggle 两级同步 + 数据先稳定后整包捕获）。而 24m↔像素域虽然也"异步"，
却在**同一个组**里，所以照常按普通路径算——那类路径必须靠打拍/RTL 去满足。

**③ 布局参数实验（目标：压 feedthrough、找回时序余量）**

每次只跑布局布线（`-Stage phy`，syn 的网表不变），参数写在 `phy_1/settings.cfg` 的
`set phyWildParams {...}` 里：

| 实验 | place 参数 | final Setup WNS | feedthrough | LUT6 | slices |
|---|---|---|---|---|---|
| E1′ | `opt_timing high`（原参数） | +856 ps | 6964 | 11222 | 13527 |
| E2 | + `effort high` | +849 ps | 7059 | 11192 | 13525 |
| E3 | + `hfn_opt_effort high` | +481 ps | 6973 | 11210 | 13528 |
| **E4** | **+ `max_fanout 250`** | **+1084 ps** | **6927** | 11197 | 13511 |
| E5 | + `max_fanout 120` | +420 ps | 6935 | 11224 | 13541 |
| E6 | E4 + `route effort high` | +1084 ps（与 E4 完全相同 → 该参数无效果） | 6927 | 11197 | 13511 |

结论：**`set phyWildParams {place opt_timing high place max_fanout 250}` 是最优组合**
（默认 `max_fanout 999999` 等于不限；限到 250 让 TD 拆开高扇出网络，长线变短，WNS 一次
涨 228 ps）。`effort high` 和 `hfn_opt_effort high` 都是"更努力但落点更差"，`max_fanout`
再往下压（120）反而把 TMDS 串行域压到 0.420 ns，属于过头。

**④ feedthrough 的账要记清楚**

基线（M0 之前）就已经是 **6767**——它主要来自既有设计的长线（ISP 的 96 位通路、DDR 的
128 位通路、TMDS 输出到 pad 环），不是 M0 加的。M0 初版把它推到 7021（+254），这一轮
瘦身 + 参数实验收回到 **6927**（+160）。也就是说：**参数只能在 ±2% 里挪，想让 feedthrough
再明显下降，必须动既有的长线布局（换位宽/换流水线/改 I/O），那是独立于 M0 的课题。**

**⑤ 最终结果（2026-09-14 23:51，一次通过、0 违例）**

| 指标 | 基线 `m0-baseline-13214` | M0 初版 | **M0 优化后** | 净变化 vs 基线 |
|---|---|---|---|---|
| slices | 13214（62.28%） | 13678（64.47%） | **13511（63.68%）** | +297 |
| LUT6 | 10809 | 11355 | **11197** | +388 |
| 触发器 | 14256 | 14767 | **14663** | +407 |
| feedthrough | 6767 | 7021 | **6927** | +160 |
| ERAM / DSP | 70 / 8 | 70 / 8 | **70 / 8** | 0 / 0 |
| final Setup WNS | +820 ps | +654 ps | **+1084 ps** | **+264 ps** |
| final Hold WNS | +20 ps | +20 ps | +20 ps | 0 |

最紧路径回到熟悉的那条：`u_hdmi_mixer/sub2 → O_hdmi_data_reg[21]`（17 级、cell 46% /
net 54%），说明报告的"地形"恢复正常，不再被 CDC 约束口径干扰。

镜像：`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`（1789547 B）
SHA256 `C090D90A5BD164C81154A8B85A963032AEA6E11BD7AC38CC12B4CC4E692F0789`

**记账结论**：M0 的真实成本是 **+388 LUT6 / +297 slices / +407 FF / +160 feedthrough**，
规划里"+0~100 LUT6"低估了——当时只算了"重构 + 插座"，把模式寄存器、在线调参、UART
收发、参数寄存器文件、KEY4 长按、LED、8 个 DBG 字段都漏了。按 §2.5.3 的账本，这部分
从总预算里扣掉即可；到 85% 仍有约 3300 LUT6 余量。

### 阶段 6：观测字段恒 0——tuser 被错误地闸在 valid 里（2026-09-15 上板发现并修复）

**现象**（用户上板抓的一行行 `DBG:`）：`F/A/G/T/N/B/C/M/L/D/E/W/V/K/S/X/Y` 全部正常，
唯独 `U=P=Q=R=0000`。CTRL_SYNC 往返（`X/Y`）与模式提交（`K/S`）都对，说明 logger 的
字段机制和跨域通路都没问题，问题出在 VIDEO_TAP 那一包。

**根因**：`awb.v` 里 tuser 是**不带延迟直通**的（`assign O_tuser = I_tuser;`），而 valid
是流水后的、并且行间有空隙——同一个文件里 `assign O_tlast = (valid_d1==0)&&(valid_d2==1)`
就是靠 valid 的空隙检测出"每个行首"的。所以 tuser 脉冲经常落在 valid=0 的拍上。而我在
`recog_top` 里把三处帧锁存**都闸在了 tvalid 上**：

- toggle 写成 `I_edge_tvalid && I_edge_tuser` → 脉冲被吞 → toggle 不翻转 → 像素域的
  "整包捕获"从不触发；
- tap 写成 `if(I_raw_tvalid) … if(I_raw_tuser)` → 计数与锁存都不发生；
- `mask_stats` 整块写成 `else if(I_valid)` → 帧首锁存与清零都不发生。

三处叠加，`U/P/Q/R` 就恒为 0；而 `X/Y` 走 ctrl_sync（不经过这个闸门）所以照常正常——
这正是把线索指向"闸门"而不是"数据"的关键。

**修法**：帧锁存一律与 valid 解耦——toggle 只看 `tuser`；tap 的**计数按 valid、锁存按
tuser**；`mask_stats` 的帧首分支移出 `if(I_valid)`（帧首那拍若同时有有效像素，仍按第 0 组
累加，用 `S_new` 选择初值）。

**教训**：这是典型"只有上板才暴露"的问题——构建、时序、资源全正常，`U=0x384` 的理论值也
算得出来，但没有真机数据就发现不了；而且它不影响画面，只让观测字段失效，很容易被忽略。
**新增任何帧级计数/锁存时，先把 tuser 与 valid 的相位关系确认清楚（见 README 第 12.4 节）。**

构建（2026-09-15 09:46，一次通过、0 违例）：slices **13481（63.54%）**、LUT6 11192、
feedthrough **6862**、ERAM 70 / DSP 8 不变、final Setup WNS **+876 ps**、Hold +20 ps。

镜像：`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`（1789547 B）
SHA256 `5CA1FEB8CC387FBB7D7C3D3761B6C965EFCA683B595890A3259952CA672803DE`
