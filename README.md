# anlogic_competition

FPGA 竞赛安路赛道赛题二工程：基于 PH1P35/HX1P35A 开发板，把 MIPI 摄像头采集、
ISP、边缘检测、OSD 叠加和 HDMI 显示整合到同一个 bitstream 中。

## 0. AI 会话入口（新会话先读）

如果你是新会话中的 AI，先不要直接改代码。先阅读 `参考资料/赛题解析二-整理.md`，
可以快速建立本项目的目标、当前工作方向。

以下是硬件参考资料：

1. `参考资料/新HX1P35A开发板手册-HDL版2604-文本.md`：开发板资源、按键、时钟、外设和约束。
2. `参考资料/SC500CS_数据手册_V1.8-整理.md`：摄像头寄存器、曝光/增益和图像配置。
3. `参考资料/DS1300_PH1P_Datasheet.md`：PH1P 器件和 DDR/外设接口资料。
4. `参考资料/TangDynasty_CLI编译流程.md`：TD 命令行综合、布局布线和 bitgen 流程。
5. 回到本 README 的第 1～12 节，理解当前数据流、按键、边缘基线和已知风险；要查历史改动、实测数字或上板结论时看 `docs/CHANGELOG.md`。
6. **当前开发计划在 `B-游戏引擎实现规划.md`**（v2.8：七步路线与门禁、`game/**` 五个模块与端口规格、B 段地址表 `0x80~0xBF`、资源账本 ≈840 LUT6 / 2 块 ERAM / 1 DSP、五个视觉开关的做法与踩点、§0.1 开工速查、§9 给 A/C 的需求单）——动手前先读它；接口细则以本 README 第 12 节为准。

`参考资料/` 中的 PDF、PPTX 是原始资料；上面的 md 文件是便于 AI 阅读的整理版。
如果 md 和原始资料存在冲突，以赛题原始文件和硬件手册为准，并在代码提交说明中
记录冲突点。

阅读完成后，AI 应明确以下工作方向：

- 当前目标是赛题二：在同一系统中完成 MIPI 采集、RAW/EDGE 实时切换、OSD、
  HDMI 显示和可观测的运行时日志。
- **边缘检测模块已基本完成**（见第 4 节）：全分辨率梯度 + 灰度输出，已上板确认
  细笔画效果良好、画面无异常。它的组内像素顺序、总延迟和输出对齐是下游
  `data_96bit_to_128bit` 的依赖，改动前先读第 4 节。
- **整条链路已从 1024x600 升级到 1280x720（720P），改造完成并已上板确认**（见第
  10 节）：摄像头寄存器表、PLL、HDMI 时序、ISP/边缘/OSD 参数和时序约束已一起改完，
  TD 综合与布局布线通过（当时 final Setup WNS +271 ps；最新数字见 11.1），上板实测画面、RAW/EDGE 切换、
  曝光按键和 OSD 全部合格。
- **资源优化已完成（2026-09-12，已合并进 `main`）**：slices 从 16957（79.93%）压到
  **13214（62.28%）**、final Setup WNS 从 +242 ps 提到 **+820 ps**（都 0 违例），
  Logo ROM 与边缘行缓存都搬进了 ERAM；做法与逐项实测见第 11 节和 11.1.1~11.1.5，
  余量规则见 11.4。
- **当前工作方向（2026-09-13 起）：开发手势操控游戏** —— 在已经稳定的 720P 采集 →
  ISP/边缘 → OSD → HDMI 链路上，用摄像头画面识别手势并驱动一个能在 HDMI 上玩的小游戏
  （手势是唯一游戏输入；KEY4 短按进/出模式、长按一键示教；KEY1~KEY3 保持基础功能）。**M0（模块重构 + 四个插座 + 模式框架 + 在线调参）已完成并合并进 `main`**（tag `m0-infra-done`），
  接口与地址表见第 12 节。**基线以 2026-09-23 实测的 `main` @ `f55ee2b` 为准：slices 13565 / 63.94%、final Setup WNS +930 ps**（§11.1，
  以后加功能都按它算余量）。下一步：A 线的 M1 融合掩码跟踪链路（识别支路直接填进 `isp/recog_top.v`，
  不动顶层与插座）；B 线按 `B-游戏引擎实现规划.md` 先做切水果（Pong 顺延）。
- 调整边缘参数时，用 `tools/read_debug_uart.ps1` 读 `DBG:` 日志做客观对比，不要只凭
  主观印象反复编译；“稳定性、可复现对比、赛题要求覆盖”仍然是底线。

工作时必须遵守：

- 先执行 `git status`，不要覆盖或提交会话外产生的未提交改动。
- `tmp/` 是本地临时诊断目录，不纳入提交；TD Run、bitstream、日志由 `.gitignore`
  排除。
- **新克隆 / 新 worktree 先跑 `pwsh -NoProfile -File tools/new_worktree_runs.ps1 -TdPath <TD 安装目录>` 铺好 Run 目录再构建**（Run 目录不在版本库里；**本机 TD 在 `D:\anlu`**，所以完整命令是 `-TdPath D:\anlu`；命令见第 6 节，四步上手见 `docs/手势游戏实现路线规划.md` §2.5.4）。
- 当前按键/开关：KEY1 切 RAW/EDGE、KEY2/KEY3 调曝光（基础功能，任何时候可用）；KEY4 短按进/出手势模式、长按 ≥1 s 一键示教；SW1~SW4 直接给边缘门限档位；串口在线调参见第 12.3 节。
- **任何 RTL / 约束改动后都要跑构建**（用户 2026-09-12 明确要求）：
  `pwsh -NoProfile -File tools/build_td.ps1 -TdPath D:\anlu` 一条命令走完综合 + 布局布线 +
  bitgen，末尾自动打印时序、资源占用和 bit 流路径；跑完要把 bitstream 路径与
  时序结果报告出来给用户烧录验证。只改文档不用跑。
- 没有用户明确指令时，不自动 push、合并 PR 或改写 Git 历史。

## 1. 工程概览

本工程整合了官方三个例程的功能：

- `lab_ex1_mipi_hdmi`：MIPI 采集 + HDMI 实时显示
- `lab_ex2_edge`：ISP 链路中的边缘检测
- `lab_ex3_osd`：HDMI 输出前的 OSD 叠加

整合版额外提供：

- KEY1 实时切换 RAW / EDGE 算法
- KEY2 / KEY3 调节摄像头曝光
- OSD 显示安路 Logo、动态文字、帧计数和当前算法状态
- 115200-8-N-1 UART 调试日志
- 边缘检测改为全分辨率梯度 + 灰度输出（见第 4 节），已上板验证
- 输出分辨率升级到 1280x720@60（见第 10 节），各级参数已同步，已上板确认

## 2. 系统数据流

```text
MIPI 摄像头
  -> MIPI D-PHY RX
  -> CSI / RAW10 解包
  -> ISP（demosaic -> AWB）
  -> 边缘检测（edge_detect_96）
  -> RAW / EDGE 算法选择 MUX
  -> DDR2 帧缓存
  -> HDMI 时序
  -> hdmi_mixer（Logo + 动态文字 + 帧计数 + 算法状态）
  -> hdmi_tx
  -> 显示器
```

RAW 路径和 EDGE 路径并行工作，MUX 在按键切换后选择其中一路送入 DDR。

## 3. 按键定义

| 板载按键 | 顶层信号          | 引脚  | 功能                        |
| ---- | ------------- | --- | ------------------------- |
| KEY1 | `I_button[1]` | D5  | RAW / EDGE 算法切换（0↔1）      |
| KEY2 | `I_button[0]` | A9  | 曝光目标值递减                   |
| KEY3 | `I_button[2]` | B9  | 曝光目标值递增                   |
| KEY4 | `I_button[3]` | C7  | 短按：游戏层开 / 关；长按（≥1 s）：一键示教 |

