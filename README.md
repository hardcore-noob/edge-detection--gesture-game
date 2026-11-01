# anlogic_competition

FPGA 竞赛安路赛道赛题二工程：基于 PH1P35/HX1P35A 开发板，把 MIPI 摄像头采集、
ISP、边缘检测、OSD 叠加和 HDMI 显示整合到同一个 bitstream 中。

## 0. AI 会话入口（新会话先读）

新会话先阅读以下资料，再改代码：

1. `参考资料/赛题解析二-整理.md`：赛题目标和交付要求。
2. 本 README 第 1～3 节：工程概览、数据流和按键。
3. [`docs/手势游戏实现路线规划.md`](docs/手势游戏实现路线规划.md)：里程碑、模块职责和资源预算。
4. [`docs/手势识别待修复问题-20261023.md`](docs/手势识别待修复问题-20261023.md)：识别问题、复现条件和待验证方案。
5. [`docs/gesture-game-interface.md`](docs/gesture-game-interface.md)：插座、完整寄存器、玩法和测试清单。
6. 查串口字段时读 [`docs/debug-uart.md`](docs/debug-uart.md)。
7. 查资源、面积表和布局参数时读 [`docs/resource-budget.md`](docs/resource-budget.md)。
8. 查历史实现、实验过程和旧构建结论时读 [`docs/CHANGELOG.md`](docs/CHANGELOG.md)。
9. 实现手部二维种子连通域前读
   [`docs/手势种子连通域实现计划.md`](docs/手势种子连通域实现计划.md)。

硬件参考资料位于 `参考资料/`。Markdown 是整理版，若与 PDF/PPTX 或硬件手册冲突，
以原始资料为准。

### 当前状态

- 当前分支：`feat/occ-gate-25pct`。
- 当前基线：slices `18166/21216`（85.62%）、LUT6 `16641`、ERAM `80/108`、
  DSP `8/40`、final Setup `+441 ps`、Hold `+20 ps`，0 违例。
- 手部掩码使用全局 7/8 投票和 16×16 全块面积占比门（`OCC_MIN=103/256≈40.2%`）；
  M2 通过 `S_m_pick_d` 共用同一结果。
- 下一阶段：优先优化资源占用和手势识别算法。
- 构建门禁：slices <95%、Setup ≥ `+200 ps`、Hold 0 违例、一次 PnR 通过。

### 工作规则

- 开工先执行 `git status`，不要覆盖或提交会话外产生的改动。
- RTL 或约束改动后运行 `pwsh -NoProfile -File tools/build_td.ps1`；只改文档不构建。
- 新克隆或新 worktree 先运行 `pwsh -NoProfile -File tools/new_worktree_runs.ps1`。
- 无用户明确要求时，不执行 `git push`、改写历史或合并外部改动。
- `tmp/`、TD Run 目录、bitstream 和日志均不纳入版本库。

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

`edge_detect_96.v` 保持 96 位 × 4 像素/拍接口。当前实现有三个关键约束：

- 每个像素独立做 Sobel，不再先把同拍 4 像素平均，因此竖线和弱边缘不会被组平均抹掉。
- 输出梯度灰度而非硬二值；当前固定为官方 720P luma 公式、`TH=16`、增益 0。
- 总延迟为 2 拍，输出 4 个像素对应源列 `4k-1..4k+2`，整幅边缘图相对 RAW 左移 1 像素。

帧级逻辑必须遵守：`tuser` 是直通信号，可能落在 `tvalid=0` 的拍上。计数按 `tvalid`，
帧首锁存和跨域 toggle 按 `tuser`。

三块行缓存显式使用 ERAM；不要改回普通数组或只依赖 `ram_style` 属性。修改边缘算法时
必须保持像素组顺序、2 拍延迟和输出对齐。详细推导见 CHANGELOG《边缘算法调参》与
《资源优化》。

## 5. OSD 与画面状态

`hdmi_mixer.v` 按以下顺序叠加：

- 左上角安路 Logo。
- 中部动态文字和帧计数。
- 右上角状态字：`RAW` / `EDGE` / `GES`。
- 游戏层位于文字层和 Logo 层下方，不能遮挡基础 OSD。

720P 固定坐标：Logo `160×160`、动态文字/帧计数 `x=540`、状态字 `x=1100`。
Logo ROM 使用 ERAM，读延迟 1 拍，地址由 `S_x_1d/S_y_1d` 预取；修改 `*_1d` 流水级时
必须同步修改地址生成。

