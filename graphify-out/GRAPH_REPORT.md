# Graph Report - lab_ex4_integrated  (2026-10-28)

## Corpus Check
- 204 files · ~395,609 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 55 file(s) not represented in the graph (top: .xml 27, .tcl 4, .sdc 3)

## Summary
- 929 nodes · 935 edges · 108 communities (22 shown, 86 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Build Scope And Health Notes
- Source code was extracted structurally with AST. Markdown, IP parameter text, and image assets were linked with an in-session deterministic semantic pass covering headings, explicit links, code references, and named project concepts.
- The 8 PDF papers were intentionally skipped at the user's request; the repository's Markdown hardware references remain represented where available.
- No dangling endpoints, missing endpoints, or self-loops were found.
- The graph model collapsed 14,730 repeated same-endpoint instance edges into 935 unique post-build edges. The main source is repeated `AL_DFF_X` and `AL_MAP_LUT*` instances under the AWB divider hierarchy; architecture-level relationships remain usable, but instance multiplicity is not preserved.

## Community Hubs (Navigation)
- Changelog History
- SC500 Sensor Datasheet
- MIPI Acquisition Infrastructure
- Game And Logo Rendering
- PH1P FPGA Hardware
- Gesture Defect Backlog
- Edge And ISP Dataflow
- Competition Requirements
- Tang Dynasty CLI
- HX1P35A Datasheet
- DDR PHY Clocks
- Project Overview README
- Gesture Roadmap
- Gesture Game Interfaces
- Demosaic Pipeline
- HDMI Transmitter Path
- Debug UART Protocol
- Resource Acceptance Plan
- AWB Arithmetic Primitives
- MCU User Interface FIFO
- Sensor Configuration
- Soft FIFO Wrappers
- MCU And QSPI Bridge
- DDR Controller Top
- AWB Signal Delay
- AWB Processing
- UART Debug Reader
- DDR Command Execution
- MIPI Error Detection
- CSI Packet Parsing
- AWB Delay Memory
- DDR PHY Simulation
- RAW To RGB Conversion
- DDR Parameter Files
- Hand Row Band Tracking
- ISP AXI Stream Adapter
- Frame AXI Stream Adapter
- Algorithm Selection
- Auto White Balance
- Image Correction
- Black Level Correction
- ISP CSI Unpacker
- Demosaic Memory Parameters
- Demosaic Memory Ports
- Demosaic Memory Model
- Demosaic Memory Port Map
- ISP RAW Unpacker
- DDR Memory Parameters
- DDR2 DRAM Initialization
- DDR FIFO Synchronization
- DDR PHY Configuration ROM
- DDR PHY APB Bridge
- DDR PHY Bank Configuration
- DDR PHY Byte Lanes
- DDR PHY Command Decode
- DDR PHY DCU Control
- DDR PHY Fast Initialization
- DDR PHY Delay Calibration
- DDR PHY Read Phase
- DDR PHY Write Phase
- DDR PHY Wrapper
- RAW10 Unpacker
- ISP Beta CSI Unpacker
- ISP Beta RAW Unpacker
- Video Frame Cropping
- AWB Delay Parameters
- AWB Delay Ports
- MCU IP Parameters
- MCU IP Ports
- PLL IP Parameters
- PLL IP Ports
- FIFO 128 Parameters
- FIFO 128 Ports
- FIFO 155 Parameters
- FIFO 155 Ports
- FIFO 40 Parameters
- FIFO 40 Ports

## God Nodes (most connected - your core abstractions)
1. `design_top_wrapper` - 24 edges
2. `recog_top` - 20 edges
3. `ISP Pipeline` - 15 edges
4. `isp_top` - 13 edges
5. `MIPI Camera Capture` - 11 edges
6. `hdmi_mixer` - 10 edges
7. `FPGA Resource Budget` - 10 edges
8. `game_fruit` - 9 edges
9. `HDMI Output` - 9 edges
10. `game_top` - 8 edges

## Surprising Connections (you probably didn't know these)
- `hdmi_tx` --instantiates--> `audio_arc_calculate`  [EXTRACTED]
  user_source/hdl_source/hdmi_tx.v → user_source/hdl_source/audio_arc_calculate.v
- `design_top_wrapper` --instantiates--> `game_top`  [EXTRACTED]
  user_source/hdl_source/design_top_wrapper.v → user_source/hdl_source/game/game_top.v
- `design_top_wrapper` --instantiates--> `hdmi_mixer`  [EXTRACTED]
  user_source/hdl_source/design_top_wrapper.v → user_source/hdl_source/hdmi_mixer.v
- `design_top_wrapper` --instantiates--> `hdmi_tx`  [EXTRACTED]
  user_source/hdl_source/design_top_wrapper.v → user_source/hdl_source/hdmi_tx.v
- `design_top_wrapper` --instantiates--> `isp_top`  [EXTRACTED]
  user_source/hdl_source/design_top_wrapper.v → user_source/hdl_source/isp/isp_top.v

## Import Cycles
- None detected.

## Communities (108 total, 86 thin omitted)

### Community 0 - "Changelog History"
Cohesion: 0.01
Nodes (185): 1. 三条前提（照做，不做变通）, 幅度对比（1024x600 + 旧灰度公式的历史数据）, 11.1.1 资源优化第一版：Logo ROM 搬 ERAM（`feat/resource-opt` @ `0aa5c25`）, 11.1.2 资源优化第二版：精简调试/观测逻辑（第一批，2026-09-12）, 11.1.3 资源优化第三版：行缓存搬 ERAM（2026-09-12）, 11.1.4 时序余量：place 的 opt_timing 提到 high（2026-09-12）, 11.1.5 观测增强：FIFO 丢写与占用进 DBG 行（2026-09-12，`4b1ec22`）, ⑤ 的读数口径（档 13/14 借 P/Q；R 保持 M1 的包围盒 y） (+177 more)

### Community 1 - "SC500 Sensor Datasheet"
Cohesion: 0.04
Nodes (48): 第 1 页（封面）, 第 10 页（1.3 引脚描述（CSP）续；图 1-5 封装引脚图）, 第 11 页（1.4 芯片初始化；1.4.1 上电时序）, 第 12 页（1.4.2 下电时序）, 第 13 页（1.4.3 睡眠模式；1.4.4 复位模式；1.5 配置接口）, 第 14 页（1.5 配置接口；I2C 时序）, 第 15 页（1.5 I2C 时序参数；1.6 Sensor ID；1.7 数据接口）, 第 16 页（1.7.1 MIPI；MIPI 接口及数据包） (+40 more)

### Community 2 - "MIPI Acquisition Infrastructure"
Cohesion: 0.04
Nodes (17): debug_uart_logger, design_top_wrapper, ctrl_sync, key_event, mipi_dphy_rx_ph1p_mipiio_wrapper, mode_sync, param_ctrl, ddr2 (+9 more)

### Community 3 - "Game And Logo Rendering"
Cohesion: 0.04
Nodes (15): anlogic_logo_rom, game_fruit, game_gesture, game_input, game_param, game_render, game_sprite_rom, game_top (+7 more)

### Community 4 - "PH1P FPGA Hardware"
Cohesion: 0.04
Nodes (40): 1 简介, 1.1 SALPHOENIX®1P（以下简称PH1P）系列器件特性, 1.2 PH1P器件介绍, 2.1 可编程逻辑资源, 2.10 电压温度检测模块, 2.11 External Memory Interface, 2.12 Integrated Memory Interface, 2.13 MIPI DPHY (+32 more)

### Community 5 - "Gesture Defect Backlog"
Cohesion: 0.05
Nodes (35): 0. 一句话总结, 1. 优先级总表, 手势识别待修复问题（2026-10-23）, 2. P0：不解决就无法验收, 3. P1：影响调试效率和稳定性, 4. P2：已解决或已闭环, 5. 建议的逐项解决顺序, 6. 上板验收命令与判读 (+27 more)

### Community 6 - "Edge And ISP Dataflow"
Cohesion: 0.05
Nodes (8): eram_spram, data128_96, data_96bit_to_128bit, edge_detect_96, edge_win_3x3_96, isp_top, mask_stats, recog_top

### Community 7 - "Competition Requirements"
Cohesion: 0.05
Nodes (33): HX1P35A 开发板, 涉及 IP 核与参考设计, 赛题解析二（安路赛道-选题二）整理, 赛题注意事项, 三、赛题解析, 选题优势, 基础要求实现思路, 扩展要求实现思路 (+25 more)

### Community 8 - "Tang Dynasty CLI"
Cohesion: 0.06
Nodes (30): 1. 用途, 10. 本次实际验证结果, 2. 环境信息, 2.1 工具安装路径, 2.2 相关可执行文件, 2.3 工程目录, 3.1 TD CMD 窗口中执行 Tcl 脚本, 3.2 批处理文件执行 (+22 more)

### Community 9 - "HX1P35A Datasheet"
Cohesion: 0.07
Nodes (29): 第 10 页（原 PDF 第 10 页）, 第 11 页（原 PDF 第 11 页）, 第 12 页（原 PDF 第 12 页）, 第 13 页（原 PDF 第 13 页）, 第 14 页（原 PDF 第 14 页）, 第 15 页（原 PDF 第 15 页）, 第 16 页（原 PDF 第 16 页）, 第 17 页（原 PDF 第 17 页） (+21 more)

### Community 10 - "DDR PHY Clocks"
Cohesion: 0.07
Nodes (12): ph1p_ddrphy_clk_top, ph1p_ddrphy_pll0, ph1p_ddrphy_pll1, ph1p_ddrphy_sync_rst_gen, ph1p_ddrphy_dcu_wrapper, ph1p_ddrphy_fast_init_wrapper, ph1p_ddrphy_init, ph1p_ddrphy_mdl_cal_wrapper (+4 more)

### Community 11 - "Project Overview README"
Cohesion: 0.07
Nodes (27): 0. AI 会话入口（新会话先读）, 1. 工程概览, 10. 分辨率与时钟配置（720P）, 11. 资源占用与优化, 11.1 当前基线, 11.2 优化方向, 11.3 资源判读, 11.4 余量策略与门禁 (+19 more)

### Community 12 - "Gesture Roadmap"
Cohesion: 0.08
Nodes (24): 0. 总体架构, 1. 里程碑总览（主线）, 2. 三人分工, 2.5.1 文件所有权, 2.5.2 四个插座（编译期固定，接口冻结）, 2.5 并行协作与资源账本（2026-09-13 新增）, 2.5.3 硬件资源账本, 2.5.4 集成流程 (+16 more)

### Community 13 - "Gesture Game Interfaces"
Cohesion: 0.11
Nodes (18): B 段参数, CTRL_SYNC, 手势游戏接口与验收, 数据流, 插座, 跨域规则, 系统参数地址, 串口命令 (+10 more)

### Community 14 - "Demosaic Pipeline"
Cohesion: 0.12
Nodes (7): bilinear_interpolation, blk_mem_gen_zhenghe, ram_d32970204f32, demosaic, mipi_to_raw_converter, raw_matrix_3x3_buffer, zhenghe

### Community 15 - "HDMI Transmitter Path"
Cohesion: 0.13
Nodes (6): audio_arc_calculate, hdmi_phy_wrapper, hdmi_tx, I2S_receiver, key_remove_shakes, lane_lvds_10_1

### Community 16 - "Debug UART Protocol"
Cohesion: 0.13
Nodes (13): DBG 串口调试字段, 连接与输出, 字段表, 字段复用, 采样规则, 修改清单, T 位图, CTRL_SYNC Interface (+5 more)

### Community 17 - "Resource Acceptance Plan"
Cohesion: 0.17
Nodes (11): 资源预算与验收, 当前基线, 构建门禁, 构建与产物, 数字来源, 布局参数, 优化优先级, 记录格式 (+3 more)

### Community 19 - "MCU User Interface FIFO"
Cohesion: 0.20
Nodes (8): mc_to_user_interface, ram_infer_f58e8b3e1f3d, read_a, read_b, write_a, write_b, soft_fifo_al_f58e8b3e1f3d, w155_d512_fifo

### Community 20 - "Sensor Configuration"
Cohesion: 0.20
Nodes (5): SC500GainTbl, uicfgcs500, uics500reg, uics500regAE, uii2c

### Community 21 - "Soft FIFO Wrappers"
Cohesion: 0.25
Nodes (7): ram_infer_2758cdf81c93, read_a, read_b, write_a, write_b, soft_fifo_al_2758cdf81c93, w40_d512_fifo

### Community 22 - "MCU And QSPI Bridge"
Cohesion: 0.25
Nodes (3): ps_wrapper, MCU_f9f874759a41, MCU

## Knowledge Gaps
- **518 isolated node(s):** `alg_switch`, `auto_white_balance`, `image_correction`, `BLC`, `csi_unpacket_2lane` (+513 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 774 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **86 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MIPI Camera Capture` connect `Resource Acceptance Plan` to `Changelog History`, `SC500 Sensor Datasheet`, `PH1P FPGA Hardware`, `Competition Requirements`, `Tang Dynasty CLI`, `HX1P35A Datasheet`, `Project Overview README`, `Gesture Roadmap`, `Gesture Game Interfaces`, `Debug UART Protocol`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **What connects `alg_switch`, `auto_white_balance`, `image_correction` to the rest of the system?**
  _518 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Changelog History` be split into smaller, more focused modules?**
  _Cohesion score 0.010752688172043012 - nodes in this community are weakly interconnected._
- **Why does `design_top_wrapper` connect `MIPI Acquisition Infrastructure` to `Game And Logo Rendering`, `Edge And ISP Dataflow`, `DDR PHY Clocks`, `HDMI Transmitter Path`, `MCU User Interface FIFO`, `Sensor Configuration`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Should `SC500 Sensor Datasheet` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._
- **Why does `ISP Pipeline` connect `Gesture Defect Backlog` to `Changelog History`, `PH1P FPGA Hardware`, `Competition Requirements`, `Tang Dynasty CLI`, `Project Overview README`, `Gesture Roadmap`, `Gesture Game Interfaces`, `Debug UART Protocol`, `Resource Acceptance Plan`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Should `MIPI Acquisition Infrastructure` be split into smaller, more focused modules?**
  _Cohesion score 0.04343971631205674 - nodes in this community are weakly interconnected._