KEY1 / KEY4 都在 HDMI 像素域里做 20 ms 消抖（`key_event.v`），KEY4 的短按/长按分界是
1 s，长按只发一次事件、松手不再补短按。KEY2、KEY3 仍是 24 MHz 域里的短按调节
（`ae_set`，短按一次走一档，不支持长按连续调整），M0 没有改动这条路径。

**M0 起模式切换统一走模式寄存器**（`param_ctrl.v` → `mode_sync.v`），display_mode 与
边缘门限档位在**相机帧首**提交给 CSI 域，所以写入 DDR 的每一帧都是单一算法——第 5 节
原先记的"切换瞬间一帧撕裂"从设计上消失了；代价是 OSD 状态字最多比画面早一帧。

其余新外设（M0 登记，见 `user_source/constraints_source/pin.adc`）：

| 外设         | 顶层信号            | 引脚                  | M0 行为                                                  |
| ---------- | --------------- | ------------------- | ------------------------------------------------------ |
| 拨码 SW1~SW4 | `I_switch[3:0]` | A4 / B4 / E11 / D11 | 直接给"边缘门限档位"（TH = 16 + 4×档位，20 ms 消抖，变化即写寄存器 0x02）      |
| 4 个独立 LED  | `O_led[3:0]`    | D10 / E10 / C6 / D6 | {KEY4 事件闪 0.3 s, 心跳, game_mode, display_mode}（极性以实板为准） |
| 蜂鸣器        | `O_buzzer`      | C12                 | M0 恒为高（不响），低电平才响，碰撞音效留给 M4c                            |
| 串口接收       | `I_uart_rx`     | J1                  | 115200-8-N-1，命令见第 12 节                                 |

## 4. 边缘检测实现

`user_source/hdl_source/isp/edge_detect_96.v` 相对官方实现有三处结构改动（前两处
来自 `feat/edge-magnitude`，第三处来自 `feat/edge-luma`）。输入输出仍是
96 位 × 4 像素/拍，`O_tuser` / `O_tlast` / `O_tvalid` 与数据严格对齐，但本版总
延迟为 2 拍，且输出的 4 个像素对应列 4k-1..4k+2，因此整幅边缘图相对 RAW
**左移 1 像素**。

1. **全分辨率梯度**。官方实现先做 `grp_gray = (gray0+gray1+gray2+gray3)>>2`，
   把同拍 4 个像素平均成一个再做 Sobel，真正参与梯度运算的是宽度只有 1/4 的图
   （1024x600 下是 256×600，现在 720P 下是 320×720），
   结果再复制回 4 个像素。宽度小于 4 像素的竖线因此被 4 倍组平均压到阈值以下
   而完全消失。本版为每个像素单独算 Sobel（4 路并行）。
2. **输出梯度灰度而不是硬二值化**。`I_thresh` 只作噪声门限，门限以上保留灰阶：
   `显示灰度 = clamp((|gx|+|gy|) << EDGE_GAIN_SHIFT)`，干净阶跃边缘是
   `|gx|+|gy| = 4Δ`（Δ 是两侧的真实灰阶差）。**门限决定“多弱才看得见”，增益决定
   “多强才全白”**：TH=16 → Δ≥4 可见，TH=48 → Δ≥12 才可见；增益 0 → Δ≥64 饱和，
   增益 1 → Δ≥32 饱和。当前取 TH=16 + 增益 0。
   同时删掉了三点多数滤波，它会把细笔画产生的孤立边缘像素直接抹掉。
3. **灰度公式换成官方 720P 例程的 `R/4 + G/2 + B/4`**（最大 253，不回绕、不用除法）。
   旧公式 `(R+G+B)/3` 的加法在 8 位表达式里先回绕，把全图**绝对亮度**压到 0..85
   （R=G=B=128 只剩 42、255 只剩 84）。
   **但它并不压缩局部对比度**：旧公式是斜率恒为 1 的锯齿，段内相邻像素的差分原样
   保留（实测 Δ=8 时 232/248 个相邻位置保留），只在每 85 级跨段时冒出 ±85 的假跳变
   ——那会在平滑表面上产生成片假边缘（白块/弧线）。所以换公式的实际收益是
   “去掉回绕假边 + 绝对亮度正确 + 少一个除法”，**不能**据此把门限或增益按 3 倍去
   换算。这一点踩过坑：一度把 TH 放大到 48，上板后弱边缘整片消失、只剩强轮廓。

数值对比（组平均 vs 全分辨率的 Sobel 幅度表、旧公式那批假边的来源）见
[`docs/CHANGELOG.md`](docs/CHANGELOG.md)《边缘算法调参》。

当前配置（全分辨率 + 官方 luma 公式 + 增益 0 + 门限 16）**已上板确认（2026-09-12），效果优秀**：
弱边缘与印刷细节合格、旧公式那种回绕假边消失，这一版就是当前基线；bitstream 在
`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`。
上板 A/B 对比（组平均 + 增益 2 vs 全分辨率 + 增益 0）与历次调参见
[`docs/CHANGELOG.md`](docs/CHANGELOG.md)《边缘算法调参》。

行缓存改成**三块按行轮转的存储器**：每块 320×48 位（1024x600 时是 256×48，
行缓存按 `IMG_WIDTH/4` 自动跟着分辨率走），保存一行内 6 个平滑灰度
（对应列 4k-2..4k+3），每周期只写其中一块、只读另外两块，读写永不同址且读地址已
寄存。这是必需的——全分辨率下若沿用官方那种异步读写法，行缓存会落成触发器，直接
把器件 FF 资源耗尽（TD 报 `PHY-9002 Placer initialization failed`）。

**注意（2026-09-12 更正）**：上面写的"block RAM"当时并不成立——那三块行缓存虽然带
`(* ram_style = "block" *)` 属性，TD 仍把它们综合成了分布式 RAM（面积表里
`u_edge_detect_96` 的 `dram lut = 1152`、`eram = 0`），花了 1152 个 LUT。同一年的
`feat/resource-opt` 分支把它们改成显式例化 `PH1P_LOGIC_ERAM`（`eram_spram.v` 封装，
每块 2 个 ERAM20K，共 6 块），`dram lut` 归零、slices −1457（见 CHANGELOG《资源优化》第 3 节）。
读时序没变：地址 `x_grp` 当拍给出、数据下一拍有效，与原数组写法逐拍等价。

官方实现保留的已知限制：

- `data96_128` 的 128 位打包计数器不会被帧起始单独复位。

任何进一步的数值“修正”都必须保持 `O_tuser` / `O_tlast` 与数据对齐，
并用固定文字目标做对比后再替换（**M0 拍板：边缘质量按"方案 c 计数器级对比"**——同光照、固定曝光下 `DBG:` 的 `N/B/C` 相对差 ≤1%；逐像素对比需先补"抓一帧导出"通路，见 `docs/手势游戏实现路线规划.md` §3 M0），不能只比较“是否能检测到边缘”。

## 5. OSD 与画面状态

`hdmi_mixer.v` 负责在 HDMI 数据输出前叠加：

- 左上角：安路 Logo；
- 中部：动态文字和帧计数；
- 右上角：当前状态字 `RAW` / `EDGE` / `GES`（`GES` = 游戏层已打开，M0 只有状态字变化，
  画面仍是摄像头直通）。

状态文字位置由 `STATUS_OSD_X`、`STATUS_OSD_Y` 参数控制，字符由 `I_debug_status[1:0]`
选（bit0 = **已提交**的 display_mode，bit1 = game_mode）。M0 起切换在相机帧首提交，
所以画面本身不再有"半帧旧算法"的撕裂；状态字用的是提交值，**它永远等于屏幕上真正在
放的那一路**（2026-09-14 那次"字样变、画面不变"的位序 bug 就是靠这条约束避免复现）。

720P 下这几处坐标也调过：动态文字/帧计数 `DYN_OSD_X = 540`（1280 宽下水平居中），
右上角的 RAW/EDGE 状态字 `STATUS_OSD_X = 1100`，Logo 仍在左上角 160x160。