## 6. 编译与烧录

TD 工程入口：

```text
td_project/camera_to_dsi_display.al
```

首次或新 worktree：

```powershell
pwsh -NoProfile -File tools/new_worktree_runs.ps1
```

完整构建：

```powershell
pwsh -NoProfile -File tools/build_td.ps1
```

每次成功生成 bit 后，脚本会把普通版和压缩版自动归档到
`temp/<时间戳>_<分支名>[_标签]/`，方便烧录对比；上面的目录已被 Git 忽略。
可用 `-BitLabel global7` 为本次对照补充可读标签。

`build_td.ps1` 依次运行 `syn_1`、`phy_1` 和 bitgen，并在末尾输出时序、资源和 bit 路径。
新增 `.v` 后先登记到 `.al`，再运行 `tools/new_worktree_runs.ps1 -SyncOnly` 同步两个
Run 目录的 `.prj`。

生成的 bit：

```text
td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display.bit
td_project/camera_to_dsi_display_Runs/phy_1/camera_to_dsi_display_compress.bit
```

Run 目录、构建日志和 bitstream 均被 `.gitignore` 排除。旧的 TD 骨架设计理由和手工命令
记录见 CHANGELOG。

## 7. 串口运行时日志

串口格式为 115200-8-N-1，每秒输出一行：

```text
DBG:F=xxxx A=xxxx G=xxxx T=xxxxxx N=xxxxx B=xxxxx C=xxxxx M=xxx L=xx D=xxxx E=xxxx W=xxx V=xxx K=xxxx S=xxxx P=xxxx Q=xxxx R=xxxx U=xxxx X=xxxx Y=xxxx
```

| 字段组 | 含义 |
|---|---|
| `F/A/G/T` | HDMI 帧计数、AE 曝光、AG 增益、24 位流水线状态 |
| `N/B/C/M/L` | 当前算法亮度和像素统计；均为上一完整帧 |
| `D/E/W/V` | 两块 FIFO 的丢写次数和最大占用；`D/E` 非 0 表示真实丢数 |
| `K/S` | 已提交模式字、已生效边缘门限 |
| `P/Q/R/U/X/Y` | 掩码/手势统计、VIDEO_TAP 像素数、CTRL_SYNC 往返自检 |

`P/Q/R` 的调试复用规则见
[`docs/debug-uart.md`](docs/debug-uart.md)。

读取日志：

```powershell
.\tools\read_debug_uart.ps1 -Port COM3
```

同一行字段必须来自同一帧；计数在帧首锁存后清零。`U=0384`、`X=00a5`、`Y=00d3`
可用于确认 tap 和 CTRL_SYNC 通路。

## 8. 仓库与文档

- GitHub：`git@github.com:hardcore-noob/anlogic_competition.git`
- 默认分支：`main`
- 构建产物、TD Run 目录、bitstream 和本地日志不纳入版本库。

长期保留的文档只有：

- [`docs/CHANGELOG.md`](docs/CHANGELOG.md)：实现历史、构建数字、实验和上板结论。
- [`docs/手势游戏实现路线规划.md`](docs/手势游戏实现路线规划.md)：里程碑、模块所有权、接口和资源预算。
- [`docs/手势识别待修复问题-20261023.md`](docs/手势识别待修复问题-20261023.md)：识别问题清单和复现条件。
- [`docs/debug-uart.md`](docs/debug-uart.md)：完整 DBG 字段、复用规则和读取方法。
- [`docs/resource-budget.md`](docs/resource-budget.md)：当前资源、门禁、面积表和布局参数。
- [`docs/resource-optimization-backlog.md`](docs/resource-optimization-backlog.md)：
  资源优化候选、优先级和已完成实验结果。
- [`docs/gesture-game-interface.md`](docs/gesture-game-interface.md)：插座、参数地址、玩法和测试清单。

边缘算法原理和调参过程以 CHANGELOG 为准，不再另建平行文档。

## 9. 当前已知风险

- 手势识别仍需改善下劈稳定性、脸/背景误锁、白/自然光鲁棒性、远距离锁定和坐标抖动；
  当前已恢复行带水平窗和窄行拆带，识别稳定性优先；脸、手臂和背景粘连留给后续
  种子连通域处理。
