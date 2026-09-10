# anlogic_competition

FPGA 竞赛安路赛道赛题二工程：基于 PH1P35/HX1P35A 开发板，把 MIPI 摄像头采集、
ISP、边缘检测、OSD 叠加和 HDMI 显示整合到同一个 bitstream 中。

## 0. AI 会话入口（新会话先读）

如果你是新会话中的 AI，先不要直接改代码。按下面顺序阅读，可以快速建立
本项目的目标、硬件约束和当前工作方向：

1. `参考资料/赛题解析二-整理.md`：赛题目标、评分点、必须实现的进阶功能和验收方向。
2. `参考资料/新HX1P35A开发板手册-HDL版2604-文本.md`：开发板资源、按键、时钟、外设和约束。
3. `参考资料/SC500CS_数据手册_V1.8-整理.md`：摄像头寄存器、曝光/增益和图像配置。
4. `参考资料/DS1300_PH1P_Datasheet.md`：PH1P 器件和 DDR/外设接口资料。
5. `参考资料/TangDynasty_CLI编译流程.md`：TD 命令行综合、布局布线和 bitgen 流程。
6. 回到本 README 的第 1～9 节，理解当前数据流、按键、边缘基线和已知风险。

`参考资料/` 中的 PDF、PPTX 是原始资料；上面的 md 文件是便于 AI 阅读的整理版。
如果 md 和原始资料存在冲突，以赛题原始文件和硬件手册为准，并在代码提交说明中
记录冲突点。

阅读完成后，AI 应明确以下工作方向：

- 当前目标是赛题二：在同一系统中完成 MIPI 采集、RAW/EDGE 实时切换、OSD、
  HDMI 显示和可观测的运行时日志。
- 当前 `edge_detect_96.v` 是官方 `lab_ex2_edge` 的兼容基线。不要因为它有
  数值位宽问题就盲目替换；任何“更正确”的重写都必须先证明细字体边缘没有退化。
- 后续优化应优先围绕“文字边缘清晰度、稳定性、可复现对比”展开，而不是只追求
  边缘数量或单帧检测结果。
- 调试时优先使用 `tools/read_debug_uart.ps1` 读取 `DBG:` 日志，再结合代码修改；
  不要只凭一张画面的主观印象反复编译。

工作时必须遵守：

- 先执行 `git status`，不要覆盖或提交会话外产生的未提交改动。
- `tmp/` 是本地临时诊断目录，不纳入提交；TD Run、bitstream、日志由 `.gitignore`
  排除。
- 当前按键定义为：KEY1 切换 RAW/EDGE，KEY2 降低曝光，KEY3 提高曝光。
- 修改边缘模块、OSD 或 top wrapper 后，必须重新做 TD 综合/布局布线，并报告
  实际 bitstream 路径和时序结果。
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

| 板载按键 | 顶层信号 | 引脚 | 功能 |
|----------|----------|------|------|
| KEY1 | `I_button[1]` | D5 | RAW / EDGE 算法切换 |
| KEY2 | `I_button[0]` | A9 | 曝光目标值递减 |
| KEY3 | `I_button[2]` | B9 | 曝光目标值递增 |

KEY1 采用约 20 ms 消抖，短按一次切换一次算法。KEY2、KEY3 当前为短按调节，
不支持长按连续调整。KEY4 暂未使用。

## 4. 边缘检测实现

`user_source/hdl_source/isp/edge_detect_96.v` 自 `feat/edge-magnitude` 分支起做了
两处结构改动。输入输出仍是 96 位 × 4 像素/拍，`O_tuser` / `O_tlast` / `O_tvalid`
与数据严格对齐，但本版总延迟为 2 拍，且输出的 4 个像素对应列 4k-1..4k+2，
因此整幅边缘图相对 RAW **左移 1 像素**。

1. **全分辨率梯度**。官方实现先做 `grp_gray = (gray0+gray1+gray2+gray3)>>2`，
   把同拍 4 个像素平均成一个再做 Sobel，真正参与梯度运算的是 256×600 的图，
   结果再复制回 4 个像素。宽度小于 4 像素的竖线因此被 4 倍组平均压到阈值以下
   而完全消失。本版为每个像素单独算 Sobel（4 路并行）。
2. **输出梯度灰度而不是硬二值化**。`I_thresh` 只作噪声门限，门限以上保留灰阶：
   `显示灰度 = clamp((|gx|+|gy|) << EDGE_GAIN_SHIFT)`，默认增益为 1（×2、饱和到 255）、
   门限 16。
   同时删掉了三点多数滤波，它会把细笔画产生的孤立边缘像素直接抹掉。

幅度对比（全图亮度被压缩在 0..85，按整数运算推导）：