Logo 的 ROM 地址用移位加法 `((y<<7) + (y<<5)) + x`，**不要写回 `y * LOGO_W`**：
`LOGO_W = 160 = 128 + 32`，数值等价，但乘法会多占一个 DSP，而且那条路径曾是 75 MHz
像素域最紧的一条。来历见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)《资源优化》附录。

2026-09-12（分支 `feat/resource-opt`）：Logo 位图从"6387 条 case 的组合 ROM"换成
**ERAM（块 RAM）**。依据是综合报告 `syn_1/camera_to_dsi_display_rtl.area` 的层次
面积表：`u_anlogic_logo_rom` 占 38426 个门，是父模块 `hdmi_mixer`（38822 门）的
99%，技术映射后这些门就是 mixer 那 2633 个 LUT6 的绝大部分（同一张表里
`u_osd_char_lib` 只有 101 门）。换 ERAM 后这部分 LUT 全部还给逻辑，代价约 20 块
ERAM（25 位 × 16384 深；器件 108 块，原本已用 39 块）。改这个模块前必须知道：

- **读延迟 1 拍**：`anlogic_logo_rom.v` 现在直接例化 `PH1P_LOGIC_ERAM`
  （`MODE="SP"`、`REGMODE_A="OUTREG"`、`ocea=1`），地址第 N 拍给出、数据第 N+1
  拍有效。0 拍的组合读在块 RAM 上不被支持（TD 的 `apm_memory` 模型对此直接报
  错），所以不要把 `REGMODE_A` 改成 `NOREG`。
- **地址改成"预取"**：`hdmi_mixer.v` 里用 `S_x_1d/S_y_1d`（下一拍才成为
  `S_x_2d/S_y_2d`）算 Logo 地址，单独放在一个 `always` 块里；这样数据正好在
  `*_2d` 那一拍到达，与原来的组合 ROM 逐像素等价、整条链路总延迟不变。动预取级
  或 `*_d` 流水线时两处必须一起改。
- 位图数据在 `user_source/hdl_source/anlogic_logo_rom.dat`（TD 的 .dat 约定：
  一行一个单元、行序即地址序、25 位二进制高位在前，靠文件名在源码目录里找到，
  与 DDR PHY 的 `ddrphy_cfg_rom.txt` 同一套机制）。重新生成用
  `tools/logo_rom_case_to_dat.ps1`，脚本会穷举校验新旧行为逐地址一致。

**已上板确认（2026-09-12）**：1280x720 画面正常，Logo 位置与内容与改造前一致
（没有出现"整体右移 1 像素"，说明 1 拍读延迟 + `*_1d` 预取地址的相位假设成立；
也没有花屏/乱码，说明 `.dat` 初始化数据确实进了 bit 流）。

## 6. 编译与烧录

使用安路 TangDynasty 打开：

```text
td_project/camera_to_dsi_display.al
```

命令行编译时，TD 的安装目录**按机器给**（命令行工具与流程脚本都从它下面取），两个 Run 目录分别是：

```text
td_project/camera_to_dsi_display_Runs/syn_1
td_project/camera_to_dsi_display_Runs/phy_1
```

完整流程（`<TD>` 换成机器上的安装目录；**Tcl 只吃正斜杠，反斜杠会被当转义吃掉**）：

```bat
cd /d <你的 worktree>\td_project\camera_to_dsi_display_Runs\syn_1
<TD>\bin\td_commands_prompt.exe <TD>/scripts/DefaultFlow.tcl

cd /d ..\phy_1
<TD>\bin\td_commands_prompt.exe <TD>/scripts/DefaultFlow.tcl
```

**本机（2026-09-23 实测）TD 装在 `D:\anlu`**（Tang Dynasty Release_2026.1_SP2），
本机**没有** `D:\TangDynasty`：所以手敲上面的命令时把 `<TD>` 换成 `D:\anlu`，用脚本时给
`-TdPath D:\anlu`。`tools/build_td.ps1` 的 `-TdPath` 默认值仍是 `D:\TangDynasty`（为了兼容别的机器），
**本机必须显式给**，否则脚本会直接报"找不到 TD 命令行工具"。除这一处外没有别的安装路径假设。

注意：Run 目录里的 `settings.cfg` 和 `camera_to_dsi_display.prj` 都用**相对路径**
引用 `../../../user_source/`，所以编译的一定是**当前 worktree** 的源码。新建
worktree 后若没有 Run 目录，直接跑一条命令铺好：

```powershell
pwsh -NoProfile -File tools/new_worktree_runs.ps1 -TdPath D:\anlu
```

骨架来自**仓库内**的 `tools/run_skeleton/`（`settings.cfg`、`camera_to_dsi_display.prj`、
`camera_to_dsi_display.tcl`、`run.bat`，`phy_1` 另加 `.bitgen_param.f`）——clone 下来就能用，
不依赖任何机器上的其它 worktree；`run.bat` 里的 TD 路径按 `-TdPath`（默认 `D:\TangDynasty`，**本机要显式给 `D:\anlu`**）
落地。脚本随后**以 `.al` 的 `Source_Files` 为唯一事实源**把缺失的源文件登记幂等补进两个
`prj`、确保 `phy_1/settings.cfg` 带着布局参数（见 11.4 与 CHANGELOG《参数实验》）。新增
`.v` 之后跑 `-SyncOnly` 就只做登记同步；想抄一台"已知可用"的 Run 目录时用
`-SourceWorktree <路径>` 覆盖骨架源。

**为什么骨架放 `tools/run_skeleton/` 而不是把 Run 目录纳入版本库**：TD 每次构建都会改写
Run 目录里的 `settings.cfg` / `camera_to_dsi_display.prj`（时间戳、行尾、`CompileOrder`
都会动），纳入版本库会让工作区每次构建后都变脏，而 `.prj` 正是"只能由一个人登记"的那个
文件，最容易冲突。模板不参与 TD 读写，既进版本库又不脏。

**新增源文件时（2026-09-12 起）**：新加的 `.v` 必须同时登记进
`td_project/camera_to_dsi_display.al` 和两个 Run 目录的 `camera_to_dsi_display.prj`
（照抄相邻条目的 `<File Path=...>` + `CompileOrder`），否则综合时找不到模块。
Run 目录被 `.gitignore` 排除，所以从别处复制 Run 目录时也要重新补这一条
（`eram_spram.v` 就是这么加进去的）。现在这一步由上面那条 `pwsh -NoProfile -File
tools/new_worktree_runs.ps1 -SyncOnly` 自动完成：只要登记进 `.al`，两个 `prj` 会被补齐。

**改 place / route 的流程参数时**：Run 目录的 `settings.cfg` 支持"通配参数"，流程脚本
（`camera_to_dsi_display.tcl` 的 `prepare`）会把它展开成
`set_param <step> <param> <value>`：

```tcl
set phyWildParams {place opt_timing high}
```

2026-09-12 就是用这一行把布局的时序优化从默认 `medium` 提到 `high`，把 TMDS 串行域
那条"91% 是走线"的路径从 0.226 ns 拉到 1.12 ns（见 CHANGELOG《资源优化》第 4 节）。同样地，Run 目录不纳
版本库，换 worktree 时要记得补。

生成的 bitstream 位于：

```text
td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit
td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display_compress.bit
```

也可以通过 JTAG 下载或固化到板卡后上电运行。

## 7. 串口运行时日志

开发板 Type-C USB 带有 USB 转 UART，FPGA TXD 使用 H1 引脚。日志格式为
115200-8-N-1，每秒输出一行：

```text
DBG:F=xxxx A=xxxx G=xxxx T=xxxxxx N=xxxxx B=xxxxx C=xxxxx M=xxx L=xx D=xxxx E=xxxx W=xxx V=xxx K=xxxx S=xxxx P=xxxx Q=xxxx R=xxxx U=xxxx X=xxxx Y=xxxx
```