- 当前 slices 为 85.62%，新增功能前仍必须先评估资源和 feedthrough。
- 时序余量对布局落点敏感；同一网表重复 PnR 不会自动改善，必须改逻辑或约束。
- 链路没有完整 ready/backpressure 闭环；DDR/FIFO 拥塞时可能静默丢数，需监控 `D/E/W/V`。
- CSI 与 HDMI 像素域是异步组，TD 不检查其间路径；跨域必须使用 toggle 握手、两级同步
  和整包捕获。

## 10. 分辨率与时钟配置（720P）

| 环节 | 当前配置 |
|---|---|
| 摄像头窗口 | 1280×720，起点 (512,512)，HTS 1600 / VTS 1000，VBIN+HSUB，2-lane |
| PLL | C4 75 MHz 像素 / C5 375 MHz TMDS serial / C1 23.81 MHz 摄像头 MCLK 与 I2C |
| VTC | 1280×720，帧 1650×750，sync 1390/1430、725/730 |
| HDMI TX | HTOTAL 1650 / HSA 40 / HFP 110 / HBP 220 / VTOTAL 750 / VSA 5 / VFP 5 / VBP 20 |
| ISP、边缘、裁剪、uial2axis、hdmi_mixer | 全部 1280×720 |
| MIPI 输入约束 | `mipi_rx_ck_pad` period 4.167 ns，CSI 域实测约 59 MHz |
| UART logger | `CLK_HZ=75000000` |

摄像头寄存器表必须先写 `0x0100=01`，延时 10 ms 后再写 `0x302d=00`；延时由
`uicfgcs500.v` 的 `POST_STREAM_DELAY` 实现。修改 sensor 窗口、PLL 或 HDMI 时序时，
上述整条链路必须一起修改并重新上板确认。

## 11. 资源占用与优化

### 11.1 当前基线

| 资源 | 用量 | 占比 |
|---|---:|---:|
| slices | 18166 / 21216 | 85.62% |
| LUT6 | 16641 / 21216 | 78.44% |
| 触发器 | 16198 / 42432 | 38.17% |
| ERAM | 80 / 108 | 74.07% |
| DSP | 8 / 40 | 20.00% |
| feedthrough | 6116 | — |
| final Setup WNS | +441 ps | 0 违例 |
| final Hold WNS | +20 ps | 0 违例 |

### 11.2 优化方向

1. 按 [`docs/resource-optimization-backlog.md`](docs/resource-optimization-backlog.md)
   的顺序继续裁剪 `recog_top` 调试档和 `game_fruit` 状态/物理通路。
2. 清理已完成功能留下的死代码、重复 mux 和未使用寄存器。
3. 优先复用已有 ERAM/DSP 和共享数据通路，不为单一功能复制整套组合逻辑。

### 11.3 资源判读

只看本次运行生成的 `td_YYYYMMDD_HHMMSS.log` 和 `*.area`，不要误用旧的 `run.log`。
模块开销优先查 `*.area` 文末的层次面积表；RTL 级门数用于判断大块逻辑是否值得搬迁。
完整方法和布局参数见 [`docs/resource-budget.md`](docs/resource-budget.md)。

### 11.4 余量策略与门禁

- 建议密度：≤80% 舒适、85% 可接受、95% 为当前硬门禁。
- final Setup 必须 ≥ `+200 ps`，Hold 无违例，并争取一次 PnR 通过。
- feedthrough 持续上升通常比 slices 更早暴露布线恶化。
- 不允许通过降低功能正确性、关闭必要验证或跳过时序检查来换资源数字。

## 12. 手势游戏接口与操作

`VIDEO_TAP` 提供 CSI 域观测，`RENDER_SLOT` 位于 DDR 读回与 OSD 之间，
`PARAM_BUS` 是唯一参数写口，`CTRL_SYNC`/`MODE_SYNC` 负责跨域提交。

### 12.1 四个插座

| 插座 | 时钟域 | 约定 |
|---|---|---|
| `VIDEO_TAP` | CSI ~59 MHz | 96 bit/4 px，含 tuser/tlast/tvalid；观测包含 track x/y/locked |
| `RENDER_SLOT` | 像素域 75 MHz | DDR 读回 → 游戏层 → OSD；对外必须 0 拍组合 |
| `PARAM_BUS` | 像素域 | 单拍写；来源优先级 UART > KEY4 长按 > KEY4 短按 > KEY1 > 拨码 |
| `CTRL_SYNC` | 跨域 | 每帧 26 位，toggle 握手；下行形状描述子、上行判定结果 |
| `MODE_SYNC` | 像素域 → CSI | 算法类寄存器在相机帧首提交；像素域使用回执 |