| 竖线宽度 | 官方组平均版 | 原 `EDGE_TH=132` | 全分辨率版（门限 16） |
|----------|--------------|------------------|------------------------|
| 1 像素   | 40           | 消失             | 168                    |
| 2 像素   | 84           | 消失             | 252                    |
| ≥3 像素  | ≥124         | 3 像素仍消失     | ≥252                   |

上表是 Sobel 幅度本身；默认增益 ×2 之后这些幅度都会饱和到 255，门限以下仍为 0。

上板 A/B 对比（第一步：组平均 + 增益 2 / 第二步：全分辨率 + 增益 0）的结论：
**第一步的笔画更粗，但两版明暗肉眼分辨不出**。粗笔画说明第一步那种"更好看"
有相当一部分来自组平均把边缘摊成 4 像素的副作用；明暗无差异说明真实笔画宽度多在
3 像素以上、两版都已接近饱和。因此保留全分辨率几何，把增益调回 1。

行缓存改成**三块按行轮转的 block RAM**：每块 256×48 位，保存一行内 6 个平滑灰度
（对应列 4k-2..4k+3），每周期只写其中一块、只读另外两块，读写永不同址且读地址已
寄存。这是必需的——全分辨率下若沿用官方那种异步读写法，行缓存会落成触发器，直接
把器件 FF 资源耗尽（TD 报 `PHY-9002 Placer initialization failed`）。改成 BRAM
后最终时序反而由负转正。

官方实现保留的已知限制：

- 灰度计算 `R+G+B` 在 8 位表达式中回绕后再除以 3，会产生约 85 为周期的锯齿，
  并把全图亮度压缩到 0..85（上表幅度偏小即由此而来）；
- `data96_128` 的 128 位打包计数器不会被帧起始单独复位。

任何进一步的数值“修正”都必须保持 `O_tuser` / `O_tlast` 与数据对齐，
并用固定文字目标做整幅边缘图对比后再替换，不能只比较“是否能检测到边缘”。

## 5. OSD 与画面状态

`hdmi_mixer.v` 负责在 HDMI 数据输出前叠加：

- 左上角：安路 Logo；
- 中部：动态文字和帧计数；
- 右上角：当前算法状态 `RAW` / `EDGE`。

算法状态文字位置由 `STATUS_OSD_X`、`STATUS_OSD_Y` 参数控制。切换算法瞬间
可能出现短暂的一帧撕裂，下一帧恢复属于当前设计的预期现象。

## 6. 编译与烧录

使用安路 TangDynasty 打开：

```text
td_project/camera_to_dsi_display.al
```

命令行编译时，TD 安装在 `D:\TangDynasty`，两个 Run 目录分别是：

```text
td_project/camera_to_dsi_display_Runs/syn_1
td_project/camera_to_dsi_display_Runs/phy_1
```

完整流程：

```bat
cd /d D:\competition\example\lab_ex4_integrated\lab_ex4_integrated\td_project\camera_to_dsi_display_Runs\syn_1
D:\TangDynasty\bin\td_commands_prompt.exe D:/TangDynasty/scripts/DefaultFlow.tcl

cd /d ..\phy_1
D:\TangDynasty\bin\td_commands_prompt.exe D:/TangDynasty/scripts/DefaultFlow.tcl
```

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
DBG:F=xxxx A=xxxx G=xxxx T=xxxxxx N=xxxxx B=xxxxx C=xxxxx M=xxx L=xx
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

EDGE 模式下显示层是梯度灰度，所以 `N` / `B` / `C` 实际是 mag ≥ 16 / ≥ 32 / ≥ 64
的像素计数，可直接用来选边缘门限，不必只靠肉眼看画面。

读取日志：

```powershell
.\tools\read_debug_uart.ps1 -Port COM3
```

脚本会同时打印到终端并追加写入 `debug_uart.log`。

## 8. 仓库与提交

- GitHub：`git@github.com:hardcore-noob/anlogic_competition.git`
- 默认分支：`main`
- 提交身份：`hardcore-noob`（仓库本地已配置）

构建产物、TD Run 目录、bitstream 和日志默认由 `.gitignore` 排除，不纳入版本库。

## 9. 当前已知风险

- 边缘实现已改为全分辨率梯度 + 灰度输出，画面与官方例程不同；
- 新边缘实现目前只有数值推导和编译验证，**尚未做整幅边缘图对比和上板确认**；
- 官方和整合版都没有完整的 ready/backpressure 闭环，DDR 或 FIFO 拥塞时
  需要重点检查数据是否被丢弃；
- 官方参考路径的 Setup 负余量在本分支已消失（final Setup WNS +158 ps、0 违例，
  基线为 -8466 ps / 1549 违例），但余量很薄，继续加功能后必须重新确认；
- 灰度公式的 8 位回绕（亮度压缩在 0..85）仍未修，幅度只有理论值的 1/3。