字段含义：

- `F`：HDMI 显示帧计数
- `A`：AE 曝光目标值
- `G`：AG 增益目标值
- `T`：24 位流水线状态位图，定义见 `debug_uart_logger.v` 顶部注释
- `N`：当前帧非零像素计数
- `B`：亮度不低于 64 的像素计数
- `C`：亮度不低于 128 的像素计数
- `M`：RAW10 最大值
- `L`：显示层最大值

2026-09-12 追加的 4 个字段（专门用来回答"有没有因为 FIFO 满而丢数据"，**没有复用 `T`
位图**，行因此从 70 字节变成 96 字节，115200 下一行约 8.3 ms，仍远小于 1 s 周期）：

- `D`：`video_in` FIFO（ISP→DDR）**上一帧的丢写次数**（16 位，HEX）
- `E`：`video_out` FIFO（DDR→HDMI）**上一帧的丢写次数**（16 位，HEX）
- `W`：`video_in` FIFO 上一帧**最大占用**（0..0x1FF，HEX）
- `V`：`video_out` FIFO 上一帧**最大占用**（0..0x1FF，HEX）

2026-09-14（手势游戏 M0）行尾再追加 8 个字段，全部 16 位 HEX，行 96 → 152 字节
（115200 下一行约 13.2 ms，仍远小于 1 s 周期）：

- `K`：**已提交的**模式字 `{4'h0, recog_algo[3:0], game_mode[3:0], display_mode[3:0]}`（`recog_algo`：0 = 识别停 / 1 = 手势识别）。例 `K=0111` = display_mode=1（EDGE）+ game_mode=1（游戏层开）+ recog_algo=1（手势识别开）。它取自 mode_sync 的**回执**（走 ctrl_sync 握手同步回像素域），所以"K 变了"就证明跨域提交成功；请求值看 UART 读回。
- `S`：**已生效**的边缘门限（提交到 CSI 域之后的值，默认 `0x0010`；拨码或串口改档位后看这个）
- `P`：掩码统计器的像素数 >> 4（M0 的掩码源是"边缘非零"，所以与 `N>>4` 同量级）
- `Q`：`{x_min/16, x_max/16}`（掩码包围盒列范围，各 8 位）
- `R`：`{y_min/16, y_max/16}`（掩码包围盒行范围，各 8 位）
- `U`：VIDEO_TAP 每帧像素数 >> 10，**1280x720 应恒为 `0x0384`**（900）；不等于 900 说明抽头接错了流
- `X` / `Y`：CTRL_SYNC 上行每帧字的 x / y。M0 是往返自检的测试常数，应恒为
  `X=00a5`、`Y=00d3`；M1 接入真实识别结果后这两个字段就变成手势坐标

怎么读：`D`/`E` 恒为 0 表示这一秒没有因为写满而丢数据；一旦非 0，就说明那一路的
写入被 FIFO 丢掉了（原设计里这是**静默**发生的，见第 9 节）。`W`/`V` 是余量指标：
FIFO 深度 512，`W`/`V` 越接近 `1FF` 说明离写满越近，可以提前看出"再加大算法负载就
要丢了"。丢写计数在两个 FIFO 各自的写时钟域里自由计数（不会漏单拍事件），在
`design_top_wrapper` 里同步到显示域、按显示帧取 16 位差值上报；跨域同步带来的偏斜
最多一两拍，对统计无影响。

代价（本次构建实测）：slices 12987 → 13214、LUT6 10738 → 10809、触发器 14036 →
14256、feedthrough 6513 → 6767，final Setup WNS +866 → +820 ps（仍 0 违例）。
买来的就是"丢没丢数据"从猜变成看。

`N` / `B` / `C` / `M` / `L` 都是**上一完整帧**的统计：计数器在帧首锁存后清零，所以
同一行里的字段最多只差一帧，可以安全地拿去做 A/B 对比。

EDGE 模式下显示层是梯度灰度，所以 `N` / `B` / `C` 实际是 mag ≥ 16 / ≥ 32 / ≥ 64
的像素计数，可直接用来选边缘门限，不必只靠肉眼看画面。

读取日志：

```powershell
.\tools\read_debug_uart.ps1 -Port COM3
```

脚本会同时打印到终端并追加写入 `debug_uart.log`。

日志模块的两个位宽必须用 `$clog2` 从参数推导（`CLK_PER_BIT_W` / `LOG_TICKS_W`），不要写死：
720P 把 `CLK_HZ` 提到 75 MHz 后，9 位的分频计数器到不了 651，状态机停在起始位、TXD 恒低。
成因、实测数据与修复经过见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)《串口日志》第 1 条。

同一行日志的字段必须取自同一帧：计数器在帧首锁存、日志只报**上一完整帧**，否则会出现
`B > N`、`M` 在相邻行之间乱跳。`tools/read_debug_uart.ps1` 不要无条件 `Add-Type -AssemblyName
System.IO.Ports`（PowerShell 5.1 会先报 `ASSEMBLY_NOT_FOUND` 再继续跑）。两处的成因、改法与
上板验证数据见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)《串口日志》第 2 条。

## 8. 仓库与提交

- GitHub：`git@github.com:hardcore-noob/anlogic_competition.git`
- 默认分支：`main`
- 提交身份：`hardcore-noob`（仓库本地已配置）
- 工作分支就是 `main`；下面这些分支都已快进合并进 `main`，只在本地留作历史：
  `feat/edge-magnitude`（全分辨率 Sobel + 灰度输出）、`feat/720p`（1280x720 改造）、
  `feat/edge-luma`（官方 720P luma 公式 + TH16）
- `feat/edge-magnitude-step1` 只是 A/B 对比用的中间状态（组平均 + 增益 2），
  不需要推送
- 还在做的实验放在独立 worktree 的独立分支上：`feat/edge-lut`（K=512 等边缘参数
  实验，已推送到远端同名分支）、`feat/edge-denoise`（降噪实验，本地开发中）

构建产物、TD Run 目录、bitstream 和日志默认由 `.gitignore` 排除，不纳入版本库。

## 9. 当前已知风险

- 边缘实现已改为全分辨率梯度 + 灰度输出，画面与官方例程不同；1024x600 与 720P
  都已上板确认细笔画效果良好、画面无异常（无 4 像素梳状纹理、无水平错位）。
  **2026-09-14（M0）把这条欠账降级为"计数器级对比"**：窗口生成器拆分是纯结构搬移
  （逐拍映射与层次面积表见 CHANGELOG《手势游戏 M0》阶段 2），质量证据改用同一固定
  文字目标、同光照、固定曝光下的 `DBG:` 计数器 A/B（`N/B/C` 相对差 ≤1%、`M/L` 无
  数量级偏差）。真要做逐像素对比，得先补"抓一帧导出"的通路，M1 若要更硬的证据再加；
- M0 新增两组跨域通路（像素域 ↔ CSI 域：模式寄存器帧首提交、CTRL_SYNC 上下行、
  VIDEO_TAP 每帧观测），全部走 `ctrl_sync` / `mode_sync` 的两级同步，并在
  `td_project/camera_to_dsi_display.sdc` 里按同一套路加了 `set_max_delay -datapath_only`
  约束。**再加跨域信号时必须照做**，否则时序报告不可信（这类问题会静默出错）；
- 720P 是本工程第一次跑的模式：摄像头寄存器表取自官方 `lab_ex*_SC500_720P` 例程，
  已上板实测合格。以后若改 sensor 窗口/帧率、PLL 或 HDMI 时序，必须按第 10 节的
  对照表整链一起改，并重新综合与上板确认；