跨域固定规则：发送侧同拍锁存数据和 toggle；接收侧两级同步并整包捕获；禁止逐位同步。
完整插座、参数地址、玩法和测试清单见
[`docs/gesture-game-interface.md`](docs/gesture-game-interface.md)。

### 12.2 系统地址

| 地址 | 名称 | 说明 |
|---|---|---|
| `0x00` | `display_mode` | 0=RAW，1=EDGE |
| `0x01` | `game_mode` | 0=游戏层关，1=GES |
| `0x02` | `edge_th_sel` | TH = 16 + 4×sel |
| `0x03` | `teach_req` | 示教已停用；写入仍计入计数 |
| `0x04` | `teach_cnt` | 示教请求累计 |
| `0x05` | `key4_evt` | `{长按次数, 短按次数}` |
| `0x06` | `param_wr_cnt` | 成功写入次数 |
| `0x07` | `mode_commit_cnt` | 模式提交次数 |
| `0x08` | `recog_algo` | 0=停，1=手势识别；8..15 为调试档 |

0x40~0x7F 归 A，0x80~0xBF 归 B，0xC0~0xFF 归 C。算法类寄存器跨域，系数类寄存器
不跨域。

### 12.2.1 B 段地址（0x80~0xBF）

| 地址 | 名称 | 默认值 | 说明 |
|---|---|---|---|
| `0x80` | `game_sel` | 1 | 1=切水果 |
| `0x81` | `game_ctrl` | 0 | bit0 重开、bit1 待机、bit2 关层、bit3 暂停 |
| `0x85` | `input_src` | 1 | 0=假源，1=手势，2=UART 手柄预留 |
| `0x86` | `input_cfg` | 0 | 假源档位/死区 |
| `0x87` | `input_gain` | 0x0100 | 保留，未参与运算 |
| `0x88` | `input_offset` | 0 | 手势源 x/y 有符号偏置 |
| `0x89` | `fruit_spawn` | 48 | 水果生成间隔 |
| `0x8A` | `fruit_grav` | 0x0040 | 重力 |
| `0x8B` | `fruit_v0` | 0x0900 | 垂直初速/水平散布 |
| `0x8C` | `trail_cfg` | 0x080A | 刀光参数，编译关闭 |
| `0x8D` | `particle_cfg` | 0x0814 | 粒子寿命，已启用 |
| `0x8E` | `field_y0` | 200 | 场地上边界 |
| `0x8F` | `field_y1` | 704 | 漏切判定线 |
| `0x90` | `state_word` | RO | `{state[3:0], 3'b0, score_neg, score_bcd[7:0]}` |
| `0x91` | `blade_pos` | RO | 刀尖坐标（粗） |
| `0x92` | `fruit_pos` | RO | 1 号水果坐标（粗） |
| `0x93` | `hit_cnt` | RO | 切中计数 |
| `0x94` | `miss_cnt` | RO | 漏切计数 |
| `0xA0~0xA3` | 调试寄存器 | — | UART 刀尖和 5 点对齐标记 |

未登记地址读回 `0xFFFF`。

### 12.3 串口在线调参

命令格式：`W <addr 2位HEX> <data 4位HEX>`，无回显。

```text
W 02 0003      # 门限档位 3，生效 TH=28
W 00 0001      # 切换 EDGE
W 01 0001      # 打开游戏层
W 08 0001      # 单独启用手势识别
W 85 0000      # 回假源
W 85 0001      # 切回手势源
```

### 12.4 上板自检

1. RAW/EDGE、KEY1、KEY2/KEY3 和基础 OSD 正常。
2. DBG 行完整，`D=E=0`、`U=0384`、`X=00a5`、`Y=00d3`。
3. KEY4 短按正确提交 `game_mode` 与 `recog_algo`，长按计入示教次数。
4. 拨码和串口改门限后，`S`、`param_wr_cnt` 按预期变化。
5. 手势重新锁定后历史点从当前刀尖填满，不跨屏补放旧轨迹。
6. 假源/UART 可移动刀锋，但不计分。