- 边缘图相对 RAW 左移 1 像素、总延迟 2 拍，这是设计选择而非缺陷；
- 官方和整合版都没有完整的 ready/backpressure 闭环（`isp_top.v` 里 `m_aixs_tready`
  被注释掉、内部各级 `tready` 悬空或直接拉高，两块 FIFO 的 `full_flag` 原本也没人
  接），DDR 或 FIFO 拥塞时数据会被**静默丢弃**；720P 的 DDR 读写量比 1024x600 高
  50%（写+读约 330 MB/s），上板实测画面稳定。**2026-09-12 起这件事变成可观测的**：
  `DBG:` 行尾新增 `D/E/W/V`——`D`/`E` 是两块 FIFO 上一帧的丢写次数（非 0 就是真丢了
  数据），`W`/`V` 是上一帧的最大占用（离写满还有多少余量），见第 7 节。长时间运行
  或加大算法负载时先看这四个字段，再看帧计数和 N/B/C；
- 时序余量一直很薄：720P 上出现过 Setup **-99 ps**（只差一个端点）的版本。而且
  TD 的布局布线是确定性的——同一份网表重跑，HPWL、拥塞和时序数字完全一样，
  不能指望“再跑一次就好了”，只能改逻辑或改约束。资源优化之前，去掉 `hdmi_mixer`
  里那个 DSP 乘法器后 TH48 那版是 +728 ps、`main` 的 TH16 版只有 +596 ps（都是
  2026-09-11 前后的历史值，`feat/resource-opt` 把余量抬到 +820 ps）；**当前基线是
  `main` @ `f55ee2b` 的 final Setup WNS +930 ps**（见 11.1）。余量对布局落点很敏感，
  继续加功能后必须重新确认；
- 当前配置是“新公式 + TH16 + 增益 0”，已通过 TD（0 违例）并已上板确认（2026-09-12），
  效果优秀：弱边缘与旧版相当、旧公式的回绕假边消失，这一版是当前基线。增益 0/1 的取舍
  （饱和点 Δ≥64 vs Δ≥32）还没做板级 A/B 对比，只是可选的调优方向，不影响当前基线；
- 调 TH / 增益时**不要按灰度公式换算**：公式改的是绝对亮度，Sobel 只看局部差分，
  两者不是一回事——TH 48 那一版就是这么踩的坑，弱边缘被整片拦掉。

## 10. 分辨率与时钟配置（720P）

2026-09 起整条链路从 1024x600 升到 **1280x720@60，75 MHz 像素时钟**。分辨率是
整链参数，不能只改一处；改动时对照下表一起改，改完必须重新综合与布局布线。

| 环节                             | 现在（720P）                                                                       | 之前的 1024x600                                |
| ------------------------------ | ------------------------------------------------------------------------------ | ------------------------------------------- |
| 摄像头窗口                          | 1280x720，起点 (512,512)，HTS 1600 / VTS 1000，VBIN+HSUB，2-lane 约 480 Mbps          | 1024x600，起点 (1024,1024)，HTS 2852 / VTS 1127 |
| 摄像头寄存器表                        | `uics500reg.v`（模块名不变，内容取自官方 `lab_ex*_SC500_720P` 例程）                           | 旧表                                          |
| PLL                            | C4 75 MHz（像素）/ C5 375 MHz（TMDS serial）/ C1 23.81 MHz（摄像头 MCLK 与 I2C）           | C4 52 / C5 260 / C1 24.07 MHz               |
| VTC                            | 1280x720，帧 1650x750，sync 1390/1430、725/730                                     | 1024x600，帧 1344x635                         |
| HDMI TX core                   | HTOTAL 1650 / HSA 40 / HFP 110 / HBP 220 / VTOTAL 750 / VSA 5 / VFP 5 / VBP 20 | 1344 / 24 / 160 / 136、635 / 2 / 12 / 21     |
| ISP、边缘、裁剪、uial2axis、hdmi_mixer | 全部 1280x720                                                                    | 1024x600                                    |
| MIPI 输入约束                      | `mipi_rx_ck_pad` period 4.167ns（480 Mbps/lane，CSI 域实测 59 MHz）                  | period 2.222ns（过度约束）                        |
| 串口日志                           | `CLK_HZ = 75000000`                                                            | 52000000                                    |

摄像头寄存器表的顺序也要留意：出厂文件要求先写 `0x0100=01`（stream on，索引 114），
等 10 ms 再写 `0x302d=00`（索引 115），这个延时由 `uicfgcs500.v` 里的
`POST_STREAM_DELAY` 实现，换表时不要丢掉。

历次构建的时序与资源数字（含 720P 首版、luma 版、资源优化各轮）见
[`docs/CHANGELOG.md`](docs/CHANGELOG.md)《构建记录》；当前占用见 11.1 节。

**已上板确认**：1280x720 画面正常、RAW/EDGE 切换与曝光按键可用、OSD 位置合适，
720P 改造到此完成。后续再调算法参数时，用 `tools/read_debug_uart.ps1` 读 `DBG:`
日志（帧计数、N/B/C）做客观对比。

## 11. 资源占用与优化方向

### 11.1 现在的占用（`main` @ `f55ee2b`，2026-09-23 本机实测）

| 资源               | 用量      | 占比         | 说明                                      |
| ---------------- | ------- | ---------- | --------------------------------------- |
| slices           | 13565   | **63.94%** | 器件共 21216 个 slice（M0 时 13481 / 63.54%，资源优化后 13214 / 62.28%） |
| LUT6             | 11270   | 53.12%     | TD 的 `#lut6` 口径（M0 时 11192、资源优化后 10809） |
| 触发器              | 14732   | 34.72%     | 分母 42432（M0 时 14661）；其中 reg-only slice 2295 |
| 分布式 RAM（占 slice） | 408     | —          | 296 LUTRAM + 112 SRL                    |
| ERAM             | 70      | 64.81%     | 还剩 38 块（已成新的约束项）                        |
| DSP              | 8       | 20.00%     | 还剩 32 个                                 |
| feedthrough      | 6879    | —          | 官方 720P 例程约 2400（M0 时 6862）             |
| final Setup WNS  | +930 ps | 0 违例       | M0 时 +876 ps、资源优化后 +820 ps（门禁 ≥ +300 ps） |
| final Hold WNS   | +20 ps  | 0 违例       | —                                       |

证据是**本次运行**的 `phy_1/td_20260923_224835.log` 与 `*.area`——`pwsh -NoProfile -File
tools/build_td.ps1 -Stage summary -TdPath D:\anlu` 可以直接把这组数字复读出来，不用重编。
2026-09-26 改过一处注释后整链复跑（`phy_1/td_20260926_172957.log`，0 ERROR、0 违例，
bit 17:33:44）数字**逐项一致**——TD 的布局布线是确定性的，同一份网表重跑得到同样的结果。
比 M0 多出的 **+84 slices / +78 LUT6 / +71 FF / +17 feedthrough / +54 ps** 来自 `f55ee2b`：
`MODE_SYNC` 扩到 26 位提交字、`recog_algo`/`game_mode` 一起进跨域提交，属于正常增量。

M0 全部交付（四个插座 + 掩码统计 + 模式框架 + 在线调参 + 8 个 DBG 字段 + 引脚登记）净成本
**+383 LUT6 / +267 slices / +405 FF / +95 feedthrough**，**ERAM 与 DSP 一个没多**；
WNS 反而比 M0 之前高 56 ps。压这部分成本用的手段（RTL 减法、A/G 打拍、布局参数、
观测包整包捕获）见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)《手势游戏 M0》阶段 5、6。
对照 11.4 的余量规则，到 85% 还剩约 3700 LUT6。

slice 的构成（**资源优化后、M0 前那一版 13214 的拆分**，M0 之后没有再单独拆过）：408
（分布式 RAM）+ 7059（带 LUT 的逻辑）+ 3342（加法器/进位链）+ 2405
（只有 FF 的 slice）= 13214，其中 2405 个是打包开销，占 18.2%——比优化前（11.7%）高，
因为 LUT 砍掉四千多而触发器基本没动。官方 lab_ex1 / lab_ex2 / lab_ex3 的 720P 版本
分别是 20.2% / 19.4% / 14.7%，我们落在中间；**这也说明下一个还能压的方向是 FF 与
流水线寄存器（`f55ee2b` 实测 2295 个 reg-only slice），而不是 LUT。**

优化过程见 11.1.1~11.1.5，全部在 `feat/resource-opt` 上完成、2026-09-12 合并进
`main`：16957（79.93%）→ 14579 → 14459 → 13002 → 12987 → **13214（62.28%）**；
之后的 M0 与 `f55ee2b` 增量见本节上表。

两个容易搞混的口径：数据手册表 1-1 里 PH1P35 写的是 **LUT4s 38,189**，那是 LUT4
等效口径（= 21216 × 1.8）；TD 报告里的 `#lut6` 是物理 6 输入查找表位点数。同一份
资源、换算比 1.8，利用率两种口径算出来一样；手册同表的 DFFs 42,432、ERAM 108、
DSP 40 与 TD 报告的容量完全一致，可以互相印证。

### 11.1.1~11.1.5 优化过程（细节见 CHANGELOG）

五轮改动依次是：Logo ROM 搬 ERAM（−2378）、logger 精简（−120）、边缘行缓存搬 ERAM
（−1457）、place `opt_timing high`（不改 RTL，把 Setup 余量从 +226 ps 抬到 +866 ps）、
FIFO 观测增强（+227，把 `D/E/W/V` 加进 DBG 行）。每轮的做法、前后对比表与上板结论见
[`docs/CHANGELOG.md`](docs/CHANGELOG.md)《资源优化》。
bitstream：`td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit`

### 11.2 横向对比（`official_example/` 是本地资料、**不在版本库**，同一器件）

| 设计                                    | slices    | 占比         | LUT6  | FF    | 分布式 RAM slice |
| ------------------------------------- | --------- | ---------- | ----- | ----- | ------------- |
| lab_ex1 720P（MIPI+DDR+HDMI）           | 12358     | 58.25%     | 9865  | 13313 | 408           |
| lab_ex2 720P（+边缘）                     | 12926     | 60.93%     | 10422 | 13465 | 664           |
| lab_ex3 720P（+OSD）                    | 14852     | 70.00%     | 12669 | 13380 | 408           |
| **本工程（720P + 全分辨率边缘 + OSD + 调试，资源优化后 / M0 前）** | **13214** | **62.28%** | 10809 | 14256 | 408           |

优化完成后，我们比官方最全的 lab_ex3（14852 / 70.00%）**还低 1638 slices**：LUT6 少
1860，分布式 RAM 从“多 1152”降到与官方 lab_ex1 相同的 408；代价是触发器多 876，因为
我们多了全分辨率边缘、每帧统计和 OSD 状态机。

优化过程（每轮前后对比见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)《资源优化》）：Logo ROM 搬 ERAM 先降到 14579 / 68.72%，已经低于 lab_ex3；
随后几轮再降到 12987 / 61.21%，加上 FIFO 观测后停在 13214 / 62.28%。

### 11.3 优化方向（按性价比排序）

| 手段                                                                                                                                                                          | 估算收益            | 风险                 |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- | ------------------ |
| Logo ROM 搬 ERAM（**已完成**，见 CHANGELOG《资源优化》第 1 节：实际 −2378 slices、Setup 余量还从 +242ps 涨到 +733ps。原估算 −200~−600 严重偏小：RTL 级面积表显示它占 mixer 99% 的门；文字库 `osd_char_lib` 只有 101 门，不值得一起搬） | 实测 −2378 slices | 低：只需给地址加一级预取       |
| 分布式 RAM 搬进 ERAM —— **已完成**（见 CHANGELOG《资源优化》第 3 节：`edge_detect_96` 的 3 块行缓存改用 `eram_spram` 封装，实测 −1457 slices、`dram lut` 1448→296、ERAM +6）                                  | 实测 −1457 slices | 低（读延迟 1 拍与原写法一致）   |
| 精简调试/观测逻辑（UART logger、N/B/C/M/L 统计）—— **第一批已完成**（见 CHANGELOG《资源优化》第 2 节：删冗余双寄存器 + 行模板拆表，实测 −120 slices，日志字段与编码完全不变）；第二批（T 字段 24→8 位）、第三批（N/B/C 隔行抽样、删 A/G）经评估性价比太低，用户明确不做   | 实测 −120 slices  | 低                  |
| 宽通路重构（96 位 × 4 像素延迟线、RAW/EDGE 双路径 mux、常量乘法移位化）                                                                                                                              | −200 ~ −600     | 中高：必须守住第 4 节的流水线相位 |
| 打通拥挤、回收 feedthrough（打包选项、拆大 mux、减少跨区走线）                                                                                                                                     | −300 ~ −1000    | 高：最不确定，得反复试落点      |

实际结果比预期好：两条主要目标都已达成——Logo ROM 搬 ERAM 实测 −2378 slices，
`edge_detect_96` 的分布式 RAM 也搬进 ERAM 实测 −1457 slices，再加上 logger 精简
（−120），占用从 79.93% 一路降到 61.21%；补上 FIFO 观测增强后停在 **13214 / 62.28%**，
而且 Setup 余量从 +242 ps 提到 **+820 ps**。
（以上是 2026-09-12 资源优化那一轮的结论；M0 与 `f55ee2b` 之后当前占用是 **63.94% /
+930 ps**，见 11.1。）

继续往下压的空间已经不大：官方纯 MIPI+DDR+HDMI 的 720P 例程本身就有 58.25%，我们
只比它高 4 个百分点，却多了全分辨率边缘、OSD 和整套运行时观测。剩下的方向是 11.3
表里那两条（宽通路重构、打通拥挤），收益不确定，性价比明显低于已经做完的三项。

### 11.4 余量策略与操作注意事项

- 密度上限：**≤80% 舒适，85% 可接受，90% 是红线**。官方例子在 58%~70%，我们优化前
  是 79.93%（贴着红线），现在是 **63.94%**，回到舒适区。
- 评估“还能加多少功能”用 **1 个 LUT6 ≈ 1.2 个 slice**（当前实测 13565 / 11270 = 1.20，
  其中 2295 个是 reg-only slice）：到 85% 还能加约 4470 slices（≈3700 LUT6），到 90%
  约 5530 slices（≈4600 LUT6）。
- 比百分比更该盯的三个指标：**final Setup WNS**（建议 ≥ +300 ps 才当基线）、
  **feedthrough**（继续涨说明布线在恶化，比 slices 更早预警）、以及**能否一次
  布局布线成功**（要反复重跑就说明余量不够）。
- **属性写法不足以把大数组推断成 ERAM**（2026-09-12 用面积报告坐实）：行缓存
  无论写 Vivado 风格的 `(* ram_style = "block" *)`、还是 TD 自己模板用的
  `(*ram_style="bram"*)`，TD 仍把它们做成分布式 RAM——`u_edge_detect_96` 的
  `dram lut = 1152`、`eram = 0` 就是证据（这 1152 个 LUT 正是本工程比官方例程多
  出来的那部分分布式 RAM）。要真正搬进块 RAM，得像 `anlogic_logo_rom.v` 那样
  **直接例化 `PH1P_LOGIC_ERAM`**（TD 的器件原语模板在
  `<TD>\template\verilog\Device-Primitive\PH1P\RAM,ROM\ph1p_ram_rom.v`，**本机 `<TD>` = `D:\anlu`**，实测存在）。
  历史上行缓存落成触发器会把 FF 打满，TD 报 `PHY-9002 Placer initialization
  failed`——这个流在资源满时是“编不出来”，不是“编得慢”。
- 看资源数字请认**本次运行**的 `td_YYYYMMDD_HHMMSS.log` 与 `*.area`：`phy_1\run.log`
  可能是更早构建留下的旧文件（本项目就误读过一次，把 8 月的数字当成当次结果）。