### 12.5 刀锋轨迹连续切水果

1. KEY4 进入游戏后默认使用手势源，无需先设置 `input_src`。
2. 水果显示和碰撞箱均为 128×128，指尖轨迹命中外扩 10 px 的 AABB 即切中。
3. 使用 8 个刀锋历史点和 16 个插值采样点，一帧可命中多颗水果。
4. `cut_enable = blade_valid && track_locked && input_src==1`；进入时历史点填满，
   失锁时清空。
5. 切中水果 `+1`，漏掉水果 `-1`；切中炸弹 `-5`，漏掉炸弹不扣分。分数范围
   `-99..+99`，负分在两位数字左侧显示负号。
6. 已移除生命值和结束态；漏切不会结束游戏。炸弹生成概率约 12.5%，同屏最多一颗。
7. 水果命中显示黄色粒子，炸弹命中不产生半片，改为橙红色 `12×12` 爆散粒子。
8. 左右挥切生成上下半片，上下挥切生成左右半片；半片严格使用
   `pal[3]=A/B侧`、`pal[2]=负x`、`pal[1:0]=水果种类`、`color[6]=切割轴`。
9. 左侧水果逐渐裁剪到 `x<=-128` 后回收；右侧在 `x>=1280` 回收。
10. 动态挥手事件与 `game_gesture` 已移除；游戏主路径使用独立的刀锋轨迹判定，`0x95` 已移除。
11. 当前构建：slices `18166/21216`（85.62%）、LUT6 `16641`、Setup `+441 ps`、
   Hold `+20 ps`，0 违例。

| `W 08 000X` | 识别视图 |
|---|---|
| 0 | 原图 |
| 1 | 交付档：掩码 + 准星 |
| 2/3 | 运动门开/关 |
| 4/5 | 运动门归因 / 只看肤色 |
| 6/7 | 已删除（按普通融合视图处理） |
| 8/9 | 亮度数字增益 ×2 / ×4 |
| 10/11 | 旧肤色预设（现为普通融合视图） |
| 12 | 亮度灰阶 |
| 13 | 肤色判据按 Y 分档 |
| 14/15 | 亮暖反射+运动门 / 全部候选（P/Q 不再报 Y/sat 极值） |

## 13. README 更新准则

README 面向项目介绍、快速上手和新会话交接。更新时按以下规则放置内容：

| 内容 | 放置位置 |
|---|---|
| 项目目标、数据流、按键、快速构建、当前状态 | README |
| 完整 DBG 字段、字段复用和读取细节 | `docs/debug-uart.md` |
| 资源表、门禁、面积表方法和布局参数 | `docs/resource-budget.md` |
| 插座、完整参数地址、玩法与测试清单 | `docs/gesture-game-interface.md` |
| 历史实现、实验过程、构建演化和旧结论 | `docs/CHANGELOG.md` |
| 里程碑、模块所有权和资源分配 | `docs/手势游戏实现路线规划.md` |
| 当前识别问题、复现条件和待验证方案 | `docs/手势识别待修复问题-20261023.md` |

执行规则：

1. README 只写当前有效事实；同一事实只在最合适的位置维护，其他位置用链接。
2. 详细参考超过约 10 行时，优先写入专题文档，README 保留摘要和触发条件明确的链接。
3. 更新资源数字时同步检查第 0、11、12.5 节；完整资源方法只维护在
   `docs/resource-budget.md`。
4. 更新 DBG 字段或字段复用时同步检查 `debug_uart_logger.v`、读取脚本、
   `docs/debug-uart.md` 和 README 第 7 节。
5. 更新参数地址、插座或玩法时同步检查 `docs/gesture-game-interface.md` 和 README 第 12 节。
6. 历史过程、失败方案、逐次构建数字和旧阈值只写 CHANGELOG，不写进 README。
7. 第 1～3 节是项目最小介绍，除非数据流或按键实际变化，否则保持稳定。
8. 保留第 4～12 节和 `12.2.1`、`12.5` 等被源码引用的编号；改编号时全仓搜索引用并一起更新。
9. README 目标控制在约 400 行、10～12k 字符以内；新增内容先判断能否链接到专题文档。
10. 只改文档时无需重新构建；RTL、约束、工具参数或构建结果变化时，按仓库规则重新构建并更新相关文档。