- **定位到具体模块用 `*.area` 里的层次面积表**：syn_1 与 phy_1 各有一份
  `camera_to_dsi_display_{rtl,gate,phy}.area`，文末 `Report Hierarchy Area` 表按实例
  列出 `logic lut / ripple / seq / eram / dram lut`（父模块的数字包含子模块，可直接
  相减得到自身开销）；RTL 级那张表还带"未映射的综合门数"，正是它暴露出 logo ROM
  占了 mixer 99% 的门。**判断一块逻辑值不值得搬，看 RTL 级那张表的门数**：子模块
  在 phy 表里的数字会被优化器摊进父模块（改造前的 `u_anlogic_logo_rom` 只剩 14 LUT，
  真实代价全在父模块的 2633 里，差点让人以为它不值得搬）。
- 想加功能又不想吃 slice 时，优先用富余的块资源：**ERAM 还剩 38 块（70/108 已用）、
  DSP 还剩 32 个**。“把逻辑换成 ERAM”这条路走通了两遍（Logo ROM、edge 行缓存），
  合计省下 3835 slices；但 ERAM 已经从 36% 用到 65%，**再搬存储要先算 ERAM 余量**。
- **布局参数**（Run 目录 `phy_1/settings.cfg` 的 `set phyWildParams {...}`，换 worktree 时
  由 `tools/new_worktree_runs.ps1` 从仓库模板带过去）现在是
  `{place opt_timing high place max_fanout 250}`：
  - `opt_timing high`（2026-09-12 加）把 TMDS 串行域那条 91% 走线的路径从 0.226 ns 拉到 1.12 ns；
  - `max_fanout 250`（2026-09-14 参数实验）限制高扇出网的扇出（默认 999999 = 不限），
    让 TD 拆开高扇出网络、长线变短，final Setup WNS 一次涨 228 ps、feedthrough 也小幅回落。
  - 试过但**没采用**的：`place effort high`（feedthrough 反而 +95）、`place hfn_opt_effort high`
    （WNS 掉到 +481 ps）、`max_fanout 120`（TMDS 域掉到 0.420 ns）、`route effort high`（无效）。
    完整对比见 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)《手势游戏 M0》阶段 5。
- **TD 对"已声明为异步的时钟对"会直接忽略 `set_max_delay`**（`camera_to_dsi_display_exception.timing`
  里标成 `Set Max Delay (Ignored)`）：`MIPI_RX_BYTE_CLK`（CSI）与 `HDMI_PIXEL_CLK` 是两个
  异步组，所以这两个方向之间的路径**TD 根本不查**——验证手段只能是握手设计本身
  （toggle 两级同步 + 数据先稳定、再整包捕获）。相反，24m 与像素域在**同一个组**里，
  那里的路径照常按普通路径算，必须靠打拍/RTL 满足（A/G 进 logger 前就是靠这个修掉的）。

## 12. 手势游戏地基（M0 交付，2026-09-14）

这一节是 M1~M6 的接口说明书：插座、地址表、命令格式都是**编译期冻结**的，后续里程碑
只往里面填内容，不改接口（改了就要动顶层与 SDC，成本高且容易踩跨域的雷）。
设计背景与分工见 `docs/手势游戏实现路线规划.md`。

### 12.1 四个插座

| 插座          | 时钟域         | 端口约定                                                                                 | 实现位置                                                           |
| ----------- | ----------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| VIDEO_TAP   | CSI ~59 MHz | 96bit/4px + tuser/tlast/tvalid，取点在 `isp_top` 内部、RAW/EDGE **MUX 之前**（EDGE 模式下彩色流也在）   | `isp/recog_top.v`（M1 往这里填肤色/运动/融合掩码与跟踪）                        |
| RENDER_SLOT | 像素域 75 MHz  | DDR 读回 → 游戏层 → OSD；边界 **0 拍组合**（插寄存器会让 OSD 错开一像素）                                    | `game/game_top.v`（M3 往这里填逐像素判属渲染）                              |
| PARAM_BUS   | 像素域         | 写 `param_we / param_addr[7:0] / param_data[15:0]`（单拍脉冲），读回 `param_addr → param_data` | `param_ctrl.v`（唯一写口；源优先级 UART > KEY4 长按 > KEY4 短按 > KEY1 > 拨码） |
| CTRL_SYNC   | 跨域          | 每帧一个字 **26 位**，"每帧一次"由 toggle 表示。**下行 = 形状描述子** `{shape_type[2:0], progress[7:0], hole_w[5:0], hole_h[5:0], variant[2:0]}`；**上行 = 判定结果** `{verdict[1:0], viol_cnt[11:0], fill[11:0]}`。墙/洞坐标由共享 `shape_gen.v` 两域各算一次，不传 x/y/w/h | `isp/ctrl_sync.v`（toggle 握手 + 两级同步）+ `hdl_source/shape_gen.v`（M4c 新建，共享只读） |
| MODE_SYNC（M0 已建，2026-09-17 扩到 26 位） | 像素域 → CSI 域 | 只在值变化时发一次、在**相机帧首**提交：`bit[3:0] edge_th_sel` / `bit[7:4] display_mode` / `bit[11:8] game_mode` / `bit[15:12] recog_algo` / `bit[19:16] teach_cnt[3:0]`。CSI 域消费直接用提交寄存器；像素域（OSD 状态字、DBG 的 K）必须用**回执** | `mode_sync.v`（下行请求 + 上行回执，两条 `ctrl_sync`） |

> M0 时 CTRL_SYNC 二字是往返测试常数；M4c 起按上表改为"形状描述子 / 判定结果"，`DBG:` 的 `X`/`Y` 字段随之改语义。
数据流顺序固定：**DDR → RENDER_SLOT → OSD 文字/Logo 层 → HDMI**。游戏层永远在文字层
下面，安路 Logo 与状态字在任何模式下都盖不住（基础要求 4 天然满足）。

**跨域通路怎么保证正确**：CSI↔像素域之间的时序 TD 一律不查（见 11.4 最后一条），所以
这两条通路的正确性靠设计本身：①发送侧把数据和 toggle 同拍锁存——数据在 toggle 渡越之前
就已经稳定；②接收侧先两级同步 toggle、再边沿检测，最后**整包捕获**数据（不做逐位同步，
避免多位同时跳变时的混采）；③上板用 `DBG:` 的 `X`/`Y`（CTRL_SYNC 往返测试常数
`0x00a5`/`0x00d3`）和 `S`（模式提交后的生效门限）验证。**再加跨域信号时照这三条做**。

### 12.2 地址表（0x00~0x08）

| 地址   | 名称                   | 读写  | 说明                                      |
| ---- | -------------------- | --- | --------------------------------------- |
| 0x00 | `display_mode[3:0]`  | R/W | 0 = RAW，1 = EDGE（KEY1 短按翻转；相机帧首提交）      |
| 0x01 | `game_mode[3:0]`     | R/W | 0 = 游戏层关（KEY4 短按翻转；1 时状态字显示 GES）        |
| 0x02 | `edge_th_sel[3:0]`   | R/W | 边缘门限档位：TH = 16 + 4×sel（拨码 SW1~SW4 直接给值） |
| 0x03 | `teach_req`          | W1P | 写 1 触发一次一键示教（M1 消费；KEY4 长按也发这个）         |
| 0x04 | `teach_cnt[15:0]`    | RO  | 示教请求累计次数                                |
| 0x05 | `key4_evt[7:0]`      | RO  | `{长按次数[3:0], 短按次数[3:0]}`                |
| 0x06 | `param_wr_cnt[15:0]` | RO  | 成功写入次数——串口命令有没有落地，看这个                   |
| 0x07 | `mode_commit_cnt`    | RO  | 模式在相机帧首提交的次数                            |
| 0x08 | `recog_algo[3:0]`    | R/W | 0 = 识别停 / 1 = 手势识别（M1 消费）。KEY4 短按进 game_mode 时自动置 1、退出置 0；也可串口 `W 08 0001` 单独开 |

0x40~0x7F 归 A（视觉）、0x80~0xBF 归 B（游戏）、0xC0~0xFF 归 C（集成）；用之前先在本节登记。

> **跨域判据（2026-09-17 定）**：**算法类**（0x00 display_mode / 0x01 game_mode / 0x08 recog_algo）经 mode_sync 的 26 位提交字在**相机帧首**一起提交到 CSI 域；**系数类**（0x40~0x7F 段的肤色上下限 / 运动阈值 / quiet_th）**不跨域**——A 的阈值由 CSI 域的示教逻辑用 min/max 包络产生并保存，A 段寄存器只保留"读回来复盘"的语义，别指望用 UART 改它能影响识别。

#### 12.2.1 B 段地址表（0x80~0xBF，2026-09-26 由 B 线登记）

B 段的实现落在 `user_source/hdl_source/game/game_param.v`（M4a）。**在那之前 `param_ctrl`
只认 0x00~0x08，写 B 段会被 `default: ;` 静默丢弃、`param_wr_cnt` 也不增**——转发通路是 B 线
需求单 2（见 `B-游戏引擎实现规划.md` §9），在那之前 B 线用自己的 `localparam` 默认值跑通。

| 地址 | 名称 | 读写 | 默认 | 说明 |
| --- | --- | --- | --- | --- |
| `0x80` | `game_sel[3:0]` | R/W | 1 | **选哪个游戏**：1 = 切水果（2 = PONG、3 = BRICK 后续）。只在 `0x01 game_mode ≠ 0` 时被渲染层读取；**"游戏层开关"永远是 0x01**，这里不定义"0 = 无游戏" |
| `0x81` | `game_ctrl[3:0]` | W1P | — | bit0 重开本局、bit1 强制回待机、bit2 强制关层（回待机但不改 0x01）、bit3 暂停 |
| `0x82`~`0x84` | — | — | — | 预留给后续 Pong（球速 / 拍高 / AI 等级） |
| `0x85` | `input_src[3:0]` | R/W | 0 | 0 = 假源、1 = 手势、2 = UART 手柄（预留） |
| `0x86` | `input_cfg[15:0]` | R/W | — | `{假源档位[3:2], 死区[1:0]}`（档位 0 乱舞 / 1 固定圆 / 2 UART 直给） |
| `0x87` | `input_gain[15:0]` | R/W | 0x0100 | 归一化增益（定点 ×256） |
| `0x88` | `input_offset[15:0]` | R/W | 0 | 归一化偏置（有符号） |
| `0x89` | `fruit_spawn[7:0]` | R/W | 48 | 生成间隔（帧） |
| `0x8A` | `fruit_grav[15:0]` | R/W | 0x0040 | 定点重力 |
| `0x8B` | `fruit_v0[15:0]` | R/W | 0x0800 | 初速档（水平/垂直各 8 位）；垂直初速 = `v0[15:8]×2` px/帧（默认 16 px/帧 → 顶点升高约 512 px） |
| `0x8C` | `trail_cfg[15:0]` | R/W | `{8'd8, 8'd10}` | `{点数, 寿命帧}` |
| `0x8D` | `particle_cfg[15:0]` | R/W | `{8'd8, 8'd20}` | `{粒子数, 寿命}` |
| `0x8E` | `field_y0[11:0]` | R/W | 200 | 场地上边界 |
| `0x8F` | `field_y1[11:0]` | R/W | 704 | 场地下边界（漏切判定线） |
| `0x90` | `game_state[15:0]` | RO | — | `{state[3:0], lives[3:0], score[7:0]}` |
| `0x91` | `blade_pos[15:0]` | RO | — | `{x[7:0], y[7:0]}`（各 >>3） |
| `0x92` | `fruit_pos[15:0]` | RO | — | 1 号水果坐标（>>3） |
| `0x93` | `hit_cnt[15:0]` | RO | — | 累计切中数（调试与计分核对） |
| `0x94` | `miss_cnt[15:0]` | RO | — | 累计漏切数 |
| `0xA0` | `dbg_blade_x[11:0]` | R/W | — | 调试刀尖 x（假源档位 2 时直接给坐标，从 PC 手动切） |
| `0xA1` | `dbg_blade_y[11:0]` | R/W | — | 调试刀尖 y |
| `0xA2` | `dbg_blade_en` | R/W | — | 调试坐标有效标志（0 = 用自动档） |
| `0xA3` | `dbg_marker_en` | R/W | 0 | **1 像素对齐标记开关**（L1 坐标自检）：白点画在 `(0,0)`、`(1279,719)`、`(7,127)`、`(106,127)`、`(152,34)`；后三个落在 Logo 墨迹极值点上——**对齐 = 被墨迹盖住看不见，差 1 像素就会在墨迹边冒白点**。串口 `W A3 0001` 打开 |
| `0xB0`~`0xBF` | 预留 | — | — | 用完再登记 |

### 12.3 串口在线调参

115200-8-N-1，命令是 ASCII 一行：`W <addr 2 位hex> <data 4 位hex>` + CR/LF，大小写
通吃，**只写不回显**；生效与否看 `DBG:` 的 `S`（提交后的门限）与 `K`（模式字）。

```text
W 02 0003      # 门限档位 3 → 生效 TH = 28（DBG 的 S=001c）
W 00 0001      # 切到 EDGE
W 01 0001      # 打开游戏层（状态字变 GES）
W 03 0001      # 发一次一键示教请求（teach_cnt 加 1）
```

B 段（0x80~0xBF）的命令示例见 12.2.1 与 `B-游戏引擎实现规划.md` §6，例如
`W 85 0000`（输入源切假源）、`W A0 0400` + `W A1 0300` + `W A2 0001`（手动给刀尖）。
注意在 `param_ctrl` 开通 B 段转发之前，这些写入会被静默丢弃，只是当前已知的待办。

### 12.4 M0 上板自检清单

> **tuser 与 valid 不同相（2026-09-15 上板踩到的坑）**：`awb.v` 里 tuser 是**直通**的
> （`assign O_tuser = I_tuser;`），valid 是流水后的、而且行间有空隙（同文件里
> `O_tlast = (valid_d1==0)&&(valid_d2==1)` 就是靠这个空隙检测行首）。所以 **tuser 脉冲
> 经常落在 valid=0 的拍上**。任何帧级计数/锁存都不能写成 `if(tvalid && tuser)`，要
> **计数按 valid、锁存按 tuser**；跨域的每帧 toggle 也只能看 tuser。M1 的每帧统计照这条做，
> 否则会重演"观测字段恒 0、画面却完全正常"的坑（见 CHANGELOG《手势游戏 M0》阶段 6）。

烧 `td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit` 后逐项看：

1. 基础四项：RAW/EDGE 画面正常、KEY1 切换、KEY2/KEY3 曝光、Logo/动态文字/帧计数 OSD。
2. `DBG:` 行 152 字节完整可读，`D`/`E` 恒 0。
3. `U=0384`（tap 每帧像素数）、`X=00a5` / `Y=00d3`（CTRL_SYNC 往返）。
4. `P` 与 `N>>4` 同量级；`Q`/`R` 满足 x_min≤x_max、y_min≤y_max（包围盒各 16 像素粒度）。
5. 拨 SW1~SW4：`S` 随之变化（16/20/24/…），EDGE 画面灵敏度肉眼可见地变。
6. 串口发 `W 02 0003`：`S` 变 `001c`、`param_wr_cnt` 自增（不发命令时它不动）。
7. KEY4 短按：`K` 的 game_mode 位翻转、**recog_algo 位同时 0↔1**（进游戏置 1 = 手势识别、退出归 0）、状态字变 `GES`、LED 同步；注意 `K` 是**已提交值**，会在**下一个相机帧首**才变（约 1 帧延迟）。长按 ≥1 s：`teach_cnt` 增 1。
8. 串口 `W 08 0001`：`K` 的 algo 位变 1——**不进游戏模式也能单独开识别**，M1 调算法时用这条。
