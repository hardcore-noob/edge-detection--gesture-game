# SALPHOENIX®1P 系列 FPGA 数据手册

> 本文档由原 PDF `DS1300_PH1P_Datasheet.pdf`（DS_1300 v1.2，2025 年 08 月）提取整理，
> 用于快速检索。原文档中的架构图、波形图和部分图示未复制到 Markdown；
> 封装规格图纸已渲染并嵌入本文；其他图示请按标注的“原 PDF 页码”查阅原文件。
>
> 整理日期：2026-09-08

## 文档信息

| 项目 | 内容 |
| --- | --- |
| 文档名称 | SALPHOENIX®1P 系列 FPGA 数据手册 |
| 文档编号 | DS_1300 |
| 版本 | v1.2 |
| 发布年月 | 2025 年 08 月 |
| 厂商 | 上海安路信息科技股份有限公司 |
| 原 PDF 页数 | 186 页 |
| 适用器件 | PH1P100、PH1P35 系列 |

## 重要版本备注

本版（v1.2，2025/08/29）主要变更：

- PH1P35MEG324 器件首次发布正式版。
- 表 1-2 新增 Integrated Memory Interface 的 Capacity 规格。
- 更新第 5 章订购信息中的速度等级。
- 更新表 3-41 最大时钟操作频率中的 IOCLK 和 MLCLK 性能。
- 表 2-2 新增 PLL 小数分频精度说明。
- 删除表 2-5 配置模式及对应位宽的注释 1。

## 原文档目录

> 页码为原 PDF 页码；封面为第 1 页，目录页为第 2-6 页。

- 1 简介（第 7 页）
  - 1.1 SALPHOENIX®1P（以下简称PH1P）系列器件特性（第 7 页）
  - 1.2 PH1P器件介绍（第 14 页）
- 2 PH1P架构介绍（第 15 页）
  - 2.1 可编程逻辑资源（第 16 页）
    - 2.1.1 PLB结构（第 17 页）
  - 2.2 嵌入式存储器模块（ERAM）（第 18 页）
    - 2.2.1 ERAM SLICE 架构（第 18 页）
    - 2.2.2 ERAM20K 功能（第 18 页）
  - 2.3 时钟资源（第 21 页）
  - 2.4 PLL和CLOCK ALIGNER（第 23 页）
    - 2.4.1 PLL（第 23 页）
    - 2.4.2 CLOCK ALIGNER（第 25 页）
  - 2.5 数字信号处理（DSP）（第 26 页）
  - 2.6 HXT(串行器/解串器)与PCI Express控制器（第 27 页）
    - 2.6.1 HXT结构和支持的高速协议（第 28 页）
    - 2.6.2 HXT功能特性（第 28 页）
    - 2.6.3 PCI Express控制器内部结构和特性（第 30 页）
  - 2.7 输入输出缓冲器（IOB）（第 31 页）
  - 2.8 配置说明（第 34 页）
    - 2.8.1 配置模式（第 34 页）
    - 2.8.2 FPGA I/O 引脚在配置阶段的状态（第 34 页）
    - 2.8.3 串行配置模式（第 36 页）
    - 2.8.4 主动SPI配置模式（第 38 页）
    - 2.8.5 并行配置模式（第 41 页）
    - 2.8.6 JTAG配置模式（第 42 页）
  - 2.9 SEU检错和纠错模块（第 44 页）
  - 2.10 电压温度检测模块（第 44 页）
  - 2.11 External Memory Interface（第 45 页）
  - 2.12 Integrated Memory Interface（第 45 页）
  - 2.13 MIPI DPHY（第 46 页）
    - 2.13.1 功能特性（第 46 页）
    - 2.13.2 模块功能描述（第 46 页）
  - 2.14 MCU（第 49 页）
    - 2.14.1 功能特性（第 49 页）
    - 2.14.2 模块功能描述（第 49 页）
- 3 直流交流特性（第 51 页）
  - 3.1 直流电气特性（第 51 页）
    - 3.1.1 最大绝对额定值（第 51 页）
    - 3.1.2 推荐基本操作条件（第 55 页）
    - 3.1.3 IO BANK基本供电要求（第 57 页）
    - 3.1.4 器件静态供电电流（第 61 页）
    - 3.1.5 上下电时序（第 62 页）
    - 3.1.6 I/O管脚电容（第 63 页）
    - 3.1.7 热插拔规格（第 63 页）
    - 3.1.8 I/O直流电气特性（第 64 页）
    - 3.1.9 单端I/O直流电学特性（第 66 页）
    - 3.1.10 差分I/O电学特性（第 69 页）
      - 3.1.10.1 LVDS（第 69 页）
      - 3.1.10.2 SUB_LVDS（第 70 页）
      - 3.1.10.3 MINI_LVDS（第 70 页）
      - 3.1.10.4 TMDS33（第 71 页）
      - 3.1.10.5 POD12（第 71 页）
      - 3.1.10.6 LVDS_E（第 72 页）
      - 3.1.10.7 其他（第 73 页）
    - 3.1.11 MIPI（第 74 页）
      - 3.1.11.1 MIPI RX（第 74 页）
      - 3.1.11.2 MIPI TX（第 75 页）
  - 3.2 交流电气特性（第 76 页）
    - 3.2.1 时钟性能（第 76 页）
    - 3.2.2 嵌入数字信号处理模块（DSP）规格（第 76 页）
    - 3.2.3 存储器模块（ERAM）规格（第 77 页）
    - 3.2.4 锁相环(PLL)规格（第 77 页）
    - 3.2.5 CLOCK ALIGNER规格（第 79 页）
    - 3.2.6 TVS指标（第 80 页）
    - 3.2.7 I/O接口性能（第 80 页）
      - 3.2.7.1 HR I/O（第 80 页）
      - 3.2.7.2 HD I/O（第 82 页）
      - 3.2.7.3 DDR I/O（第 83 页）
      - 3.2.7.4 MIPI I/O（第 84 页）
    - 3.2.8 配置模块（第 85 页）
    - 3.2.9 External Memory Interface（第 86 页）
    - 3.2.10 Integrated Memory Interface（第 86 页）
    - 3.2.11 MIPI（第 86 页）
      - 3.2.11.1 MIPI RX（第 86 页）
      - 3.2.11.2 MIPI TX（第 87 页）
    - 3.2.12 MCU（第 87 页）
  - 3.3 HXT串行收发器直流交流特性和规格（第 88 页）
    - 3.3.1 HXT串行收发器的直流参数（第 88 页）
    - 3.3.2 HXT串行收发器的交流参数（第 89 页）
    - 3.3.3 HXT串行收发器APB接口时钟性能（第 89 页）
    - 3.3.4 HXT串行收发器PLL和CDR性能（第 89 页）
    - 3.3.5 HXT串行收发器的用户时钟交流特性（第 90 页）
    - 3.3.6 HXT发送器的交流特性（第 90 页）
    - 3.3.7 HXT接收器的交流特性（第 91 页）
    - 3.3.8 HXT串行收发器参考时钟性能（第 92 页）
    - 3.3.9 PCI Express控制器输入时钟频率要求（第 93 页）
- 4 引脚和封装（第 94 页）
  - 4.1 IO 命名规则（第 94 页）
  - 4.2 引脚定义和规则（第 95 页）
  - 4.3 PH1P100SBG676引脚信息（第 100 页）
  - 4.4 PH1P100SBG677引脚信息（第 112 页）
  - 4.5 PH1P100SBG484引脚信息（第 127 页）
  - 4.6 PH1P100GEG324引脚信息（第 137 页）
  - 4.7 PH1P35MBG484引脚信息（第 145 页）
  - 4.8 PH1P35MDG324/PH1P35MHG324引脚信息（第 157 页）
  - 4.9 PH1P35MEG324/PH1P35MEG324A引脚信息（第 165 页）
  - 4.10 封装信息（第 173 页）
    - 4.10.1 PH1P100SBG676/PH1P100SBG677封装规格（第 173 页）
    - 4.10.2 PH1P35MBG484封装规格（第 174 页）
    - 4.10.3 PH1P35MDG324/PH1P35MHG324封装规格（第 175 页）
    - 4.10.4 PH1P35MEG324/PH1P35MEG324A封装规格（第 176 页）
    - 4.10.5 PH1P100SBG484封装规格（第 177 页）
    - 4.10.6 PH1P100GEG324封装规格（第 178 页）
- 5 订购信息（第 179 页）
- 版本信息（第 182 页）
- 免责声明（第 186 页）

---

<!-- 原 PDF 第 1 页 -->

SALPHOENIX®1P 系列 FPGA
数据手册
上海安路信息科技股份有限公司
DS_1300（v1.2）2025 年08 月

<!-- 原 PDF 第 7 页 -->

## 1 简介
### 1.1 SALPHOENIX®1P（以下简称PH1P）系列器件特性
 可配置逻辑模块
 自主高效的双LUT5 结构
 双端口分布式存储器
 支持算术逻辑运算
 快速进位链逻辑
 专用移位寄存器
 分布式和嵌入式存储器
 嵌入块存储器容量为20Kbits
 简单双口模式支持位宽16K*1 到512*40
 真双口模式支持位宽16K*1 到1K*20
 支持ECC 模式
 专用FIFO 控制逻辑
 分布式存储器支持64*8 和32*16 两种模
式配置
 高性能数据信号处理器
 可支持两输入预加器、 三输入加法器、乘
法器和算术逻辑单元
 扩展功能： 多位宽运算， 级联快速互连实
现宽位宽的加法、乘法、逻辑运算
 源同步输入/输出接口
 HR I /O 支持 SERDESx1 、SERDESx2 、
SERDESx3.5、SERDESx4、SERDESx5、DDRx1、
DDRx2
 HD I/O 支持DDRx1
 DDR I/O 支持 SERDESx1、SERDESx2、
SERDESx3.5、SERDESx4、SERDESx5、DDRx1、
DDRx2
 高性能，灵活的输入/输出缓冲器
 可配置支持以下单端标准
HR I/O BANK
– LVTTL33
– LVCMOS(3.3/2.5/1.8/1.5/1.2V)
– HSTL_I(1.8/1.5V)
– HSUL12
– SSTL18_I(1.8V)
– SSTL(1.5/1.35/1.2V)
– SSTL15_R
– POD12
HD I/O BANK
– LVCMOS(3.3/2.5/1.8/1.5V)
– LVTTL33
DDR I/O BANK
– LVCMOS(1.8/1.5/1.2V)
– HSTL_I(1.8/1.5V)
– SSTL18_I
– SSTL(1.5/1.35/1.2V)
– SSTL15_R
– POD12
– HSUL12

<!-- 原 PDF 第 8 页 -->

 可配置支持以下差分标准
HR I/O BANK
– LVDS（2.5/1.8V）
– SUB_LVDS（1.8V）
– MINI_LVDS（2.5V）
– DIFF_HSTL_I(1.8/1.5V)
– DIFF_HSUL12
– DIFF_SSTL18_I(1.8V)
– DIFF_SSTL(1.5/1.35/1.2V)
– DIFF_SSTL15_R
– DIFF_POD12
– TMDS33
– LVDS33 只支持输入
– LVDS33_E、LVDS25_E、LVDS18_E
HD I/O BANK
– LVDS33_E、LVDS25_E、LVDS18_E
DDR I/O BANK
– DIFF_HSTL_I(1.8/1.5V)
– DIFF_SSTL18_I
– DIFF_SSTL(1.5/1.35/1.2V)
– DIFF_SSTL15_R
– DIFF_POD12
– DIFF_HSUL12
– 只支持LVDS18 输入
– LVDS18_E
 HR I/O 支持True LVDS 输出和输入，支
持差分输入带片内100 欧姆端接电阻
 HR I/O 支持热插拔功能
 可配置弱上拉/下拉模式
 时钟资源
 提供高效灵活的层次化时钟
– 32 路全局时钟网络（GCLK）驱动全
局
– 多区域时钟 （MLCLK） 驱动相邻区域
– 区域时钟（LCLK）驱动本区域
– I/O 时钟（IOCLK）为高速I/O 接口
提供高性能时钟
 支持PLL 用于频率相位合成
– 单个支持 7 路时钟输出（支持取反
输出）
– 占空比调整
– 相位调整
– 支持小数分频
– 动态相位调整
– 动态配置
– 时钟展频（SSC）
– CLOCK ALIGNER 支持相位对齐
 ADC
 支持12-bit,1MSPS 的模数转换
 支持内部/外部参考电压
 支持单端/差分
 支持多路输入
 配置模式
 从动串行（Slave Serial）
 主动串行（Master Serial）

<!-- 原 PDF 第 9 页 -->

 主动SPI x1/x2/x4
 主动并行x8/x16（Master Parallel）
 从动并行x8/x16/x32 (Slave Parallel)
 JTAG 模式
 HXT
 多达8 通道的高速串行收发器
 集成一个 PCI Express 的硬核，支持
GEN1/2/3，支持X1、X2 和X4 模式
 支持 1000BASE-KZ 、 10GBASE-KX4 、
1000BASE-KR 、10GBASE-KR4 、SGMII 、
QSGMII、XAUI、RXAUI、CEI、CPRI、OBSAI、
JESD204 A/B、SRIO 等多种协议
 MIPI DPHY
 2 组 MIPI DPHY ，每组最大支持 1 clk
Lane + 4 data Lane 模式
 TX 内置专用PLL
 MIPI 模式不使用时，IO 可支持为其他电
平：LVDS 或LVCMOS
RX 特性
 内嵌HS_RX、LS_RX、LP_TX
 HS_RX 主要支持 MIPI D-PHY HS 模式，
支持LVDS
 HS_RX 支持1：8、1：16 的串并转换
 LS_RX 主要支持 MIPI D-PHY LP 模式，
支持LVCMOS18、LVCMOS12
 内嵌LP_TX 主要支持MIPI D-PHY LP 反
向传输模式
 支持动态skew 调节、 自动skew 校准 （HS
RX）
TX 特性
 内嵌HS_TX、LS_TX、LP_RX
 HS_TX 主要支持 MIPI D-PHY HS 模式，
支持LVDS18 电平
 HS_TX 支持8：1、16：1 的并串转换
 LS_TX 主要支持 MIPI D-PHY LP 模式,
支持LVCMOS18
 内嵌LP_RX 主要支持MIPI D-PHY LP 反
向传输模式
 RISC-V MCU 硬核
 支持RV32 I/M/A/F/C/P/B 指令集
 三级流水设计
 32KB ICache,32KB DCache,16KB DLM
 支持JTAG 调试
 支持快速中断响应和定时器
 通用外设QSPI0/1、UART0/1、GPIOx8、
I2C
 支持DMA
 支持AHB 和APB 总线与FPGA 逻辑进行通
信访问
 External Memory Interface
 支持DDR2/3/4 存储接口
 最大支持72-bit DQ
 Integrated Memory Interface
 支持高速存储接口
 内置电压温度检测模块
 集成高精度电压温度检测模块，支持电
压和温度的实时监测

<!-- 原 PDF 第 10 页 -->

 BSCAN
 兼容IEEE-1149.1
 增强的安全设计保护
 每个芯片拥有唯一的64 位DNA
 SEU 检错和纠错
 支持单bit 检错和纠错
 支持双bit 检错
 支持单bit 和双bit 错误注入
 多种封装形式
 SBG676  27mm x 27mm, 1mm pitch
 SBG677  27mm x 27mm, 1mm pitch
 MBG484  23mm x 23mm, 1mm pitch
 MDG324  15mm x 15mm, 0.8mm pitch
 MHG324  15mm x 15mm, 0.8mm pitch
 SBG484  23mm x 23mm, 1mm pitch
 MEG324  15mm x 15mm, 0.8mm pitch
 GEG324  15mm x 15mm, 0.8mm pitch

<!-- 原 PDF 第 11 页 -->

表 1-1 PH1P FPGA 系列选型表
Device
PH1P100 PH1P35
PH1P100SBG676、
PH1P100SBG677、
PH1P100SBG484、
PH1P100GEG324
PH1P35MBG484、
PH1P35MDG324、
PH1P35MHG324、
PH1P35MEG324、
PH1P35MEG324A
LUT4s 129,024 38,189
DFFs 143,360 42,432
Dis-RAM（Kbits） 1600 507
ERAM
20K 300 108
Total
(Kbits)
6,000 2,160
DSP 220 40
PLL 12 6
TVS 1 1
ADC - -
MCU - 1
MIPI DPHY - 2

<!-- 原 PDF 第 12 页 -->

表 1-2 PH1P FPGA 封装
Device
PH1P100 PH1P35
PH1P100
SBG676
PH1P100
SBG677
PH1P100
SBG484
PH1P100
GEG324
PH1P35
MBG484
PH1P35
MDG324
PH1P35
MHG324
PH1P35
MEG324A
PH1P35
MEG324
Package
Type SBG676 SBG677 SBG484 GEG324 MBG484 MDG324 MHG324 MEG324 MEG324
Size
（mm）
27x27 27x27 23x23 15x15 23x23 15x15 15x15 15x15 15x15
Pitch
（mm）
1.0 1.0 1.0 0.8 1.0 0.8 0.8 0.8 0.8
External Memory
Interface
DDR2
（Mbps）
- - - - 800 800 800 800 800
DDR3
（Mbps）
800 800 800 800 800 800 800 800 800
DDR4
（Mbps）
800 800 800 800 800 800 800 800 800
Max DQ Width
4
x72 x72 x72 x48 x48
5
x16 x16 x16 x16
Integrated Memory
Interface
Speed
（Mbps）
- - - - - 1066 1066 - -
DQ Width - - - - - x16 x16 - -
Capacity
(Mb)
- - - - - 512 1024 - -
PCIe
Speed GEN1/2 GEN1/2 GEN1/2 - - - - - -
Channels 4 4 4 - - - - - -
HXT Channels 8 8 4 - - - - - -

<!-- 原 PDF 第 13 页 -->

Device
PH1P100 PH1P35
PH1P100
SBG676
PH1P100
SBG677
PH1P100
SBG484
PH1P100
GEG324
PH1P35
MBG484
PH1P35
MDG324
PH1P35
MHG324
PH1P35
MEG324A
PH1P35
MEG324
Max Data rate
（Gbps）
10.3125 10.3125 10.3125 - - - - - -
I/O
2
Total 301 301 286 211 311 180 180 217 217
(HR
3
/
HD/
DDR/
MIPI)
301(144)
1
/0
/0
/0
301(144)
/0
/0
/0
286(137)
/0
/0
/0
211(100)
/0
/0
/0
50(24)
/141
/100(48)
/20(10)
50(24)
/106
/4(2)
/20(10)
50(24)
/106
/4(2)
/20(10)
50(24)/
97/
50(24)/
20(10)
50(24)/
97/
50(24)/
20(10)
注：
300（144）表示示：用户可用I/O 数量（用户可用真差分对数量）。
PH1P 系列配置管脚CCLK 进入用户模式后可复用为普通 I/O，仅支持LVCMOS 电平，但不支持ISERDES、OSERDES、IDDR、ODDR 功能,I/O Total 数量包
括该引脚。使用MCU 模块，CCLK 不能复用为普通I/O。
所有HR I/O 都支持DDR 功能。
指一个DDR 接口支持的最大DQ 位宽，不同器件根据I/O 数量可支持多个DDR 接口
支持最大48bit 大带宽需求时，请联系安路技术支持工程师。

<!-- 原 PDF 第 14 页 -->

### 1.2 PH1P器件介绍
随着科技的发展， 现有的数字产品已经不能满足人们在通信基础设施、 医疗电子、 工业控制等行业
的需求，设计出更高的处理带宽，更广的应用范围、更低的使用功耗的芯片成为芯片厂商的追求。
安路科技PH1P 系列FPGA 采用先进工艺、包含丰富的逻辑单元、高速串行的I/O、丰富的存储资源
和 IP 资源，定位低成本、高性能可编程逻辑市场。
针对高带宽应用场景，PH1P 能够在保持低功耗的前提下， 提供同类最佳的收发器和信号处理功能。
PH1P 能够满足通信基础设施、 医疗、 工业、 消费电子等尺寸、 重量、 功耗和成本敏感型市场， 给开发人
员提供更优的解决方案。
安路科技提供丰富的设计工具帮助用户有效地利用PH1P 平台实现复杂设计。业界领先的综合和布
局布线工具， 同时提供各种IP 资源， 方便用户直接调用调试， 解决了复杂逻辑带来的资源不足的问题，
为用户设计高质量产品提供有力保障。

<!-- 原 PDF 第 15 页 -->

## 2 PH1P架构介绍
PH1P 系列 FPGA 底层由I/O、PLL、ERAM、DSP、PLB、HXT、PCIe 等模块构成，器件具体架构如下图
所示。
HRIO
HRIO
HRIO
PLLPLL
PLL
PLB,
ERAM,
DSP,
CONFIG
HXT Quad
HXT Quad
PLB,
ERAM,
DSP
PCIE
图 2-1 PH1P100 器件架构图
DDR
IO
HRIO
PLL
PLL
PLB,
ERAM,
DSP
MCU
PLB,
ERAM,
DSP
HDIO
HDIO
MIPI
MIPI
CONIFG
HDIO
HDIO
DDR
IO
PLL
图 2-2 PH1P35 器件架构图

<!-- 原 PDF 第 16 页 -->

### 2.1 可编程逻辑资源
PH1P 系列 FPGA 中提供了高性能的Programmable Logic Block(PLB，可编程逻辑块)结构，主要特
点如下：
 可实现互连的双LUT5 或独立的双LUT4 功能
 可实现分布式存储器
 专用的移位寄存器资源
 先进的全加器和进位链结构
 灵活的组合拼接扩展功能

<!-- 原 PDF 第 17 页 -->

#### 2.1.1 PLB结构
可编程逻辑阵列如下图所示， 主要有PLB、PMB 和 IP 三类模块。PLB（Programmable Logic Block，
可编程逻辑块)和PMB（Programmable Multi-Function Block，可编程多功能块)带有可编程逻辑功能，
IP 具有特定功能，比如：DSP，BRAM 等硬件模块。
RSB RSB RSBRSBRSB
PMB
RSB
IP
PLB
RSB RSB RSBRSBPFURSBRSB
RSB RSB RSBRSBRSBRSB
RSB RSB RSBRSBRSBRSB
IP
PFU
PFU
PFU
PFU
PFU
PFU
PFU
PFU
PFU
PFU
PFU
PMU
PMU
PMU
PMU
图 2-3 可编程逻辑阵列单元示意图
PLB 包括RSB（Routing Switch Block， 可编程互连单元） 和PFU（Programmable Functional Unit，
可编程功能单元)；PMB 包括RSB 和PMU（Programmable Memory Unit，可编程功能/存储单元)。
RSB 包含单元间的连线以及互连单元。以实现可编程的连接关系，RSB 只负责实现逻辑单元之间的
信号传输，以及逻辑单元和内嵌其它IP 单元的连接，不带有逻辑功能。
PFU 负责实现用户逻辑中的各种组合/时序功能。包含有查找表、加法器逻辑和DFF。
PMU 除能够实现所有的PFU 功能外，还可以实现额外的分布式RAM 功能/移位器功能。

<!-- 原 PDF 第 18 页 -->

### 2.2 嵌入式存储器模块（ERAM）
#### 2.2.1 ERAM SLICE 架构
PH1P 系列 FPGA， 每个ERAM SLICE包含两个独立的ERAM20K 以及一个FIFO 控制器。每个ERAM SLICE
可实现以下功能：
 2 个ERAM20K
 1 个FIFO20K，1 个 ERAM20K
 1 个FIFO40K（位宽=2～80）
ERAM SLICE 架构如下图所示。
FIFO
控制器
Routing
ERAM20K
ERAM20K
ERAM
addr_casin
addr_casout
图 2-4 ERAM SLICE 架构
#### 2.2.2 ERAM20K 功能
ERAM20K 每块容量20Kbits，可实现：
 单口RAM/ROM
 双口RAM
 简单双口RAM

<!-- 原 PDF 第 19 页 -->

 ERAM SLICE 内嵌有硬件FIFO 控制器，支持实时深度指示
ERAM20K 模块支持的功能特色有：
 A/B 口时钟独立
 可单独配置A/B 口数据位宽，真双口支持x1 到x20，简单双口支持x1 到x40（一写一读）
 写操作时带有字节使能（Byte Enable）控制
 输出寄存器可选择
 支持多模块地址/数据级联
 支持输出复位/置位可配置
 支持RAM/ROM 模式下数据初始化（通过初始化文件在配置过程中对ERAM20K 数据初始化）
 支持多种写操作模式。只写（Write Disable Read），先读后写（Read Before Write），写穿通
（Write Before Read）三种模式。
 内嵌32 位ECC 校验硬件编解码，支持单bit：纠错、检错和插错，双bit：检错和插错
表 2-1 ERAM20K 特性
类别 特性
容量 20K
配置(深度 x 位宽)
真双口
16K x 1,8K x 2,4K x 5,
2K x 10,1K x 20,512 x 40
（简单双口W40R40 模式，支持ECC）
字节使能（Byte enable）
有且必须
1Kx20 时2 字节独立选择
512x40 时4 字节独立选择
单口模式(Single-port mode) x1,x2,x5,x10,x20,x40(AB 口组合)
简单双口模式(Simple dual-port mode)
支持1～40 位宽
A 口写时钟/写地址
B 口读时钟/读地址
真双口模式(True dual-port mode) x1,x2,x5,x10,x20
ECC 模式
支持32bit 位宽单bit 检错、插错和纠错，双bit 插错
和检错
ROM 模式 支持
FIFO 模式
FIFO 控制器只支持读写相同位宽。
单个 ERAM20K：1/2/5/10/20/40
2 个 ERAM20K 并联：2/4/10/20/40/80

<!-- 原 PDF 第 20 页 -->

类别 特性
同步/异步FIFO 功能 支持标准异步/低延迟同步（读写同一时钟）
数据输出寄存器
1
支持，可选择同步/异步，复位/置位
写模式
写穿通（Write Before Read）
先读后写（Read Before Write）
只写（Write Disable Read）
工作前RAM 初始化 支持(借助B 口20 位模式）
注：
输出复位/置位功能需要配合oce 信号使用才能生效
ERAM 的输入地址和数据需要和输入时钟采用同步设计，否则可能造成ERAM 内容异常翻转

<!-- 原 PDF 第 21 页 -->

### 2.3 时钟资源
PH1P 系列 FPGA 提供了丰富的时钟资源方便客户进行各项复杂的方案设计， 以使得系统性能达到最
优。同时该系列采用多区域的时钟网络架构，通过全局时钟布线资源实现多个区域的时钟互联。
HXT
HXT
16
12
16
12
16
16
12
HXT
16
12
16
12
HXT
12
12
1616
12
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
SCLK
GCLK
32
32
SCLK
SCLK SCLK
SCLK SCLK
SCLK SCLK
HCLK
图 2-5 PH1P100 器件时钟资源示意图
12 12
16
MCU
MIPI DPHY16
GCLK IO
4
12 12
16 16
GCLK IO
4
CLOCK ALIGNER
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
LCLK
GCLK I/O
PLL
SCLK
SCLK SCLK
SCLK
GCLK
HCLK
32
图 2-6 PH1P35 器件时钟资源示意图

<!-- 原 PDF 第 22 页 -->

全局时钟缓冲器（Global Clock Buffer，以下简称BUFG）驱动全局时钟互联网络。BUFG 和全局时
钟缓冲选择器（Global Clock Mux Buffer，以下简称GCLK）同属一种全局时钟资源。
独立时钟缓冲器（Single Clock Buffer，以下简称SCLK），允许通过水平时钟线驱动单个时钟区
域中的全局驱动本地时钟网络。
水平时钟缓冲器（Horizontal Clock Buffer，以下简称HCLK）允许通过水平时钟线驱动两个时钟
区域中的全局驱动本地时钟网络。
PH1P 系列FPGA 器件的每个时钟区域里都有本地时钟缓冲器 （Local Clock Buffer，以下简称LCLK），
和 I/O 时钟缓冲器 （I/O Clock Buffer，以下简称IOCLK） ， 可以在一个时钟区域内驱动所有时序资源。
每个Clock Sector 还具有多区域时钟缓冲器（Multi Local Clock Buffer，以下简称MLCLK），其允
许 LCLK 和IOCLK 驱动的时钟跨越多达三个垂直相邻的时钟区域。

<!-- 原 PDF 第 23 页 -->

### 2.4 PLL和CLOCK ALIGNER
#### 2.4.1 PLL
PH1P 系列 FPGA 内嵌多个多功能锁相环（（Phase Locked Loop，简称PLL），可实现高性能、高精
度的时钟管理功能。 可以实现时钟分频、 倍频、 占空比调整、 反馈模式选择、 输出时钟相位调整等功能。
PLL 参考时钟输入有：时钟网络输出、互连输出和内部振荡器输出。
PLL 反馈时钟输入有：时钟网络输出、全局时钟末端节点、互连输出、PLL 内部反馈时钟以及相移
时钟C0～C6。
PLL 支持7 路输出， 并且每一路输出的相位和占空比都可以调节， 同时输出支持单端输出和取反输
出。用户在使用中应关注PLL 的 lock 信号是否为高，同时建议用户等待输入信号稳定后，再给锁相环
进行复位以保证锁相环输出时钟信号的频率和相位稳定。
fbclk
PFD CP LPF VCO
LDO
÷N
÷M
Dynamic
phase
shift
SDM
LOCK
Detector
LOCK
SSC
PHASE
Shift
refclk C0
(Fractional
Divide)
C1
C2
C3
C4
C5
C6
VCO_PHASE
CLK0~6_INT
CLKOUT0_T
CLKOUT0_C
CLKOUT1_C
CLKOUT2_T
CLKOUT2_C
CLKOUT3_T
CLKOUT3_C
CLKOUT4_T
CLKOUT4_C
CLKOUT5_T
CLKOUT5_C
CLKOUT6_T
CLKOUT6_C
CLK0_INT
CLK1_INT
CLK2_INT
CLK3_INT
CLK4_INT
CLK5_INT
CLK6_INT
C0:1/128 Dynamic phase shift
C1~C6:1/8 Dynamic phase shift
CLKOUT1_T
CLK0~6_EXT
图 2-7  PH1P 系列 PLL 架构图

<!-- 原 PDF 第 24 页 -->

表 2-2 PLL 特性
Feature PH1P PLL
时钟输出端口数 7（支持取反输出）
参考时钟分频系数(N) 1 to 128
反馈时钟分频系数(M)
1，2
1 to 128
输出时钟分频系数(C0-C6) 1 to 128
动态相位调整 支持（粗调节和细调节）
锁定状态输出 Lock
带宽 HIGH、LOW
占空比调整 支持
小数分频 支持（CO 和反馈通路小数分频）
展频（SSC） 支持
动态配置 支持
注：
PH1P100 器件小数分频模式下反馈通路分频系数支持范围为16-126, PH1P35 器件小数分频模式下
反馈通路分频系数支持范围为5-126。
SSC 模式下反馈通路分频系数支持范围为28-56。
PH1P100 器件小数分频精度为24bit，PH1P35 器件小数分频精度为28bit。

<!-- 原 PDF 第 25 页 -->

#### 2.4.2 CLOCK ALIGNER
PH1P35 器件包含两个CLOCK ALIGNER，PH1P100 器件不支持CLOCK ALIGNER。
CLOCK ALIGNER 模块用于对齐参考时钟和该时钟经过全局时钟网络后两时钟之间的相位差，直至节
点 1 和2 处相位一致。CLOCK ALIGNER 模块时钟校准结构图如下图所示：
PFD
clk_out
fbclk
refclk
BUFG
1
2
2
CLOCK ALIGNER
Lock
Detect
lock
VCO POST-DIV
图 2-8 CLOCK ALIGNER 模块时钟校准结构
PH1P 系列器件CLOCK ALIGNER 的具体特性如下表示。
表 2-3 CLOCK ALIGNER 特性
特性 CLOCK ALIGNER
输出分频系数 1/2/4/8/16/32/64/128
锁定状态输出 支持
相位对齐 支持

<!-- 原 PDF 第 26 页 -->

### 2.5 数字信号处理（DSP）
数字信号处理中将使用大量的加法、 乘法和累加运算，相较于采用LUT 单元实现这些功能，PH1P 系
列器件的内嵌DSP 单元将带来更低的运算延迟。
PH1P 系列器件中的 DSP 按列分布，采用微型总线式架构，包含 5 大处理单元：两输入预加器、乘
法器、三输入加减器、逻辑运算单元和信号输入输出总线单元。
 支持两输入27-bit 预加运算；
 支持三输入带进位54-bit 加减运算；
 支持将三输入54-bit 加减器拆分为两个27-bit 加减器；
 三输入加减器支持rounding；
 支持对输出p 进行17-bit 算术右移操作；
 支持OVERFLOW 和UNDERFLOW；
 支持cci 和cco 进位级联；
 xa 和 xb 支持向上或向下级联输入及输出，y 支持向上级联输入及输出；
 支持27x18-bit 乘法器（有符号的二进制补码）；
 支持将27x18 乘法器拆分成2 个可支持有符号/无符号的9x9 乘法器。 （注： 仅PH1P35 器件支持此
功能）；
 乘法器支持平方操作；
 支持54-bit 按位逻辑操作，包括 AND、NAND、OR、NOR、XOR、XNOR 和NOT；
 支持宽位异或操作，单个DSP 最多可实现108-bit XOR 操作或拆分为两个54-bit XOR 操作；
 支持对输入信号进行一级或两级寄存；
 支持对输入信号进行动态选择切换。

<!-- 原 PDF 第 27 页 -->

### 2.6 HXT(串行器/解串器)与PCI Express控制器
PH1P 系列 FPGA 内置了高速串行收发器（High Speed Transceiver ，简称 HXT)），其中每个HXT
QUAD 包含4 路 HXT 收发器。
PH1P35 器件不支持HXT。
PH1P100 器件的HXT 资源示意如下图所示。
PH1P_HXT Quad
坐标：x69y120z0
PH1P_HXT Quad
坐标：x75y0z0
用户逻辑
Bank 94
Bank 91
PCIe X4 PHY1
坐标：x69y120z0
图 2-9 PH1P100(SBG676 封装)和 PH1P100(SBG677 封装)器件 HXT 资源示意图

<!-- 原 PDF 第 28 页 -->

PH1P_HXT Quad
坐标：x69y120z0
用户逻辑
Bank 94PCIe X4 PHY1
坐标：x69y120z0
图 2-10 PH1P100(SBG484 封装)器件 HXT 资源示意图
#### 2.6.1 HXT结构和支持的高速协议
PH1P 系列器件HXT 内部结构及支持的高速协议详见《UG1309_安路科技PH1P 系列 FPGA HXT用户手
册》。
#### 2.6.2 HXT功能特性
PH1P 系列器件HXT 主要功能特性如下表。
表 2-4 HXT 特性
功能 PH1P 器件
Common
参考时钟
专用差分参考时钟输入:每个 Quad 有 2 对，同
时支持内部端接匹配电阻
用户逻辑单端参考时钟输入:每个Quad 有 2 个
恢复时钟输出 支持
Common PLL 支持
寄存器读写接口 APB4
环回控制
近端 PCS 并行环回NECP
远端 PCS 并行环回FECP
近端 PMA 串行环回NEMS

<!-- 原 PDF 第 29 页 -->

功能 PH1P 器件
远端 PMA 并行环回FEMP
收发器通道数量 4 路/Quad
PCS
用户位宽 支持 16、20、32、40、64、80 位宽
Bit 反序 支持
Byte 反序 支持
64B/67B Sync Gearbox 支持 16、32、64 用户位宽
64B/66B Sync Gearbox 支持 16、32、64 用户位宽
8B/10B Encoder/8B/10B Decoder 支持 16、32 用户接口位宽
PCS PRBS GEN/VER PCS PRBS,自定义数据码型最大支持40bit 位宽
Word Aligner 支持
Rate Match FIFO 支持
DPLL 支持
C16 PRBS Gen and Ver 内部 PMA-PCS 接口PRBS，可在任意用户位宽下
使用，有效位宽为16bit
PMA
线速率
支持 500Mb/s～10.3125 Gb/s 线速率连续无断
点
Lane PLL 支持
TX pre-emphasis FIR 支持 3 TAP
CTLE 支持
DFE 支持

<!-- 原 PDF 第 30 页 -->

#### 2.6.3 PCI Express控制器内部结构和特性
PH1P 系列 FPGA 内部集成1 个 PCI Express（简称PCIe）控制器硬核，可提供高带宽、可配置和高
可靠性的PCI Express 互联。
PH1P100SBG676、PH1P100SBG677 和 PH1P100SBG484 器件的 PCIe 控制器单个 Lane 最高线速率是
5Gb/s。
PH1P 系列 FPGA PCIe 可配置成 1-Lane（X1）、2-Lane（X2）或 4-Lane（X4）的 PCI Express
Endpoint(EP)；也可配置成1-Lane（X1）、2-Lane（X2）和4-Lane（X4）的PCI Express Root Complex(RC)。
PH1P100 器件资源示意图如图 2-9 PH1P100(SBG676 封装)和 PH1P100(SBG677 封装)器件HXT 资源
示意图和图 2-10 PH1P100(SBG484 封装)器件HXT 资源示意图。它通过PIPE 接口连接HXT。PCIe 控制
器位于x69y120z0，连接HXT QUAD x69y120z0，最大PCIe 链路位宽为X4，管脚对应Bank94。
PH1P 系列器件PCIe 控制器内部结构及支持协议参见《UG1313_安路科技PH1P 系列FPGA PCIE 用户
手册》，PCIe 控制器支持以下功能：
PH1P 系列器件PCIe 控制器的通用功能如下：
 支持PCI Express Base Specification Revision 4.0 v1.0
 支持PHY Interface for PCI Express (PIPE) 4.4.1
 支持X1,X2,X4 位宽可选
 单个Lane 速率支持2.5Gb/s，5.0Gb/s
 支持Rootport，Endpoint 或者Legacy Endpoint
 至多1 个Virtual Channel (VC)
 至多2 个PF 与4 个VF
 支持Advanced Error Reporting (AER)
 支持ECRC generation and check
 支持用户时钟(集成跨时钟域，在应用层支持用户选择的频率)
 支持Lane reversal

<!-- 原 PDF 第 31 页 -->

### 2.7 输入输出缓冲器（IOB）
PH1P系列FPGA具有可配置、高性能的I/O驱动器和接收器，可支持丰富的标准输入输出接口,并且
支持热插拔功能。
PH1P100只支持HR I/O类型。
PH1P35支持HR I/O，HD I/O和DDR I/O三种类型，其中DDR I/O 可复用为普通HR I/O。
HR I/O BANK 支持的电平标准：
 单端 I/O 标准输出（LVCMOS33、LVCMOS25、LVCMOS18、LVCMOS15、LVCMOS12、LVTTL33、HSUL12、
HSTL18_I、HSTL_I、SSTL18_I、SSTL15、SSTL135、SSTL12、SSTL15_R、POD12）
 单端 I/O 标准输入（LVCMOS33、LVCMOS25、LVCMOS18、LVCMOS15、LVCMOS12、LVTTL33、HSUL12、
HSTL18_I、HSTL_I、SSTL18_I、SSTL15、SSTL135、SSTL12、SSTL15_R、POD12）
 差分 I/O 标准输出（LVDS33_E、LVDS25_E、LVDS18_E、LVDS25、LVDS18、SUB_LVDS、MINI_LVDS、
DIFF_HSUL12、DIFF_HSTL18_I、DIFF_HSTL_I、DIFF_SSTL18_I、DIFF_SSTL15、DIFF_SSTL135、
DIFF_SSTL12、DIFF_SSTL15_R、DIFF_POD12、TMDS33）
 差分I/O 标准输入 （LVDS33、LVDS25、LVDS18、SUB_LVDS、MINI_LVDS、DIFF_HSUL12、DIFF_HSTL18_I、
DIFF_HSTL_I、DIFF_SSTL18_I、DIFF_SSTL15、DIFF_SSTL135、DIFF_SSTL12、DIFF_SSTL15_R、
DIFF_POD12、TMDS33）
HR I/O BANK 支持上述电平标准的同时，HR 支持以下配置项：
 输出驱动能力调节
 输出Slew Rate 调节
 输入迟滞使能
 内部/外部VREF 电压配置
 支持静态ODT
 弱上拉/弱下拉/KEEPER 选择配置
 PRE_EMPHASIS(预加重)
HD I/O BANK 支持的电平标准：
 单端 I/O 标准输出（LVCMOS33、LVCMOS25、LVCMOS18、LVCMOS15、LVTTL33）
 单端 I/O 标准输入（LVCMOS33、LVCMOS25、LVCMOS18、LVCMOS15、LVTTL33）
 差分 I/O 标准输出（LVDS33_E、LVDS25_E、LVDS18_E）
HD I/O BANK 持上述电平标准的同时，HD 支持以下配置项：

<!-- 原 PDF 第 32 页 -->

 输出驱动能力调节
 输出Slew Rate 调节
 弱上拉/弱下拉/KEEPER 选择配置
 输入迟滞
DDR I/O BANK 复用为普通I/O 时支持的电平标准：
 单端 I/O 标准输出（LVCMOS18、LVCMOS15、LVCMOS12、HSUL12、HSTL18_I、HSTL_I、SSTL18_I、
SSTL15、SSTL15_R、SSTL135、SSTL12、POD12）
 单端 I/O 标准输入（LVCMOS18、LVCMOS15、LVCMOS12、HSUL12、HSTL18_I、HSTL_I、SSTL18_I、
SSTL15、SSTL15_R、SSTL135、SSTL12、POD12）
 差分 I/O 标准输出（LVDS18_E、DIFF_HSUL12、DIFF_HSTL18_I、DIFF_HSTL_I、DIFF_SSTL18_I、
DIFF_SSTL15、DIFF_SSTL15_R、DIFF_SSTL135、DIFF_SSTL12、DIFF_POD12）
 差分 I/O 标准输入（LVDS18、DIFF_HSUL12、DIFF_HSTL18_I、DIFF_HSTL_I、DIFF_SSTL18_I、
DIFF_SSTL15、DIFF_SSTL15_R、DIFF_SSTL135、DIFF_SSTL12、DIFF_POD12）
DDR I/O BANK 复用为普通I/O 时支持上述电平标准的同时，支持以下配置项：
 输出驱动能力调节
 输出Slew Rate 调节
 输入迟滞使能
 内部/外部VREF 电压配置
 支持静态ODT
 弱上拉/弱下拉/KEEPER 选择配置
注：
对于HR I/O 差分输入，I/O 支持LVDS33、LVDS25、LVDS18、SUB_LVDS 和MINI_LVDS 信号输入而且
对差分和共模信号范围有明确要求。对外部电路发送来的LVDS33、LVDS25、LVDS18、SUB_LVDS 和
MINI_LVDS 信号， 需要检查信号共模和差分信号有没有超出I/O 输入范围。 如果超过I/O 输入范围，
必须要使用板级电阻电容网络调节差分和共模电平以满足 I/O 信号范围要求，具体参数请参照交
直流参数章节。超出I/O 规定的共模和差分范围会导致I/O 工作不正常甚至损坏芯片。
HR I/O LVCMOS12 不支持输入迟滞；
DDR I/O 复用为普通HR I/O 时LVCMOS12 支持输入迟滞。
HD I/O 和 DDR I/O 不支持热插拔。
PH1P 系列器件的HR IO、DDR IO LVDS_E 类型的电平支持输出 （TX） 和双向(BI)方向, HD IO LVDS_E

<!-- 原 PDF 第 33 页 -->

类型的电平只支持输出（TX）方向。
PH1P100 相关封装器件的HR I/O 的预加重功能，当前器件版本暂不支持配置。
HR I/O INOUT/OUT LVDS18 不支持预加重功能。
DDR I/O LVDS18 输入不支持片内100Ω电阻。
SUB_LVDS、MINI_LVDS 仅PH1P35 器件支持。

<!-- 原 PDF 第 34 页 -->

### 2.8 配置说明
PH1P 系列 FPGA 支持 6 种配置模式，分别是JTAG、从动串行(Slave Serial ，简称 SS)、主动串行
(Master Serial，简称MS)、主动SPI(简称MSPI)、主动并行(Master Parallel，简称MP)及从动并行
(Slave Parallel，简称SP)配置模式，且支持位流文件压缩功能。
#### 2.8.1 配置模式
PH1P 系列 FPGA 的配置模式由M[2:0]引脚决定。
表 2-5 配置模式及对应位宽
模式 M[2:0] 位宽 CCLK 方向
MSPI 001 x1/x2/x4 Output
MS 000 x1 Output
MP 100 x8/x16 Output
SS 111 x1 Input
SP 110 x8/x16/x32
Input
JTAG
- - -
#### 2.8.2 FPGA I/O 引脚在配置阶段的状态
非配置相关IO
芯片上电完成后到程序加载完成前：
PH1P100 器件非配置相关I/O 的状态受HSWAPEN 引脚控制，可以为弱上拉或者高阻态。HSWAPEN 设
置为0 时，用户I/O 管脚在配置过程中为弱上拉状态；HSWAPEN 为1 时，用户I/O 处于高阻态。
PH1P35 器件非配置相关I/O 的状态受HSWAPEN 引脚控制，可以为弱下拉或者高阻态。HSWAPEN 设置
为 0 时，用户I/O 管脚在配置过程中为弱下拉状态；HSWAPEN 为 1 时，用户I/O 处于高阻态。
进入用户模式之后，用户使用的I/O 引脚状态受代码控制;
PH1P 系列器件未使用的管脚默认状态为弱上拉状态。
配置相关引脚跟配置设置相关，如下表所示。

<!-- 原 PDF 第 35 页 -->

表 2-6 Configuration Pin Termination
Pin
配置成功前
配置成功后
HSWAPEN=0  HSWAPEN=1
PROGRAMN
Pull-up to Vccio Pull-up to Vccio
Config 专用I/O 呈现
高电平
INITN
high-z high-z
Config 专用I/O 呈现
高电平
DONE
2
Pull-up to Vccio Pull-up to Vccio
Config 专用I/O 呈现
高电平
CCLK
Pull-up to Vccio Pull-up to Vccio 复用 I/O
CSN
Pull-down to Gnd Pull-down to Gnd 复用 I/O
TMS TCK TDO TDI
/TRSTN
Pull-up to Vccio
/TRSTN pull-down to
Gnd
Pull-up to Vccio
/TRSTN pull-down to
Gnd
软件 JtagPin 设置
D[31:4]
Pull-up to Vccio Pull-up to Vccio 复用 I/O
D0_MOSI Pull-up to Vccio Pull-up to Vccio 复用 I/O
D1_DIN_MISO
Pull-up to Vccio Pull-up to Vccio 复用 I/O
D2_WPN
Pull-up to Vccio Pull-up to Vccio 复用 I/O
D3_HOLDN
Pull-up to Vccio Pull-up to Vccio 复用 I/O
SPICSN_BUSY Pull-up to Vccio Pull-up to Vccio 复用 I/O
RDWRN
Pull- down to Gnd Pull- down to Gnd 复用 I/O
CSON_DOUT
Pull-up to Vccio Pull-up to Vccio 复用 I/O
M[2:0]
Pull-up to Vccio Pull-up to Vccio Config 专用I/O
USRCLK
1
Pull-up to Vccio Pull-up to Vccio 复用 I/O
HSWAPEN Pull-up to Vccio Pull-up to Vccio 复用 I/O
Others
（User
I/O）
PH1P100 Pull-up to Vccio High-Z User I/O
PH1P35 Pull-down to Gnd High-Z User I/O
注：
PH1P100 器件USRCLK 复用功能仅作为内部测试使用。
PH1P35 器件USRCLK 在 MSPI 模式下可作为CCLK 的时钟源。
PH1P 系列器件 DONE 信号拉高后，配置时钟至少需要维持 6us+25 个时钟周期，才能进入用户模式
(User mode)；在进入用户模式前，如果input/inout I/O 同时符合以下条件，则有可能在其内部
产生高脉冲，影响该I/O 的相关逻辑：

<!-- 原 PDF 第 36 页 -->

a） 受 HSWAPEN 控制，且HSWAPEN=1（I/O 状态为high-z）；
b） 对应I/O 的软件设置为下拉或者悬空；
c） 作为组合逻辑使用
可通过调整HSWAPE 和I/O 的软件设置，在组合逻辑中避免在进入用户模式前出现I/O 高脉冲。
#### 2.8.3 串行配置模式
在串行配置模式下，FPGA 通过上位机进行配置数据加载，在主动串行 MS 模式下，FPGA 提供 CCLK
时钟；在从动串行SS 模式下，CCLK 由外部提供。
上位机进行配置数据加载，通过CCLK、DIN 使用串行的方式将数据写入FPGA。芯片在每个CCLK 的
上升沿接收数据，数据发送完成后，DONE 拉高表示配置完成；如果出错，INITN 信号将会拉低。串行配
置接口及其时序如下图。串行配置不支持非连续数据输入。
M[2:0]
DIN
PROGRAMN
CCLK DONE
DOUT
INITN
图 2-11 串行配置接口
图 2-12 串行配置模式时序图
DIN
DONE
CCLK …
0 1 n-3... n-1 User moden
PROGRAMN
INITN
T_program_b
T_init_b
T_dsu T_dh
T_cl T_ch
T_clk
xxxx
n-2

<!-- 原 PDF 第 37 页 -->

表 2-7 主动串行时序规格表
符号 参 数 最 小 最 大 单 位
T_program_b PROGRAMN low pulse width 1 — us
T_init_b
INITN low pulse width — 73.852 ms
T_clk
1
CCLK period
PH1P100 27.55 — ns
PH1P35 27.55 — ns
T_ch CCLK high time
PH1P100 12.397 — ns
PH1P35 12.397 — ns
T_cl CCLK low time
PH1P100 12.397 — ns
PH1P35 12.397 — ns
T_dsu Data setup time
PH1P100 4.2 — ns
PH1P35 6 — ns
T_dh Data hold time
PH1P100 2 — ns
PH1P35 0 — ns
注：
实际数据和OSC 的频率偏差有关；以上计算值按照OSC 最大偏差±10%计算。
表 2-8 从动串行时序规格表
符号 参 数 最小 最大 单位
T_program_b PROGRAMN low pulse width 1 — us
T_init_b INITN low pulse width — 73.852 ms
T_clk CCLK period 10 — ns
T_ch CCLK high time 4.5 — ns
T_cl CCLK low time 4.5 — ns
T_dsu Data setup time
PH1P100 1.7 — ns
PH1P35 2 — ns
T_dh Data hold time
PH1P100 0.6 — ns
PH1P35 0.8 — ns

<!-- 原 PDF 第 38 页 -->

#### 2.8.4 主动SPI配置模式
PH1P 系列 FPGA 器件支持MSPI x1/x2/x4 Fast Read 模式，支持超过128Mb 容量的SPI Flash 器件
32-bit 地址读写模式。MSPI 模式下支持DUALBOOT 和MULTIBOOT 功能。
PH1P 系列 FPGA 在码流起始地址放置了128-bit 长度的 SPI FEATURE寄存器，用来存储SPI 接口配
置信息。对于DUALBOOT 和MULTIBOOT，SPI Flash 内的每段码流信息头都包含有SPI 配置信息。
PH1P100 器件CCLK 时钟源为OSC，PH1P35 器件CCLK 时钟源为OSC 或者USRCLK
PH1P器件的MSPI配置接口及接口电路如下所示。
M[2:0]
D1_MISO
D2
PROGRAMN
DONE
SPICSN
D0_MOSI
D3 CCLK
DOUTINITN
图 2-13  MSPI 配置接口
SPI
Serial
FLASH
MSPI
M[2:0] = 001
CCLK
D1_MISO
SPICSN
INITN
DONE
D0_MOSI
SCLK
SO
SI
CS#
DOUT_CSON
GND
GND
PROGRAMN
VCCIO
PROGRAMN
图 2-14 MSPI x1/x2 配置接口电路

<!-- 原 PDF 第 39 页 -->

SPI
Serial
FLASH
MSPI
M[2:0] = 001
CCLK
D1_MISO
SPICSN
INITN
DONE
D0_MOSI
SCLK
SO
SI
CS#
DOUT_CSON
GND
GND
PROGRAMN
VCCIO
PROGRAMN
HOLD#
WP#
D3
D2
图 2-15 MSPI x4 配置接口电路
图 2-16 MSPI 配置模式时序图
表 2-9 MSPI 时序规格表（CCLK 时钟来源为 OSC）
符号 参 数 最 小 最 大 单 位
T_program_b PROGRAMN low pulse width 1 — us
T_init_b
INITN low pulse width — 73.852 ms
T_clk
1
CCLK period
PH1P100 27.55 — ns
PH1P35 27.55 — ns
T_ch CCLK high time
PH1P100 12.397 — ns
PH1P35 12.397 — ns
T_cl CCLK low time
PH1P100 12.397 — ns
PH1P35 12.397 — ns
T_dsu Data setup time PH1P100 4.2 — ns

<!-- 原 PDF 第 40 页 -->

符号 参 数 最 小 最 大 单 位
PH1P35 6 — ns
T_dh Data hold time
PH1P100 2 — ns
PH1P35 0 — ns
注：
实际数据和OSC 的频率偏差有关；以上计算值按照OSC 最大偏差±10%计算。
表 2-10 MSPI 时序规格表（CCLK 时钟来源为 USRCLK）
符号 参 数 器件 最 小 最 大 单 位
T_program_b
PROGRAMN low pulse
width
PH1P35 1 — us
T_init_b
INITN low pulse width PH1P35 — 73.852 ms
T_clk
1
CCLK period PH1P35 1/FCLK_USRCLK  — ns
T_ch CCLK high time
PH1P35
（1/Fclk_usrclk）
*0.5*0.9
—
ns
T_cl CCLK low time
PH1P35
（1/Fclk_usrclk）
*0.5*0.9
—
ns
T_dsu Data setup time PH1P35 5.3 — ns
T_dh Data hold time PH1P35 0 — ns
注：
1/(FCLK_USRCLK×（1+FTOLMAX_USRCLK）)≥(T1+T2+TCLQV)+T_dsu
表 2-11 FCLK_USRCLK公式参数
参数 描述
FCLK_USRCLK CCLK 时钟来源为USRCLK 时，最大加载频率
FTOLMAX_USRCLK USRCLK 的最大频偏比
T_dsu FPGA 数据建立时间
T1 FPGA CCLK PAD 到FLASH SCLK PAD 的板间延迟
T2
X1/X2/x4 对应模式下，FLASH 数据输出PAD 到FPGA 数据输入PAD 的最大板
间延迟
TCLQV FLASH 时钟下降沿到数据输出有效延迟，需从FLASH 手册获取

<!-- 原 PDF 第 41 页 -->

#### 2.8.5 并行配置模式
并行模式包括主动并行MP 模式和从动并行SP 模式。FPGA 芯片在每个CCLK 的上升沿接收数据。SP
模式配置支持8 位、16 位和32 位三种数据位宽，通过控制CSN 和RDWRN 管脚电平可实现读写切换；MP
模式支持8 位和 16 位两种数据位宽，不支持回读模式。其中配置模块通过检测码流中的位宽同步字，
可自动识别数据位宽。 在MP 模式下，FPGA 提供CCLK 时钟； 在SP 模式下，CCLK 由外部提供；并行配置
接口如下图所示。
M[2:0]
D[31:0]
RDWRN
PROGRAMN
DONE
INITN
CSN CCLK
CSON
BUSY
图 2-17 并行配置接口
图 2-18 并行配置时序图
表 2-12 主动并行时序规格表
符号 参 数 最 小 最 大 单 位
T_program_b PROGRAMN low pulse width 1 — us
T_init_b INIT_B low pulse width — 73.852 ms
T_clk
1
CCLK period
PH1P100 27.55 — ns
PH1P35 27.55 — ns
T_ch CCLK high time
PH1P100 12.397 — ns
PH1P35 12.397 — ns
T_cl CCLK low time
PH1P100 12.397 — ns
PH1P35 12.397 — ns
DATA
DONE
CCLK …
0 1 n-1
CSN
... n User moden+1
PROGRAMN
INITN
T_program_b
T_init_b
T_dsu T_dh
T_cl T_ch
T_clk
xxxx

<!-- 原 PDF 第 42 页 -->

符号 参 数 最 小 最 大 单 位
T_dsu Data setup time
PH1P100 4.2 — ns
PH1P35 6 — ns
T_dh Data hold time
PH1P100 2 — ns
PH1P35 0 — ns
注：
实际数据和OSC 的频率偏差有关；以上计算值按照OSC 最大偏差10%计算。
表 2-13 从动并行时序规格表
符号 参 数 最 小 最 大 单 位
T_program_b PROGRAMN low pulse width 1 — us
T_init_b INIT_B low pulse width — 73.852 ms
T_clk CCLK period 10 — ns
T_ch CCLK high time 4.5 — ns
T_cl CCLK low time 4.5 — ns
T_dsu Data setup time
PH1P100 1.7 — ns
PH1P35 2 — ns
T_dh Data hold time
PH1P100 0.6 — ns
PH1P35 0.8 — ns
#### 2.8.6 JTAG配置模式
PH1P系列FPGA支持IEEE 1149.1协议， 该协议定义了Test Access Port（TAP） 和边界扫描 （Boundray-
Scan）。
PH1P系列FPGA同时支持IEEE 1532协议，该协议定义了In-System Configuration Architecture。
PH1P系列FPGA使用5个JTAG专用管脚：TCK、TMS、TDI、TDO及TRSTN。其中TCK、TMS、TDI、和TRSTN
为输入管脚，TDO为输出管脚。在INITN信号变高后， 不管模式选择引脚选择了何种模式， 或者其他模式
正在配置过程中，JTAG模式可以通过指令中断其他模式，进入JTAG配置模式。
TAP 状态机示意图配置方式如下图所示。

<!-- 原 PDF 第 43 页 -->

图 2-19 TAP 状态机示意图配置
表 2-14 JTAG 时序规格表
参数 描述 最 小 最 大 单 位
TJCP
1
TCK 周期
PH1P100 40 — ns
PH1P35 25 — ns
TJCH TCK 高电平时间
PH1P100 16 — ns
PH1P35 10 — ns
TJCL TCK 低电平时间
PH1P100 16 — ns
PH1P35 10 — ns
TJPSU_TDI TDI 建立时间
PH1P100 3.3 — ns
PH1P35 7 — ns
TJPSU_TMS TMS 建立时间
PH1P100 4.2 — ns
PH1P35 7 — ns
TJPH JTAG 端口保持时间 3 — ns
TJPCO
JTAG 端口时钟到输
出延时
PH1P100 — 12 ns
PH1P35 — 7 ns
TJPZX JTAG 端口高阻到有效输出转换时间 — 12 ns
TJPXZ JTAG 端口有效输出到高阻转换时间 — 12 ns
注：
若采用MSPI 加载模式， 并且通过JTAG 非背景升级外部flash 数据，TCK 的频率要大于等于100KHz。

<!-- 原 PDF 第 44 页 -->

### 2.9 SEU检错和纠错模块
PH1P 系列 FPGA 器件支持用户通过JTAG 或者SP 接口回读和校验配置存储器内容。 如果需要回读配
置存储器中的内容， 用户需要先发送一串命令到器件来初始化回读状态。 回读状态初始化完成后， 器件
就会连续的将配置存储器内容输出到JTAG 或者SP 接口上。
除了用户主动发起的回读校验，PH1P 系列FPGA 器件还支持在背景模式下连续地回读配置寄存器并
校验。这个功能主要用于简化单粒子翻转（SEU）的检测。
回读校验功能点：
 支持JTAG 接口回读
 支持SP(Slave Parallel)接口回读
 支持回读功能的使能和禁止
ECC 功能点：
 硬件内置的ECC 和CRC 错误检测
 支持两种工作模式：单次触发、循环监测
 基于ECC 的单bit 错误检测和纠正，双bit 检错
 基于ECC 的分布在多帧的每一帧单bit 错误检测和纠正
 基于CRC 的多bit 错误检测
 支持单bit 和双bit 错误注入
### 2.10 电压温度检测模块
PH1P 系列 FPGA 器件内置一个高集成度的电压温度检测模块Temperature and Voltage Sensor(以
下简称TVS)，可以实时对芯片上的电压、温度进行高精度测量。
 集成高精度电压温度检测模块
 支持芯片电压实时监控
 支持芯片温度实时监控

<!-- 原 PDF 第 45 页 -->

### 2.11 External Memory Interface
PH1P 系列 FPGA 内部集成 DDR 专用逻辑，提供 DDR2/DDR3/DDR4 存储器接口支持，支持最大位宽可
达 72-bit。
主要支持的特性如下：
 支持可配置的SDRAM 数据位宽为8-bit 至 72-bit，步进为8bit（支持的最大颗粒数为9）
 支持突发长度为8 的模式（仅支持BL8）
 支持x8、x16 类型的存储器颗粒类型
 支持最大2 个Rank
 支持后台进行延时链校准
### 2.12 Integrated Memory Interface
PH1P 系列中PH1P35MDG324 器件内部合封高速存储器，提供高速存储器接口支持。
主要支持的特性如下：
 支持SDRAM 数据位宽为16-bit,容量为512Mb
 支持突发长度为BL8 模式
 支持后台进行延时链校准
 支持写数据掩码
PH1P 系列中PH1P35MHG324 器件内部合封高速存储器，提供高速存储器接口支持。
主要支持的特性如下：
 支持SDRAM 数据位宽为16-bit,容量为1024Mb
 支持突发长度为BL8 的模式
 支持后台进行延时链校准
 支持写数据掩码

<!-- 原 PDF 第 46 页 -->

### 2.13 MIPI DPHY
PH1P35 器件集成 2 组 MIPI 硬核模块，每组 MIPI 硬核模块可以设置为输入或者输出，最大支持 4
Lane，搭配用户逻辑可以配置为串行摄像头接口（Camera Serial Interface，CSI-2）或者串行显示接
口（Display Serial Interface，DSI）。
#### 2.13.1 功能特性
MIPI 硬核模块具有如下性能特征：
 支持高速模式（High-Speed，HS）和低功耗模式（Low-Power，LP）动态切换。
 低功耗模式（Low-Power，LP）支持双向传输。
 支持动态Skew 调节，自动Skew 校准。
 输入输出电气参数可编程配置。
除了用于MIPI 模式，MIPI 硬核模块还可配置为LVCMOS 和LVDS 模式， 使得使用方式更为灵活和丰
富。
#### 2.13.2 模块功能描述
PH1P 系列 FPGA 的 MIPI 硬核模块，是一种包含了TX 和 RX 在内的混合结构物理层，单对信号线的
结构示意框图如下所示。

<!-- 原 PDF 第 47 页 -->

图 2-20 MIPI 硬核模块简化功能框图
PH1P 系列 FPAG 的MIPI TX 基础功能单元有：
LS_TX
用于MIPI 模式的LP 数据发送和LVCMOS 模式数据发送。
LP_RX
用于MIPI 模式的LP 数据接收，所有的数据Lane 都集成了LP_RX 功能，通道0 线序可以与其他通
道任意交换。
HS_TX
用于MIPI 模式的HS 数据发送和LVDS 模式数据发送，HS_TX 单元可以实现Data Lane 8:1 和16:1
并串转换。

<!-- 原 PDF 第 48 页 -->

PLL
用于提供MIPI 模式HS 数据发送和LVDS 模式数据发送所需要的所有时钟。
Clock Control
用于MIPI 模式HS 数据发送和LVDS 模式数据发送所有的时钟控制。
Tx Lane Control
用于所有模式下MIPI TX 数据和时钟Lane 的控制。
PH1P 系列 FPAG 的MIPI RX 基础功能单元有：
LS_RX
用于MIPI 模式LP 数据接收和LVCMOS 模式数据接收。
LP_TX
用于MIPI 模式LP 反向数据传输，所有的数据Lane 都集成了LP_TX 功能，通道0 线序可以与其他
通道任意交换。
HS_RX
用于MIPI 模式HS 数据接收和LVDS 模式数据接收，HS_RX 单元可以实现Data Lane 1:8 和1：16
串并转换。
RT
用于MIPI HS 模式和LVDS 模式输入终端电阻控制
Clock Control
用于MIPI 模式HS 数据接收和LVDS 模式数据接收所有的时钟控制。
RX Lane Control
用于所有模式下MIPI RX 数据和时钟Lane 的控制。

<!-- 原 PDF 第 49 页 -->

### 2.14 MCU
PH1P35 器件内部集成了一个RISC-V MCU 硬核。
#### 2.14.1 功能特性
MCU 模块具有如下性能特征：
 支持RV32 I/M/A/F/C/P/B 指令集
 三级流水设计
 32KB ICache,32KB DCache,16KB DLM
 支持JTAG 调试
 支持快速中断响应和定时器
 通用外设QSPI0/1、UART0/1、GPIOx8、I2C
 支持DMA
 支持AHB 和APB bus 访问fabric 逻辑
#### 2.14.2 模块功能描述
Frabric
RISC-V Processor Core
Dcache
IF
DLM
IF
Icache/ILM
IF
Debug
Interrupt Distribution Unit
Timer
32K
Cache
RAMs
16K
Data
RAMs
32K
Cache
RAMs
QSPI
0
QSPI
1
UART
1 I2CUART
0 GPIO DMA
config
FLASH CONFIG
JTAG
por_reset
core_reset
core_clk
APB
Bridge
AHB
Bridge
timer_clk
nmi
irq
图 2-21 RISC-V MCU 模块结构

<!-- 原 PDF 第 50 页 -->

如上图所示，RISC-V MCU 集成了三级流水线的RISC-V 内核以及相关外设。RISC-V MCU 系统时钟来
自 PLL (可配置)，RISC-V MCU 的AHB、APB 接口通过PIB 连接到FABRIC 上，可以通过AHB、APB 接口访
问 FPGA 逻辑搭建的相关模块。此外， 在该架构中，RISC-V 所有的IO 都与FPGA 相连，因此，RISC-V 的
系统时钟、中断、调试接口，可通过相关配置来实现。

<!-- 原 PDF 第 51 页 -->

## 3 直流交流特性
所有参数指最差的供电电压和结点温度。 如无特殊说明， 以下信息适用于： 同一商业和工业级别规
定的交流和直流特性。所有参数均为电压对地时的值。
### 3.1 直流电气特性
#### 3.1.1 最大绝对额定值
表 3-1 最大绝对额定值
Symbol 参 数 最小 最大 单位
VCCAUX 辅助电源 -0.5 1.98 V
VCCAUX_IO 辅助电源
PH1P100SBG676、
PH1P100SBG677、
PH1P100SBG484
-0.5 1.98 V
VCCIO I/O 驱动供电电压
HR -0.5 3.63 V
HD -0.5 3.63 V
DDR -0.5 1.98 V
VCCINT 内核电源 -0.5 1.05 V
VPHYVCCA HXT Core 模拟电源 PH1P100SBG676 -0.5 1.98 V
VPHYVCCT HXT Core 模拟电源
PH1P100SBG677、
PH1P100SBG484
-0.5 1.32 V
VCCDPHY MIPI DPHY 电源 PH1P35 -0.5 1.98 V
VCCIO_DDR Integrated Memory I/O 驱动供电电压
PH1P35MDG324 -0.5 1.98  V
PH1P35MHG324 -0.5 1.98 V
VDDR_VREF Integrated Memory 参考电压
PH1P35MDG324 -0.5 1.98 V
PH1P35MHG324 -0.5 1.98 V
VI
1
直流输入电压
HR -0.3 VCCIO+0.4 V
HD -0.3 VCCIO+0.5 V
DDR -0.3 VCCIO+0.2 V
HXT -0.3 1.2 V
MIPI -0.15 1.45 V
IDCIN-FLOAT
HXT 接收器输入为 DC 耦合，且termination 为floating 时
的 DC 输入电流
- 10 mA
IDCIN-
PHYVCCA/PHYVCCT
HXT 接收器输入为DC 耦合，且termination 为
VPHYVCCA/PHYVCCT 时的DC 输入电流
- 10 mA

<!-- 原 PDF 第 52 页 -->

Symbol 参 数 最小 最大 单位
IDCIN-GND
HXT 接收器输入为DC 耦合，且 termination 为GND 时的DC
输入电流
- 10 mA
IDCOUT-FLOAT
HXT 发射器输出为DC 耦合，且termination 为floating 时
的 DC 输出电流
- 10 mA
IDCOUT-
PHYVCCA/PHYVCCT
HXT 发射器输出为DC 耦合，且termination 为
VPHYVCCA/PHYVCCT 时的DC 输出电流
- 10 mA
VESDHBM 人体模型静电放电电压 － ±2000 V
VESDCDM 器件充电模型静电放电电压 － ±350 V
TSTG 存储温度 -40 125 ℃
TJ 结点温度
工业级 -40 125 ℃
车规级 -40 125 ℃
注：
最大限制适用于直流信号，有关最大下冲和过冲交流规范，请参见表 3-2、表 3-3、表 3-4。
超过以上最大绝对额定值可能会导致器件永久性损坏。表 3-1 的值仅表示在该额定值下操作不会
损坏器件， 但不表示器件在此极限值下功能正常。 而且器件长期在极值条件下运行， 会严重影响器件的
可靠性。
表 3-2 列出了最大允许输入过冲/下冲电压，以及过冲/下冲电压的持续时间占数据UI 的百分比。
如例图所示，T 为数据的UI 长度，DT 为过冲信号的持续时间。 过冲电压超过VCCIO+0.2V 的时刻即为统计
过冲DT 的起始时刻，过冲电压低于VCCIO+0.2V 的时刻即为统计过冲DT 的结束时刻。同样，下冲电压低
于 GND-0.2V 的时刻即为统计下冲 DT 的起始时刻，下冲电压超过 GND-0.2V 的时刻即为统计下冲 DT 的
结束时刻。表 3-2 中一个直流输入信号意味着过冲信号(例如幅值为VCCIO+0.4V 的过冲信号)的持续时间
（DT） 可以占整个数据UI 的 100％， 或者下冲信号(例如幅值为GND-0.3V 的下冲信号)的持续时间 （DT）
可以占整个数据UI 的100％。 而过冲至VCCIO+0.5V 的过信号的维持时间 （DT） ， 只能占数据UI 的27％。
VCCIO+0.4
VCCIO+0.2
VCCIO
GND
GND-0.2
GND-0.3
图 3-1 输入信号过冲/下冲(HR)

<!-- 原 PDF 第 53 页 -->

表 3-2 10 年使用寿命条件下允许的最大过冲、下冲占比(HR I/O)
Parameter Condition(V)
Under/Overshoot Duration as% of High Time
（–40° C to 125° C）
Unit
VI AC
Input Voltage
VCCIO+0.1 100 %
VCCIO+0.2 100 %
VCCIO+0.3 100 %
VCCIO+0.4 100 %
VCCIO+0.5 27 %
VCCIO+0.6 7 %
VCCIO+0.7 2 %
VCCIO+0.8 0.7 %
-0.1 100 %
-0.2 100 %
-0.3 100 %
-0.4 27 %
-0.5 7 %
-0.6 2 %
-0.7 0.7 %
注：
UI 的周期T 不超过20uS
表 3-3 10 年使用寿命条件下允许的最大过冲、下冲占比(HD I/O)
Parameter Condition(V)
Under/Overshoot Duration as% of High Time
–40° C to 125° C
Unit
VI AC
Input Voltage
VCCIO+0.1 100 %
VCCIO+0.2 100 %
VCCIO+0.3 100 %
VCCIO+0.4 100 %
VCCIO+0.5 100 %
VCCIO+0.6 39.2 %
VCCIO+0.7 9.8 %
VCCIO+0.8 2.75 %
VCCIO+0.9 0.85 %
-0.1 100 %
-0.2 100 %
-0.3 100 %

<!-- 原 PDF 第 54 页 -->

Parameter Condition(V)
Under/Overshoot Duration as% of High Time
–40° C to 125° C
Unit
-0.4 27 %
-0.5 7 %
-0.6 2 %
-0.7 0.7 %
表 3-4 10 年使用寿命条件下允许的最大过冲、下冲占比(DDR I/O)
Parameter Condition(V)
Under/Overshoot Duration as% of High Time
–40° C to 125° C
Unit
VI AC
Input Voltage
VCCIO+0.1 100 %
VCCIO+0.2 100 %
VCCIO+0.3 38 %
VCCIO+0.4 12.5 %
VCCIO+0.5 4 %
VCCIO+0.6 1.67 %
VCCIO+0.7 1.43 %
VCCIO+0.8 1.3 %
-0.1 100 %
-0.2 100 %
-0.3 100 %
-0.4 93 %
-0.5 67 %
-0.6 45 %
-0.7 8 %

<!-- 原 PDF 第 55 页 -->

#### 3.1.2 推荐基本操作条件
表 3-5 推荐基本操作条件
Symbol 参 数 最小 典型 最大 单位
VCCAUX 辅助电源 1.71 1.8 1.89 V
VCCAUX_IO IO 辅助电源
PH1P100SBG676、
PH1P100SBG677、
PH1P100SBG484
1.71 1.8 1.89 V
VCCIO
HR
I/O 供电电压
@ 3.3V
3.135 3.3 3.465 V
I/O 供电电压
@ 2.5V
2.375 2.5 2.625 V
I/O 供电电压
@ 1.8V
1.71 1.8 1.89 V
I/O 供电电压
@ 1.5V
1.425 1.5 1.575 V
I/O 供电电压
@ 1.35V
1.2825 1.35 1.4175 V
I/O 供电电压
@ 1.2V
1.14 1.2 1.26 V
HD
I/O 供电电压
@ 3.3V
3.135 3.3 3.465 V
I/O 供电电压
@ 2.5V
2.375 2.5 2.625 V
I/O 供电电压
@ 1.8V
1.71 1.8 1.89 V
I/O 供电电压
@ 1.5V
1.425 1.5 1.575 V
DDR
I/O 供电电压
@ 1.8V
1.71 1.8 1.89 V
I/O 供电电压
@ 1.5V
1.425 1.5 1.575 V
I/O 供电电压
@ 1.35V
1.2825 1.35 1.4175 V
I/O 供电电压
@ 1.2V
1.14 1.2 1.26 V
VCCINT 内核电源 PH1P 0.92 0.95 0.98 V

<!-- 原 PDF 第 56 页 -->

Symbol 参 数 最小 典型 最大 单位
VPHYVCCA
HXT Core
模拟电源
PH1P100SBG676 1.71 1.8 1.89 V
VPHYVCCT
HXT Core
模拟电源
PH1P100SBG677、
PH1P100SBG484
- 1.2 - V
VCCDPHY MIPI DPHY 电源 PH1P35 1.71 1.8 1.89 V
VCCIO_DDR
Integrated Memory I/O
驱动供电电压
PH1P35MDG324 1.425 1.5 1.575 V
PH1P35MHG324 1.283 1.35 1.45 V
VDDR_VREF
Integrated Memory
参考电压
PH1P35MDG324、
PH1P35MHG324
0.49*VCCIO_DDR 0.5*VCCIO_DDR 0.51*VCCIO_DDR V
VI 直流输入电压
HR -0.2 - VCCIO+0.2 V
HD -0.2 - VCCIO+0.2 V
DDR -0.2 - VCCIO+0.1 V
HXT 0 - 0.99 V
MIPI -0.05 - 1.35 V
VO 输出电压 0 － VCCIO V
TJ 结点温度
工业级 -40 － 100 ℃
车规级 -40 － 125 ℃
TVCCAUX 上电时间,从 GND 到90%VCCAUX 0.1 － 100 ms
TVCCAUX_IO 上电时间,从GND 到90% TVCCAUX_IO 0.1 － 100 ms
TVCCINT 上电时间,从GND 到90% TVCCINT 0.1 － 100 ms
TVCCIO 上电时间,从GND 到90% TVCCIO 0.1 － 100 ms
TPHYVCCA 上电时间,从 GND 到90% TPHYVCCA 0.1 － 100 ms
TPHYVCCT 上电时间,从 GND 到90% TPHYVCCT 0.1 － 100 ms
TVCCDPHY 上电时间,从 GND 到90% TVCCDPHY 0.1 － 100 ms
TVCCADC 上电时间,从GND 到90% TVCCADC 0.1 - 100 ms
ODT
HR
VCCIO/2 的等效电阻
RTT_50
-30% 50 30% Ω
VCCIO/2 的等效电阻
RTT_100
-30% 100 30% Ω
VCCIO/2 的等效电阻
RTT_40
-30% 40 30% Ω
VCCIO/2 的等效电阻
RTT_48
-30% 48 30% Ω
VCCIO/2 的等效电阻
RTT_60
-30% 60 30% Ω
DDR VCCIO/2 的等效电阻 -30% 50 30% Ω

<!-- 原 PDF 第 57 页 -->

Symbol 参 数 最小 典型 最大 单位
RTT_50
VCCIO/2 的等效电阻
RTT_100
-30% 100 30% Ω
VCCIO/2 的等效电阻
RTT_40
-30% 40 30% Ω
VCCIO/2 的等效电阻
RTT_48
-30% 48 30% Ω
VCCIO/2 的等效电阻
RTT_60
-30% 60 30% Ω
#### 3.1.3 IO BANK基本供电要求
表 3-6 PH1P100SBG676 最小供电要求
3
电源域标识 基本供电要求 备注
VCCIO0
1,4
>=1.8V 与JTAG 相连，必须供电
VCCIO11 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO12
1，4
>=1.2V 必须供电
VCCIO13 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO14 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO21
2
>=1.2V 可选择性供电、悬空或接地
VCCIO22
2
>=1.2V 可选择性供电、悬空或接地
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO33 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCAUX_IO =1.8V 必须供电
VCCINT =0.95V 必须供电
注：
POR 上电检测，必须供电
封装上此电源各个引脚内部无连接
需要供电使用的电源，所有的电源引脚必须供电
PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保
持一致。

<!-- 原 PDF 第 58 页 -->

表 3-7 PH1P100SBG677 最小供电要求
3
电源域标识 基本供电要求 备注
VCCIO0
1，4
>=1.8V 与JTAG 相连，必须供电
VCCIO11 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO12
1，4
>=1.2V 必须供电
VCCIO13 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO14 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO21
2
>=1.2V 可选择性供电、悬空或接地
VCCIO22
2
>=1.2V 可选择性供电、悬空或接地
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO33 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCAUX_IO =1.8V 必须供电
VCCINT =0.95V 必须供电
注：
POR 上电检测，必须供电
封装上此电源各个引脚内部无连接
需要供电使用的电源，所有的电源引脚必须供电
PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保
持一致
表 3-8 PH1P100SBG484 最小供电要求
2
电源域标识 基本供电要求 备注
VCCIO0
1，3
>=1.8V 与JTAG 相连，必须供电
VCCIO11 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO12
1，3
>=1.2V 必须供电
VCCIO13 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO14 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO33 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCAUX_IO =1.8V 必须供电
VCCINT =0.95V 必须供电
注：
POR 上电检测，必须供电
需要供电使用的电源，所有的电源引脚必须供电

<!-- 原 PDF 第 59 页 -->

PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保
持一致
表 3-9 PH1P100GEG324 最小供电要求
2
电源域标识 基本供电要求 备注
VCCIO0
1，3
>=1.8V 与JTAG 相连，必须供电
VCCIO12
1，3
>=1.2V 必须供电
VCCIO13 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO14 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO33 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCINT =0.95V 必须供电
注：
POR 上电检测，必须供电
需要供电使用的电源，所有的电源引脚必须供电
PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保
持一致
表 3-10 PH1P35MBG484 最小供电要求
2
电源域标识 基本供电要求 备注
VCCIO0
1，3
>=1.8V 与JTAG 相连，必须供电
VCCIO11 1.2V～1.8V 可选择性供电、不使用时可供电或者悬空
VCCIO12 1.2V～1.8V 可选择性供电、不使用时可供电或者悬空
VCCIO21 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCIO22
1，3
>=1.5V 必须供电
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO41 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCIO42 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCINT =0.95V 必须供电
VCCDPHY =1.8V 必须供电
注：
POR 上电检测，必须供电
需要供电使用的电源，所有的电源引脚必须供电
PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保

<!-- 原 PDF 第 60 页 -->

持一致
表 3-11 PH1P35MDG324/PH1P35MHG324 最小供电要求
2
电源域标识 基本供电要求 备注
VCCIO0
1，3
>=1.8V 与JTAG 相连，必须供电
VCCIO11
4
VCCIO12
4
VCCIO_DDR
4
PH1P35MDG324 =1.5V
可选择性供电、不使用时可供电或者悬空
PH1P35MHG324 =1.35V
VCCIO21 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCIO22
1，3
>=1.5V 必须供电
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO42 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCINT =0.95V 必须供电
VCCDPHY =1.8V 必须供电
注：
POR 上电检测，必须供电
需要供电使用的电源，所有的电源引脚必须供电
PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保
持一致
VCCIO11、VCCIO12、VCCIO_DDR 三个电源供电电压相同，建议同时上电，如不使用，则都不供电或
者都悬空
表 3-12 PH1P35MEG324/PH1P35MEG324A 最小供电要求
2
电源域标识 基本供电要求 备注
VCCIO0
1，3
>=1.8V 与JTAG 相连，必须供电
VCCIO12 1.2V～1.8V 可选择性供电、不使用时可供电或者悬空
VCCIO21 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCIO22
1，3
>=1.5V 必须供电
VCCIO32 >=1.2V 可选择性供电、不使用时可供电或者悬空
VCCIO42 >=1.5V 可选择性供电、不使用时可供电或者悬空
VCCAUX =1.8V 必须供电
VCCINT =0.95V 必须供电
VCCDPHY =1.8V 必须供电
注：
POR 上电检测，必须供电

<!-- 原 PDF 第 61 页 -->

需要供电使用的电源，所有的电源引脚必须供电
PH1P 系列 FPGA 支持多种配置模式， 需使用的配置管脚位于不同BANK 时， 相关BANK 供电电源需保
持一致
#### 3.1.4 器件静态供电电流
表 3-13 静态电源电流
Symbol IO 类型 参 数 器 件 典 型 单 位
IVCCIO
HR
I/O 组电源, @VCCIO=1.2V PH1P100 10 mA
I/O 组电源, @VCCIO=1.5V PH1P100 12 mA
I/O 组电源, @VCCIO=1.8V PH1P100 15 mA
I/O 组电源, @VCCIO=2.5V PH1P100 21 mA
I/O 组电源, @VCCIO=3.3V PH1P100 25 mA
I/O 组电源, @VCCIO=1.2V PH1P35 1.3 mA
I/O 组电源, @VCCIO=1.35V PH1P35 1.4 mA
I/O 组电源, @VCCIO=1.5V PH1P35 1.5 mA
I/O 组电源, @VCCIO=1.8V PH1P35 2 mA
I/O 组电源, @VCCIO=2.5V PH1P35 2.5 mA
I/O 组电源, @VCCIO=3.3V PH1P35 3 mA
HD
I/O 组电源, @VCCIO=1.5V PH1P35 4.5 mA
I/O 组电源, @VCCIO=1.8V PH1P35 6 mA
I/O 组电源, @VCCIO=2.5V PH1P35 8 mA
I/O 组电源, @VCCIO=3.3V PH1P35 11 mA
DDR
I/O 组电源, @VCCIO=1.2V PH1P35 0.5 mA
I/O 组电源, @VCCIO=1.35V PH1P35 0.5 mA
I/O 组电源, @VCCIO=1.5V PH1P35 0.5 mA
I/O 组电源, @VCCIO=1.8V PH1P35 0.5 mA
Symbol 参 数 器 件 典 型 单 位
IVCCAUX 辅助电源
PH1P100 68 mA
PH1P35 5 mA
IVCCAUX_IO IO 辅助电源
PH1P100SBG676、
PH1P100SBG677、
PH1P100SBG484
2.2 mA

<!-- 原 PDF 第 62 页 -->

IVCCINT 内核电压
PH1P100 350 mA
PH1P35 210 mA
IPHYVCCA HXT High Voltage IO Supply PH1P100SBG676  60 mA
IPHYVCCT HXT High Voltage IO Supply
PH1P100SBG677、
PH1P100SBG484
TBD mA
IVCCIO_DDR Integrated Memory I/O 驱动供电电压
PH1P35MDG324 5 mA
PH1P35MHG324 5 mA
IVCCDPHY MIPI DPHY 电源 PH1P35 1 mA
注：
该表中的数值基于通用的推荐操作条件，结温下（Tj =85℃）使用典型器件测得。
典型值为空白器件，没有输出电流负载，高阻抗状态下，并当所有上拉/下拉电阻器在I/O 引脚禁
止时，测量的所有I/O 驱动的静态电源电流。
#### 3.1.5 上下电时序
PH1P FPGA 无上下电时序要求，VCCAUX 与VCCAUX_IO 需要连接在一起，同时上下电。
图 3-2 器件上电时序图
电源上电过程中所有的IO 处于高阻态。
TPOR 最大为73.852ms，TPROG 最大值为59.517ms,TCCLKV 最小值为5us。
表 3-14 上下电复位电压阈值
Symbol 参 数 最 小 典 型 最 大 单 位
VCCAUX_PORUP VCCAUX 上电检测阈值 1.39 1.55 1.71 V
VCCAUX_PORDN VCCAUX 下电检测阈值 1.21 1.35 1.49 V

<!-- 原 PDF 第 63 页 -->

Symbol 参 数 最 小 典 型 最 大 单 位
VCCIO_PORUP Vccio 上电检测阈值
PH1P100 0.72 0.81 0.9 V
PH1P35 0.81 0.9 0.99 V
VCCIO_PORDN Vccio 下电检测阈值
PH1P100 0.72 0.81 0.9 V
PH1P35 0.81 0.9 0.99 V
VCCINT_PORUP VCCINT 上电检测阈值 0.63 0.7 0.77 V
VCCINT_PORDN VCCINT 下电检测阈值 0.54 0.6 0.66 V
VDRINT
数据保留VCCINT 电压
（低于此值可能会丢失配置数据）
0.7 － － V
VDRI
数据保留VCCAUX 电压
（低于此值可能会丢失配置数据）
1.49 － － V
#### 3.1.6 I/O管脚电容
表 3-15 器件管脚电容
Symbol 参 数 电容（典型） 单 位
CHR HR 管脚输入电容 6 pF
CHD HD 管脚输入电容 8 pF
CDDR DDR 管脚输入电容 3 pF
CMIPI MIPI 管脚输入电容 2 pF
CADC ADC 管脚输入电容 2.3 pF
注：
该测量值代表芯片die 上管脚电容，不包括封装。
#### 3.1.7 热插拔规格
表 3-16 热插拔规格
Symbol 参 数 最 大 单 位
IIOPIN(DC)
2
DC 电流，每个I/O 300 uA
IIOPIN(AC)
3
AC 电流，每个 I/O
电源上下电导致（VCCINT、VCCAUX、VCCIO）
4
1 mA
IO 上下电导致 15 mA
注：
DDR I/O,HD I/O 不支持热插拔
DC：电源与IO 状态稳定后的IO 电流。
AC 电流是在电源变化或者I/O 端口信号变化，且I/O 端口信号变化rise/fall time>=10ns条件的

<!-- 原 PDF 第 64 页 -->

情况下测到输入或者流出I/O 的最大电流。 如果rise/fall time<10ns，IIOPIN(AC) =Cdv/dt,C 为
I/O 的负载电容，dv/dt 为I/O 信号的slew rate。rise/fall time 指信号变化从10%~90%的时间。
I2C 总线使用场景上拉电阻值为1K～2K
#### 3.1.8 I/O直流电气特性
表 3-17 IO 推荐基本操作条件(HR I/O)
Symbol 参 数 条 件 最 小 典 型 最 大 单 位
IL
输入输出漏电电流 0≦VI/O≦VCCIO － － 15 uA
输入输出漏电电流 VCCIO≦VI/O≦3.465 － － 300 uA
IPU I/O 弱上拉电流
VI=0V,VCCIO=3.3V  80 － 165 uA
VI=0V,VCCIO=2.5V 60 － 125 uA
VI=0V,VCCIO=1.8V 30 － 90 uA
VI=0V,VCCIO=1.5V 20 － 75 uA
VI=0V,VCCIO=1.2V 15 － 60 uA
IPD I/O 弱下拉电流
VI=3.3V,VCCIO=3.3V 80 － 165 uA
VI=2.5V,VCCIO=2.5V 60 － 125 uA
VI=1.8V,VCCIO=1.8V 30 － 90 uA
VI=1.5V,VCCIO=1.5V 20 － 75 uA
VI=1.2V,VCCIO=1.2V 15 － 60 uA
VHYST
Hysteresis for
Schmitt Trigger
Input
VCCIO=3.3V － 350 － mV
VCCIO=2.5V － 350 － mV
VCCIO=1.8V － 250 － mV
VCCIO=1.5V － 150 － mV
表 3-18 IO 推荐基本操作条件(HD I/O)
Symbol 参 数 条 件 最 小 典 型 最 大 单 位
IL 输入输出漏电电流
0≦VI≦VCCIO － － 15 uA
VCCIO≦VI≦3.465 － － 300 uA
IPU I/O 弱上拉电流
VI=0V,VCCIO=3.3V  80 － 350 uA
VI=0V,VCCIO=2.5V 60 － 300 uA
VI=0V,VCCIO=1.8V 30 － 250 uA

<!-- 原 PDF 第 65 页 -->

Symbol 参 数 条 件 最 小 典 型 最 大 单 位
VI=0V,VCCIO=1.5V 20 － 200 uA
IPD I/O 弱下拉电流
VI=3.3V,VCCIO=3.3V 50 － 350 uA
VI=2.5V,VCCIO=2.5V 50 － 300 uA
VI=1.8V,VCCIO=1.8V 30 － 250 uA
VI=1.5V,VCCIO=1.5V 20 － 200 uA
VHYST
Hysteresis for
Schmitt Trigger
Input
VCCIO=3.3V － 250 － mV
VCCIO=2.5V － 200 － mV
VCCIO=1.8V － 150 － mV
VCCIO=1.5V － 60 － mV
表 3-19 IO 推荐基本操作条件(DDR I/O)
Symbol 参 数 条 件 最 小 典 型 最 大 单 位
IL
输入输出漏电电流 0≦VI≦VCCIO － － 15 uA
输入输出漏电电流 VCCIO≦VI≦1.89 － － 300 uA
IPU I/O 弱上拉电流
VI=0V,VCCIO=1.8V 30 － 250 uA
VI=0V,VCCIO=1.5V 20 － 200 uA
VI=0V,VCCIO=1.2V 15 － 150 uA
IPD I/O 弱下拉电流
VI=1.8V,VCCIO=1.8V 30 － 250 uA
VI=1.5V,VCCIO=1.5V 20 － 200 uA
VI=1.2V,VCCIO=1.2V 15 － 150 uA
VHYST
Hysteresis for
Schmitt Trigger Input
VCCIO=1.8V － 150 － mV
VCCIO=1.5V － 100 － mV
VCCIO=1.2V － 100 － mV

<!-- 原 PDF 第 66 页 -->

#### 3.1.9 单端I/O直流电学特性
表 3-20 IO 单端 I/O 标准规格(HR I/O)
标准
VIL (V) VIH (V) VOL (V) VOH (V) IOL IOH
最小 最大 最小 最大 最大 最小 (mA) (mA)
LVCMOS33 -0.3 0.8 2.0 Vccio+0.3 0.4 VCCIO–0.4
4 -4
8 -8
12 -12
16 -16
LVTTL33 -0.3 0.8 2.0 Vccio+0.3 0.4 2.4
4 -4
8 -8
12 -12
16 -16
LVCMOS25 -0.3 0.7 1.7 Vccio+0.3 0.4 VCCIO–0.4
4 -4
8 -8
12 -12
16 -16
LVCMOS18 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.45 VCCIO–0.45
4 -4
8 -8
12 -12
16 -16
LVCMOS15 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.25*Vccio 0.75* Vccio
4 -4
8 -8
12 -12
LVCMOS12 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.4 VCCIO–0.4
4 -4
8 -8
HSTL18_I -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 0.4 VCCIO–0.4 8 -8
HSTL_I -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 0.4 VCCIO–0.4 8 -8
SSTL18_I -0.3 VREF-0.125 VREF+0.125 Vccio+0.3 Vccio/2-0.47 Vccio/2+0.47 8 -8
SSTL15 -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.175 Vccio/2+0.175 13 -13
SSTL15_R -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.175 Vccio/2+0.175 8.9 -8.9
SSTL135 -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.15 Vccio/2+0.15 8.9 -8.9
SSTL12 -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.15 Vccio/2 +0.15 8 -8
POD12 -0.3 VREF-0.068 VREF+0.068 Vccio+0.3 - - - -
HSUL12 -0.3 VREF-0.13 VREF+0.13 Vccio+0.3 0.2*Vccio 0.8*Vccio 0.1 -0.1

<!-- 原 PDF 第 67 页 -->

表 3-21 IO 单端 I/O 标准规格(HD I/O)
标准
VIL (V) VIH (V) VOL (V) VOH (V) IOL IOH
最小 最大 最小 最大 最大 最小 (mA) (mA)
LVCMOS33 -0.3 0.8 2.0 Vccio+0.15 0.4 VCCIO–0.4
4 -4
8 -8
12 -12
16 -16
LVTTL33 -0.3 0.8 2.0 Vccio+0.15 0.4 2.4
4 -4
8 -8
12 -12
16 -16
LVCMOS25 -0.3 0.7 1.7 Vccio+0.3 0.4 VCCIO–0.4
4 -4
8 -8
12 -12
16 -16
LVCMOS18 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.45 VCCIO–0.45
4 -4
8 -8
12 -12
16 -16
LVCMOS15 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.25*Vccio 0.75* Vccio
4 -4
8 -8
12 -12
16 -16
表 3-22 IO 单端 I/O 标准规格(DDR I/O)
标准
VIL (V) VIH (V) VOL (V) VOH (V) IOL IOH
最小 最大 最小 最大 最大 最小 (mA) (mA)
LVCMOS18 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.45 VCCIO–0.45
2 -2
4 -4
6 -6
8 -8
12 -12
16 -16
LVCMOS15 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.25*Vccio 0.75* Vccio
2 -2
4 -4

<!-- 原 PDF 第 68 页 -->

标准
VIL (V) VIH (V) VOL (V) VOH (V) IOL IOH
最小 最大 最小 最大 最大 最小 (mA) (mA)
6 -6
8 -8
12 -12
LVCMOS12 -0.3 0.35*VCCIO 0.65*VCCIO Vccio+0.3 0.4 VCCIO–0.4
2 -2
4 -4
6 -6
8 -8
HSTL18_I -0.3 VREF-0.2 VREF+0.2 Vccio+0.3 0.4 VCCIO–0.4 8 -8
HSTL_I -0.3 VREF-0.2 VREF+0.2 Vccio+0.3 0.4 VCCIO–0.4 8 -8
SSTL18_I -0.3 VREF-0.25 VREF+0.25 Vccio+0.3 Vccio/2-0.47 Vccio/2+0.47 8 -8
SSTL15 -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.175 Vccio/2+0.175 13 -13
SSTL15_R -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.175 Vccio/2+0.175 8.9 -8.9
SSTL135 -0.3 VREF-0.135 VREF+0.135 Vccio+0.3 Vccio/2-0.15 Vccio/2+0.15 13 -13
SSTL12 -0.3 VREF-0.1 VREF+0.1 Vccio+0.3 Vccio/2-0.15 Vccio/2+0.15 13 -13
POD12 -0.3 VREF-0.068 VREF+0.068 Vccio+0.3 - - - -
HSUL12 -0.3 VREF-0.13 VREF+0.13 Vccio+0.3 0.2*Vccio 0.8*Vccio 0.1 -0.1
表 3-23 IO 单端 I/O 标准规格（MIPI I/O）
标准
VIL (V) VIH (V) VOL (V) VOH (V) IOL IOH
最小 最大 最小 最大 最大 最小 (mA) (mA)
LVCMOS18 -0.3 0.35*VCCIO 0.65*VCCIO VCCIO +0.3 0.45 VCCIO-0.45
4 -4
8 -8
12 -12
16 -16
LVCMOS12 -0.3 0.35*VCCIO 0.65*VCCIO VCCIO +0.3 - - - -

<!-- 原 PDF 第 69 页 -->

#### 3.1.10 差分I/O电学特性
##### 3.1.10.1 LVDS
表 3-24 LVDS 直流规格(HR I/O)
参 数 描 述 测试条件 最 小 典 型 最 大 单 位
VIP, VIN 输入电平
VCCIO=3.3 0.45 － 1.725 V
VCCIO=2.5 0.45 － 1.725 V
VCCIO=1.8 0.45 － 1.725 V
VID 输入差分摆幅 |VIP-VIN|, RT = 100 Ω 100 350 600 mV
VICM 输入共模电压
VCCIO=3.3 0.5 1.2 1.4 V
VCCIO=2.5 0.5 1.2 1.4 V
VCCIO=1.8 0.5 1.2 1.4 V
RT
片内端接差分电
阻
－ 65 100 135 Ω
VOD
标准差分输出摆
幅
VCCIO=2.5
|VOP – VON|, RT = 100 ohm
200 300 325 mV
VCCIO=1.8
|VOP – VON|, RT = 100 ohm
300 350 600 mV
VOCM 输出共模电压
VCCIO=2.5 1.0 1.2 1.35 V
VCCIO=1.8 0.9 1.1 1.2 V
表 3-25 LVDS 直流规格(DDR I/O)
参 数 描 述 测试条件 最 小 典 型 最 大 单 位
VIP, VIN 输入电平 VCCIO=1.8 0.45 － 1.725 V
VID 输入差分摆幅 |VIP-VIN| 100 350 600 mV
VICM 输入共模电压 VCCIO=1.8 0.5 - 1.425 V
注：
DDR I/O 内部无100Ω电阻
表 3-26 LVDS 直流规格（MIPI I/O）
参 数 描 述 测试条件 最小 典型 最大 单位
VID MIPI LVDS 输入差分摆幅
|VIP-VIN|，
RT = 100Ω
100 300 400 mV
RT MIPI LVDS 片内输入端接差分电阻 - 80 100 125 Ω

<!-- 原 PDF 第 70 页 -->

参 数 描 述 测试条件 最小 典型 最大 单位
VOD MIPI LVDS18 输出差分摆幅
|VOP-VON|，
RT = 100Ω
300 350 450 mV
VOCM MIPI LVDS18 输出共模电压 - 1000 1200 1300 mV
EQ MIPI LVDS18 去加重 - - -5 - dB
注：
VICM 规格请参见《UG1316_安路科技PH1P 系列FPGA MIPI 用户手册》中3.4 章节中表 3-9 LVDS RX
输入耦合设置
##### 3.1.10.2 SUB_LVDS
表 3-27 SUB_LVDS I/O 直流规格（HR I/O）
参 数 描 述 测试条件 最 小 典 型 最 大 单 位
VID 输入差分摆幅 |VIP-VIN|, RT = 100 Ω 70 - 600 mV
VICM 输入共模电压 VCCIO=1.8V 0.5 0.9 1.25 V
RT
片内端接差分电
阻
－ 65 100 135 Ω
VOD
标准差分输出摆
幅
VCCIO=1.8V
|VOP – VON|, RT = 100 ohm
100 150 200 mV
VOCM 输出共模电压 VCCIO=1.8 0.7 0.9 1.1 V
##### 3.1.10.3 MINI_LVDS
表 3-28 MINI_LVDS I/O 直流规格（HR I/O）
参 数 描 述 测试条件 最 小 典 型 最 大 单 位
VID 输入差分摆幅 |VIP-VIN|, RT = 100 Ω 200 - 600 mV
VICM 输入共模电压 VCCIO=2.5V 0.3 1.2 1.425 V
RT
片内端接差分电
阻
－ 65 100 135 Ω
VOD
标准差分输出摆
幅
VCCIO=2.5V
|VOP – VON|, RT = 100 ohm
200 300 325 mV
VOCM 输出共模电压 VCCIO=2.5V 1 1.2 1.4 V

<!-- 原 PDF 第 71 页 -->

##### 3.1.10.4 TMDS33
表 3-29 TMDS33 I/O 直流规格（HR I/O）
参 数 描 述 测试条件 最 小 典 型 最 大 单 位
VIP,VIN 输入电平
VCCIO=3.3，
上拉电阻50Ω
2.63 － 3.3 V
VID 输入差分摆幅 |VIP-VIN| 150 675 1200 mV
VICM 输入共模电压 VCCIO=3.3 2.7 2.965 3.23 V
VOD 标准差分输出摆幅
VCCIO=3.3
|VOP–VON|
400 600 800 mV
VOCM 输出共模电压 VCCIO=3.3 VCCIO–0.405 VCCIO–0.3 VCCIO–0.19 V
##### 3.1.10.5 POD12
表 3-30 单端和差分 POD12 电平标准的直流输出电平(HR I/O)
参 数 描 述
1
VOUT
2
最 小 典 型 最 大 单 位
ROL 下拉电阻 VOM_DC 26 40 54 Ω
ROH 上拉电阻 VOM_DC 26 40 54 Ω
注：
POD12 电平的测试条件为FPGA 侧的I/O 内部终端阻抗设置为40ohm
VOUT 条件参照下表中的描述定义。
表 3-31 单端和差分 POD12 标准的直流输出电平定义(HR I/O)
参 数 描 述 典 型 单 位
VOM_DC DC 输出中间测量电平（IV 曲线线性度） 0.8*VCCIO V
表 3-32 单端和差分 POD12 电平标准的直流输出电平(DDR I/O)
参 数 描 述
1
VOUT
2
最 小 典 型 最 大 单 位
ROL 下拉电阻 VOM_DC 37 40 48 Ω
ROH 上拉电阻 VOM_DC 37 40 48 Ω
注：
POD12 电平的测试条件为FPGA 侧的I/O 内部终端阻抗设置为40ohm。
VOUT 条件参照下表中的描述定义。

<!-- 原 PDF 第 72 页 -->

表 3-33 单端和差分 POD12 标准的直流输出电平定义(DDR I/O)
参 数 描 述 典 型 单 位
VOM_DC DC 输出中间测量电平（IV 曲线线性度） 0.8*VCCIO V
##### 3.1.10.6 LVDS_E
表 3-34 IO 单端 I/O 标准规格(HR I/O)
标准
VOL (V) VOH (V) IOL IOH
最大 最小 (mA) (mA)
LVDS33_E 0.4 VCCIO–0.4
8 -8
12 -12
16 -16
LVDS25_E 0.4 VCCIO–0.4
8 -8
12 -12
16 -16
LVDS18_E 0.45 VCCIO–0.45
8 -8
12 -12
16 -16
表 3-35 IO 单端 I/O 标准规格(HD I/O)
标准
VOL (V) VOH (V) IOL IOH
最大 最小 (mA) (mA)
LVDS33_E 0.4 VCCIO–0.4
8 -8
12 -12
16 -16
LVDS25_E 0.4 VCCIO–0.4
8 -8
12 -12
16 -16
LVDS18_E 0.45 VCCIO–0.45
8 -8
12 -12
16 -16

<!-- 原 PDF 第 73 页 -->

表 3-36 IO 单端 I/O 标准规格(DDR I/O)
标准
VOL (V) VOH (V) IOL IOH
最大 最小 (mA) (mA)
LVDS18_E 0.45 VCCIO–0.45
8 -8
12 -12
16 -16
##### 3.1.10.7 其他
表 3-37 差分 I/O 直流规格(HR I/O)
标准
VICM
1
(V) VID
2
(V) VOL
3
(V) VOH
4
(V) IOL IOH
最小 典型 最大 最小 最大 最大 最小 (mA) (mA)
DIFF_HSTL18_I 0.5 VCCIO/2 1.425 0.1 - 0.4 VCCIO–0.4 8 -8
DIFF_HSTL_I 0.5 VCCIO/2 1.125 0.1 - 0.4 VCCIO–0.4 8 -8
DIFF_SSTL18_I 0.5 VCCIO/2 1.425 0.1 - VCCIO/2–0.47 VCCIO/2+0.47 8 -8
DIFF_SSTL15 0.5 VCCIO/2 1.125 0.1 - VCCIO/2–0.175 VCCIO/2+0.175 13 -13
DIFF_SSTL15_R 0.5 VCCIO/2 1.125 0.1 - VCCIO/2–0.175 VCCIO/2+0.175 8.9 -8.9
DIFF_SSTL135 0.5 VCCIO/2 1 0.1 - VCCIO/2–0.15 VCCIO/2+0.15 8.9 -8.9
DIFF_SSTL12 0.5 VCCIO/2 0.85 0.1 - VCCIO/2–0.15 VCCIO/2+0.15 8 -8
DIFF_POD12 0.76 0.84 0.92 0.16 - - - - -
DIFF_HSUL12 0.5 VCCIO/2 0.85 0.1 - 0.2*VCCIO 0.8*VCCIO 0.1 -0.1
注：
VICM 为输入的共模电压。
VID 为输入差分摆幅（VIP-VIN）。
VOL 为单端输出的低电平电压。
VOH 为单端输出的高电平电压。
表 3-38 差分 I/O 直流规格(DDR I/O)
标准
VICM
1
(V) VID
2
(V) VOL
3
(V) VOH
4
(V) IOL IOH
最小 典型 最大 最小 最大 最大 最小 (mA) (mA)
DIFF_HSTL18_I 0.5 0.9 1.425 0.1 - 0.4 VCCIO–0.4 8 -8
DIFF_HSTL_I 0.5 VCCIO/2 1.125 0.1 - 0.4 VCCIO–0.4 13 -13
DIFF_SSTL18_I 0.5 0.9 1.425 0.1 - VCCIO/2–0.47 VCCIO/2+0.47 8 -8
DIFF_SSTL15 0.5 VCCIO/2 1.125 0.1 - VCCIO/2–0.175 VCCIO/2+0.175 13 -13
DIFF_SSTL15_R 0.5 VCCIO/2 1.125 0.1 - VCCIO/2–0.175 VCCIO/2+0.175 8.9 -8.9

<!-- 原 PDF 第 74 页 -->

标准
VICM
1
(V) VID
2
(V) VOL
3
(V) VOH
4
(V) IOL IOH
最小 典型 最大 最小 最大 最大 最小 (mA) (mA)
DIFF_SSTL135 0.5 0.675 1 0.1 - VCCIO/2–0.15 VCCIO/2+0.15 13 -13
DIFF_SSTL12 0.5 0.6 0.85 0.1 - VCCIO/2–0.15 VCCIO/2+0.15 13 -13
DIFF_HSUL12 0.5 VCCIO/2 0.85 0.1 - 0.2*VCCIO 0.8*VCCIO 0.1 -0.1
DIFF_POD12 0.76 0.84 0.92 0.16 - - - - -
注：
VICM 为输入的共模电压。
VID 为输入差分摆幅（VIP-VIN）。
VOL 为单端输出的低电平电压。
VOH 为单端输出的高电平电压。
#### 3.1.11 MIPI
##### 3.1.11.1 MIPI RX
表 3-39 MIPI RX 直流特性
参 数 描 述 最 小 典 型 最 大 单 位
HS Receiver
VCMRX(DC) 高速接收模式共模电压 70 - 330 mV
ZID 差分输入阻抗 80  100 125 Ω
ZID_open 关闭端接的差分输入阻抗 10，000 - - Ω
LP Receiver
VIH 逻辑 1 输入电压 740 - - mV
VIL
逻辑 0 输入电压
（不处于ULP 状态）
- - 550 mV
VHYST 输入迟滞电压 25 - - mV
LP Transmitter
VOHLP 输出高电平 0.95 1.2 1.3 V
VOLLP 输出低电平 -50 - 50 mV
ZOLP 输出阻抗 110 - - Ω

<!-- 原 PDF 第 75 页 -->

##### 3.1.11.2 MIPI TX
表 3-40 MIPI TX 直流特性
参 数 描 述 最 小 典 型 最 大 单 位
HS Transmitter
VCMTX HS TX 静态共模电压 150 200 250 mV
|△VCMTX|
VCMTX 差分输出共模电压变
化
- - 5 mV
VOD HS TX 差分电压 140 200 270 mV
|△VOD| VOD 差分输出摆幅变化 - - 14 mV
VOHHS HS 输出高电压 - - 360 mV
ZOS 单端输出阻抗 40 50 62.5 Ω
△ZOS 单端输出阻抗失配 - - 20 %
EQTX1 TX 端去加重1 4 4.5 5 dB
EQTX2 TX 端去加重2 6 7 8 dB
LP Transmitter
VOHLP LP 模式输出高电平 0.95 1.2 1.3 V
VOLLP LP 模式输出低电平 -50 - 50 mV
ZOLP LP 模式输出阻抗 110 - - Ω
LP Receiver
VIH 逻辑 1 输入电压 740 - - mV
VIL
逻辑0 输入电压（不处
于 ULP 状态）
- - 550 mV
VHYST 输入迟滞电压 25 - - mV

<!-- 原 PDF 第 76 页 -->

### 3.2 交流电气特性
本章节提供PH1P 核心和周边模块的性能参数，时序参数及其典型值是常规的设计重要参数，也是
器件的基本性能参数。这些参数反映了器件在最差条件下的实际性能。
PH1P35MEG324A 器件规格请以其正式发布版本为准。
#### 3.2.1 时钟性能
表 3-41 最大时钟操作频率
参数 描述 性能 单位
GCLK 全局时钟 PH1P100、PH1P35 480 Mhz
IOCLK I/O 时钟 PH1P100、PH1P35 650 Mhz
LCLK 本地时钟 PH1P100、PH1P35 400 Mhz
MLCLK 多区域时钟 PH1P100、PH1P35 650 Mhz
注：
LCLK 输入的最大时钟操作频率与IOCLK 相同
当IO 使用LVDS 电平，且数据与时钟非同源时，IOCLK 和MLCLK 最高支持580MHz。
表 3-42 时钟最大 skew
参数 描述 性能 单位
TGCLK 全局时钟
PH1P1OO 0.3 ns
PH1P35 0.24 ns
TIOCLK I/O 时钟 20 ps
TLCLK 本地时钟 110 ps
TMLCLK 多区域时钟 10 ps
#### 3.2.2 嵌入数字信号处理模块（DSP）规格
表 3-43 嵌入 DSP 规格
器 件 模式 性能 单位
PH1P
在所有寄存器使用情况下 500 MHz
用作乘法器且无MREG 情况下 303 MHz
无ABREG 情况下 363 MHz
无流水寄存器（MREG 和 ABREG）情况下 259 MHz
在所有寄存器均不使用情况下 180 MHz

<!-- 原 PDF 第 77 页 -->

#### 3.2.3 存储器模块（ERAM）规格
表 3-44 存储器模块规格表
模式 器件 性 能 单 位
Clk to dout(无寄存器模式)
PH1P100 1.85 ns
PH1P35 1.75 ns
Clk to dout(寄存器模式)
PH1P100 0.56 ns
PH1P35 0.5 ns
Clk to dout with ECC (无寄存器模式)
PH1P100 2.36 ns
PH1P35 2.05 ns
Clk to dout with ECC (寄存器模式)
PH1P100 0.56 ns
PH1P35 0.5 ns
Fmax (Write Only) 400 MHz
Fmax(FIFO) 400 MHz
Fmax (RBW-SDP) PH1P1OO、PH1P35 350 MHz
Fmax(In ECC Mode) 400 MHz
#### 3.2.4 锁相环(PLL)规格
表 3-45 PLL 规格
参 数 描 述 最小 典型 最大 单位
FIN 输入时钟频率 10 － 600 MHz
FPFD
鉴频鉴相器（PFD）输入频率，整数分频 10 － 600 MHz
鉴频鉴相器（PFD）输入
频率，小数分频
4
PH1P100 10 － 100 MHz
PH1P35 10 - 200 MHz
FVCO 锁相环内部振荡器频率范围 800 － 1600 MHz
FOUT 输出时钟频率 6.25 － 800 MHz
交流特性
FINDUTY
输入时钟占空比, 10MHz≤FIN＜50MHz 25 － 75 %
输入时钟占空比, 50MHz≤FIN＜200MHz 30 - 70 %
输入时钟占空比, 200MHz≤FIN＜400MHz 35 - 65 %
输入时钟占空比, 400MHz≤FIN＜500MHz 40 - 60 %
输入时钟占空比, 500MHz≤FIN≤600MHz 45 - 55 %
TINJITTER
1
输入时钟抖动，100MHz≤ fPFD ≤600MHz － － 300
ps
p-p
输入时钟抖动，10MHz≤fPFD ＜100MHz － － 1000
ps
p-p

<!-- 原 PDF 第 78 页 -->

参 数 描 述 最小 典型 最大 单位
TOUTDUTY 输出时钟占空比 45 － 55 %
phase
noise
FVCO=800MHz,bandwidth
setting to 0.4MHz
100KHz － － -57
dBc/
Hz
1MHz － － -81.5
dBc/
Hz
10MHz － － -98
dBc/
Hz
FVCO=800MHz,bandwidth
setting to 4MHz
100KHz － － -95
dBc/
Hz
1MHz － － -98
dBc/
Hz
10MHZ － － -105
dBc/
Hz
FVCO=1600MHz,bandwidth
setting to 0.4MHz
100KHz － － -57
dBc/
Hz
1MHZ － － -83.4
dBc/
Hz
10MHZ － － -100
dBc/
Hz
FVCO=1600MHz,bandwidth
setting to 4MHz
100KHz － － -92
dBc/
Hz
1MHZ － － -94.3
dBc/
Hz
10MHZ － － -104
dBc/
Hz
TLOCK
2
PLL 锁定时间，10≤FPFD＜50MHz － － 300 us
PLL 锁定时间，50≤FPFD＜100MHz － － 200 us
PLL 锁定时间，100≤FPFD － － 150 us
TSTATPHAOFFSET
3
PLL 输出的静态相位偏移，
6.25MHz≤fOUT≤800MHz
－ － 0.1 ns
SSC
SSC amplitude -3 - 3 %
FMODULATION 25 - 250 KHz
SSC 模式的PFD CLK 25 － 50 MHz
FPSCLK 动态相位移动时钟 0.01 － 100 MHz
TRST 复位脉冲最小宽度 5 － - ns
FDRP 动态配置时钟 - － 100 MHz

<!-- 原 PDF 第 79 页 -->

参 数 描 述 最小 典型 最大 单位
FBANDWIDTH
PLL 低带宽 - 0.4 - MHz
PLL 高带宽 - 4 - MHz
注：
参考时钟允许的最大输入抖动。为得到低抖动的输出时钟，必须提供干净的参考时钟。PLL 不会滤
掉低频输入噪声，PLL 会滤掉部分高频输入噪声。
TLOCK 之后，在输出端得到稳定时钟。
设置相同相位，PLL 不同通道输出之间的相位差。
鉴频鉴相器 （PFD） 输入频率， 小数分频功能使用限制请参考《UG1306_安路科技PH1P 系列FPGA_PLL
用户手册》
#### 3.2.5 CLOCK ALIGNER规格
表 3-46 CLOCK ALIGNER
参数 描 述 最小 典型 最大 单位
FIN 输入时钟频率 50 － 500 MHz
FOUT 输出时钟频率 50 － 500 MHz
FVCO 锁相环内部振荡器频率范围 1.25 － 2.5 GHz
TIN_PERIOD_JITTER 输入时钟周期抖动 － － 100 ps
TOUTDUTY 输出时钟占空比 48 － 52 %
TLOCK PLL 锁定时间 － － 20000
cycle
（FIN）
TOUT_INCREASED_PERIOD_JITTER 输出时钟周期抖动
1
50MHz≤FOUT≤100MHz - － 50 ps
100MHz＜FOUT≤200MHz - － 25 ps
200MHz＜FOUT≤400MHz - － 15 ps
400MHz＜FOUT≤500MHz - － 10 ps
TSKEW 输入时钟与输出时钟相位偏差 － － 20 ps
注：
输出时钟周期抖动需叠加输入时钟周期抖动
例如：输入时钟周期抖动为100 ps，输出时钟（50M）周期抖动为100 ps+50 ps

<!-- 原 PDF 第 80 页 -->

#### 3.2.6 TVS指标
表 3-47 TVS 模块指标
描述 最小 典型 最大 单位
温度精度 － － ±5
o
C
电压精度 － － ±3 %
时钟频率 0.8 1 1.5 MHz
时钟占空比 40 － 60 %
最小脉冲宽度（ENA 低电平脉冲宽度） 1 － － cycle
转换时间 － 400000 － cycle
采样位宽 － 10 － bit
TENA_VSAMPLE
1
10 - - ns
注：
VSAMPLE 信号在ENA 为高期间不得变化， 否则造成VSAMPLE 变化后的输出数据错误。TENA_VSAMPLE 是TVS
模块的 ENA 信号跳变前 VSAMPLE 信号的最小保持时间。时序图参见《UG1308_安路科技 PH1P 系列
FPGA TVS 用户手册》。
#### 3.2.7 I/O接口性能
I/O 所支持的最高接口频率和外部硬件相关，如需满足下表最大规格要求，需要进行IBIS 模型仿
真。
##### 3.2.7.1 HR I/O
表 3-48 I/O 接口性能表（HR I/O 输入）
输入标准 描 述 最 大 单 位
LVDS33 LVDS, VCCIO = 3.3V 1250 Mbps
LVDS25 LVDS, VCCIO = 2.5V 1250 Mbps
LVDS18 LVDS, VCCIO = 1.8V 1250 Mbps
SUB_LVDS SUB_LVDS, VCCIO = 1.8V 1250 Mbps
MINI_LVDS MINI_LVDS, VCCIO = 2.5V 1250 Mbps
LVTTL33 LVTTL, VCCIO = 3.3V 332 Mbps
LVCMOS33 LVCMOS, VCCIO = 3.3V 332 Mbps
LVCMOS25 LVCMOS, VCCIO = 2.5V 332 Mbps
LVCMOS18 LVCMOS, VCCIO = 1.8V 332 Mbps
LVCMOS15 LVCMOS, VCCIO = 1.5V 332 Mbps
LVCMOS12 LVCMOS, VCCIO = 1.2V 332 Mbps

<!-- 原 PDF 第 81 页 -->

输入标准 描 述 最 大 单 位
HSUL12 HSUL，VCCIO = 1.2V 800 Mbps
HSTL18_I HSTL，VCCIO = 1.8V 800 Mbps
HSTL_I HSTL，VCCIO = 1.5V 800 Mbps
SSTL18_I SSTL，VCCIO = 1.8V 800 Mbps
SSTL15 SSTL，VCCIO = 1.5V 800 Mbps
SSTL135 SSTL，VCCIO = 1.35V 800 Mbps
SSTL12 SSTL，VCCIO = 1.2V 800 Mbps
SSTL15_R SSTL_R，VCCIO = 1.5V 800 Mbps
POD12 POD, VCCIO = 1.2V 800 Mbps
DIFF_HSUL12 HSUL，VCCIO = 1.2V 800 Mbps
DIFF_HSTL18_I HSTL，VCCIO = 1.8V 800 Mbps
DIFF_HSTL_I HSTL，VCCIO = 1.5V 800 Mbps
DIFF_SSTL18_I SSTL，VCCIO = 1.8V 800 Mbps
DIFF_SSTL15 SSTL，VCCIO = 1.5V 800 Mbps
DIFF_SSTL135 SSTL，VCCIO = 1.35V 800 Mbps
DIFF_SSTL12 SSTL，VCCIO = 1.2V 800 Mbps
DIFF_SSTL15_R SSTL_R，VCCIO = 1.5V 800 Mbps
DIFF_POD12 POD, VCCIO = 1.2V 800 Mbps
TMDS33 TMDS, VCCIO = 3.3V 1250 Mbps
表 3-49 I/O 接口性能表（HR I/O 输出）
输出标准 描 述 最 大 单 位
LVDS33_E
1
LVDS_E,VCCIO = 3.3V 332 Mbps
LVDS25_E
1
LVDS_E,VCCIO = 2.5V 332 Mbps
LVDS18_E
1
LVDS_E,VCCIO = 1.8V 332 Mbps
LVDS25 LVDS,VCCIO = 2.5V 1250 Mbps
LVDS18 LVDS,VCCIO = 1.8V 1250 Mbps
SUB_LVDS SUB_LVDS,VCCIO = 1.8V 1250 Mbps
MINI_LVDS MINI_LVDS,VCCIO = 2.5V 1250 Mbps
LVTTL33 LVTTL,VCCIO = 3.3V 332 Mbps
LVCMOS33 LVCMOS,VCCIO = 3.3V 332 Mbps
LVCMOS25 LVCMOS,VCCIO = 2.5V 332 Mbps
LVCMOS18 LVCMOS,VCCIO = 1.8V 332 Mbps
LVCMOS15 LVCMOS,VCCIO = 1.5V 240 Mbps
LVCMOS12 LVCMOS,VCCIO = 1.2V 200 Mbps
HSUL12 HSUL，VCCIO = 1.2V 800 Mbps
HSTL18_I HSTL，VCCIO = 1.8V 800 Mbps
HSTL_I HSTL，VCCIO = 1.5V 800 Mbps

<!-- 原 PDF 第 82 页 -->

输出标准 描 述 最 大 单 位
SSTL18_I SSTL，VCCIO = 1.8V 800 Mbps
SSTL15 SSTL，VCCIO = 1.5V 800 Mbps
SSTL135 SSTL，VCCIO = 1.35V 800 Mbps
SSTL12 SSTL，VCCIO = 1.2V 800 Mbps
SSTL15_R SSTL_R，VCCIO = 1.5V 800 Mbps
POD12 POD,VCCIO = 1.2V 800 Mbps
DIFF_HSUL12 HSUL，VCCIO = 1.2V 800 Mbps
DIFF_HSTL18_I HSTL，VCCIO = 1.8V 800 Mbps
DIFF_HSTL_I HSTL，VCCIO = 1.5V 800 Mbps
DIFF_SSTL18_I SSTL，VCCIO = 1.8V 800 Mbps
DIFF_SSTL15 SSTL，VCCIO = 1.5V 800 Mbps
DIFF_SSTL135 SSTL，VCCIO = 1.35V 800 Mbps
DIFF_SSTL12 SSTL，VCCIO = 1.2V 800 Mbps
DIFF_SSTL15_R SSTL_R，VCCIO = 1.5V 800 Mbps
DIFF_POD12 POD, VCCIO = 1.2V 800 Mbps
TMDS33 TMDS,VCCIO = 3.3V 1250 Mbps
注：
作为INOUT 功能的输入频率与对应的LVDS 的输入频率相同。
##### 3.2.7.2 HD I/O
表 3-50 I/O 接口性能表（HD I/O 输入）
输入标准 描 述 最 大 单 位
LVTTL33 LVTTL, VCCIO = 3.3V 300 Mbps
LVCMOS33 LVCMOS, VCCIO = 3.3V 300 Mbps
LVCMOS25 LVCMOS, VCCIO = 2.5V 300 Mbps
LVCMOS18 LVCMOS, VCCIO = 1.8V 300 Mbps
LVCMOS15 LVCMOS, VCCIO = 1.5V 300 Mbps
表 3-51 I/O 接口性能表（HD I/O 输出）
输出标准 描 述 最 大 单 位
LVDS33_E LVDS_E,VCCIO = 3.3V 300 Mbps
LVDS25_E LVDS_E,VCCIO = 2.5V 300 Mbps
LVDS18_E LVDS_E,VCCIO = 1.8V 300 Mbps
LVTTL33 LVTTL,VCCIO = 3.3V 300 Mbps
LVCMOS33 LVCMOS,VCCIO = 3.3V 300 Mbps
LVCMOS25 LVCMOS,VCCIO = 2.5V 300 Mbps

<!-- 原 PDF 第 83 页 -->

输出标准 描 述 最 大 单 位
LVCMOS18 LVCMOS,VCCIO = 1.8V 300 Mbps
LVCMOS15 LVCMOS,VCCIO = 1.5V 300 Mbps
##### 3.2.7.3 DDR I/O
表 3-52 I/O 接口性能表（DDR I/O 输入）
输入标准 描 述 最 大 单 位
LVDS18 LVDS, VCCIO = 1.8V 1500 Mbps
LVCMOS18 LVCMOS, VCCIO = 1.8V 332 Mbps
LVCMOS15 LVCMOS, VCCIO = 1.5V 332 Mbps
LVCMOS12 LVCMOS, VCCIO = 1.2V 332 Mbps
HSTL18_I HSTL，VCCIO = 1.8V 1066 Mbps
HSTL_I HSTL，VCCIO = 1.5V 1066 Mbps
SSTL18_I SSTL，VCCIO = 1.8V 1066 Mbps
SSTL15 SSTL，VCCIO = 1.5V 1066 Mbps
SSTL15_R SSTL，VCCIO = 1.5V 1066 Mbps
SSTL135 SSTL，VCCIO = 1.35V 1066 Mbps
SSTL12 SSTL，VCCIO = 1.2V 1066 Mbps
POD12 POD, VCCIO = 1.2V 1066 Mbps
HSUL12 HSUL，VCCIO = 1.2V 1066 Mbps
DIFF_HSTL18_I HSTL，VCCIO = 1.8V 1066 Mbps
DIFF_HSTL_I HSTL，VCCIO = 1.5V 1066 Mbps
DIFF_SSTL18_I SSTL，VCCIO = 1.8V 1066 Mbps
DIFF_SSTL15 SSTL，VCCIO = 1.5V 1066 Mbps
DIFF_SSTL15_R SSTL，VCCIO = 1.5V 1066 Mbps
DIFF_SSTL135 SSTL，VCCIO = 1.35V 1066 Mbps
DIFF_SSTL12 SSTL，VCCIO = 1.2V 1066 Mbps
DIFF_POD12 POD, VCCIO = 1.2V 1066 Mbps
DIFF_HSUL12 HSUL，VCCIO = 1.2V 1066 Mbps
表 3-53 I/O 接口性能表（DDR I/O 输出）
输出标准 描 述 最 大 单 位
LVDS18_E
1
LVDS_E,VCCIO = 1.8V 332 Mbps
LVCMOS18 LVCMOS,VCCIO = 1.8V 332 Mbps
LVCMOS15 LVCMOS,VCCIO = 1.5V 332 Mbps
LVCMOS12 LVCMOS,VCCIO = 1.2V 332 Mbps
HSUL12 HSUL，VCCIO = 1.2V 1066 Mbps
HSTL18_I HSTL，VCCIO = 1.8V 1066 Mbps

<!-- 原 PDF 第 84 页 -->

输出标准 描 述 最 大 单 位
HSTL_I HSTL，VCCIO = 1.5V 1066 Mbps
SSTL18_I SSTL，VCCIO = 1.8V 1066 Mbps
SSTL15 SSTL，VCCIO = 1.5V 1066 Mbps
SSTL15_R SSTL，VCCIO = 1.5V 1066 Mbps
SSTL135 SSTL，VCCIO = 1.35V 1066 Mbps
SSTL12 SSTL，VCCIO = 1.2V 1066 Mbps
POD12 POD,VCCIO = 1.2V 1066 Mbps
DIFF_HSUL12 HSUL，VCCIO = 1.2V 1066 Mbps
DIFF_HSTL18_I HSTL，VCCIO = 1.8V 1066 Mbps
DIFF_HSTL_I HSTL，VCCIO = 1.5V 1066 Mbps
DIFF_SSTL18_I SSTL，VCCIO = 1.8V 1066 Mbps
DIFF_SSTL15 SSTL，VCCIO = 1.5V 1066 Mbps
DIFF_SSTL15_R SSTL，VCCIO = 1.5V 1066 Mbps
DIFF_SSTL135 SSTL，VCCIO = 1.35V 1066 Mbps
DIFF_SSTL12 SSTL，VCCIO = 1.2V 1066 Mbps
DIFF_POD12 POD, VCCIO = 1.2V 1066 Mbps
注：
作为INOUT 功能的输入频率与对应的LVDS 的输入频率相同
##### 3.2.7.4 MIPI I/O
表 3-54 I/O 接口性能表（MIPI I/O 输入）
输入标准 描 述 最 大 单 位
MIPI DPHY
MIPI LP 10 Mbps
MIPI HS 2.5 Gbps
LVDS 1.5 Gbps
LVCMOS18 300 Mbps
LVCMOS12 300 Mbps
表 3-55 I/O 接口性能表（MIPI I/O 输出）
输出标准 描 述 最 大 单 位
MIPI DPHY
MIPI LP 10 Mbps
MIPI HS 2.5 Gbps
LVDS18 1.5 Gbps
LVCMOS18 300 Mbps

<!-- 原 PDF 第 85 页 -->

#### 3.2.8 配置模块
表 3-56 配置模式时序规格表
下载模式 器件 模式 最 小 典 型 最 大 单 位
从动串行（Slave Serial） PH1P － 2 － 100 MHz
主动串行（Master Serial） PH1P － 2 － 33 MHz
主动SPI
CCLK 时钟源为OSC PH1P
x1 2 － 33 MHz
x2 2 － 33 MHz
x4 2 － 33 MHz
CCLK 时钟源为USRCLK
4
PH1P35
x1 2 － FCLK_USRCLK MHz
x2 2 － FCLK_USRCLK MHz
x4 2 － FCLK_USRCLK MHz
主动并行
（Master Parallel）
PH1P
x8 2 － 33 MHz
x16 2 － 33 MHz
从动并行(Slave Parallel) PH1P
x8 2 － 100 MHz
x16 2 － 100 MHz
x32 2 － 100 MHz
JTAG
PH1P100 － 0.1 － 25 MHz
PH1P35 － 0.1 － 40 MHz
ECC 工作频率
PH1P － - － 11 MHz
MULTI BOOT 使能脉冲宽度
3
PH1P － 1 － － us
OSC
1
PH1P － － 266 － MHz
注：
OSC 输出时钟最大偏差在±10%以内，对时钟精度要求较高的场景不建议使用。
JTAG 或 SP 模式回读时，最高频率为11 MHz。
PH1P100 器件：multiboot_en_n_i 接收到下降沿时，加载multiboot_addr_i 对应的位流。注意下
降沿后的低电平需要满足以上条件。
PH1P35 器件：当 multiboot_en_i 接收到上升沿时，加载 multiboot_addr_i 对应的位流。注意上
升沿后的高电平需要满足以上条件。
1/(FCLK_USRCLK×（1+FTOLMAX_USRCLK）)≥(T1+T2+TCLQV)+T_dsu
具体参数说明详见表 2-11 FCLK_USRCLK 公式参数

<!-- 原 PDF 第 86 页 -->

#### 3.2.9 External Memory Interface
表 3-57 External Memory Interface 性能
器 件 模式 性能 单位
PH1P100
DDR3 800 Mbps
DDR4 800 Mbps
PH1P35
DDR2 800 Mbps
DDR3 800 Mbps
DDR4 800 Mbps
DDR4 800 Mbps
#### 3.2.10 Integrated Memory Interface
表 3-58 Integrated Memory Interface 性能
器 件 性能（Mbps）
PH1P35MDG324 1066
PH1P35MHG324 1066
#### 3.2.11 MIPI
##### 3.2.11.1 MIPI RX
表 3-59 MIPI RX 交流特性
参 数 描 述 最 小 典 型 最 大 单 位
HS Receiver
VIDTH
高电平差分输入阈值电压（≤1.5Gbps） - - 70 mV
高电平差分输入阈值电压（＞1.5Gbps） - - 40 mV
VIDTL
低电平差分输入阈值电压（≤1.5Gbps） -70 - - mV
低电平差分输入阈值电压（＞1.5Gbps） -40 - - mV
VIHHS 高电平单端输入电压（≤1.5Gbps） - - 460 mV
VILHS 低电平单端输入电压（＞1.5Gbps） -40 - - mV
△VCMTX(HF)
共模干扰超过450MHz
（Data Rate≤1.5Gbps）
- - 100 mV
共模干扰超过450MHz
（Data Rate＞1.5Gbps）
- - 50 mV
△VCMTX(LF)
共模干扰50MHz-450MHz
（Data Rate≤1.5Gbps）
-50 - 50 mV

<!-- 原 PDF 第 87 页 -->

共模干扰50MHz-450MHz
（Data Rate＞1.5Gbps）
-25 - 25 mV
ILMAX 支持的最大插损 6.8 - - dB
TCLK_RDY
LP 切换到HS mode，clock Lane 的稳定时
间
- - 250 ns
LP Receiver
eSPIKE 输入脉冲抑制 - - 300 V.ps
TMIN_RX 最小脉宽响应 20 - - ns
VINT 峰值干扰振幅 - - 200 mV
fINT 干扰频率 450 - - MHz
##### 3.2.11.2 MIPI TX
表 3-60 MIPI TX 交流特性
参 数 描 述 最 小 典 型 最 大 单 位
HS Transmitter
△VCMTX(HF) HS TX 共模电平变化（＞450MHz） - - 15 mV
△VCMTX(LF) HS TX 共模电平变化（50MHz-450MHz） - - 25 mV
LP Receiver
eSPIKE 输入脉冲抑制 - - 300 V.ps
TMIN_RX 最小脉宽响应 20 - - ns
VINT 峰值干扰振幅 - - 200 mV
fINT 干扰频率 450 - - MHz
#### 3.2.12 MCU
表 3-61 MCU 规格
器 件 时钟 性能 单位
PH1P35
core clk 300 MHz
timer clk 100 MHz
apb clk 50 MHz

<!-- 原 PDF 第 88 页 -->

### 3.3 HXT串行收发器直流交流特性和规格
本章节提供 PH1P 系列 FPGA 的 HXT 串行收发器的直流特性和交流特性，这些参数反映了器件在最
差条件下的实际性能。
#### 3.3.1 HXT串行收发器的直流参数
下表概括了PH1P 系列FPGA 的HXT 串行收发器的直流参数和规格。
表 3-62 HXT 串行收发器直流参数规格
参数 描述 条件 Min Typ Max
单
位
DVPPOUT
差分输出电压
峰峰值
1
发送器摆幅设置为最大 － 1100 － mV
VCMOUTDC 共模输出电压 － － 550 － mV
ROUT 差分输出阻抗 － － 100 － Ω
DVPPIN
RX 差分输入峰
峰值
AC 耦合 200 － 1350 mV
VIN 单端输入电压
2
DC 耦合 -200 － 1200 mV
VCMIN
共模输入电压
（GND）
DC 耦合 － － 300 mV
共模输入电压
（POWER）
DC 耦合 600 － － mV
共模输入电压
（FLOATING）
DC 耦合 0 － 900 mV
RIN 差分输入阻抗 － － 100 － Ω
CEXT
推荐外部AC 耦
合电容
3
－ － 100 － nF
DVRECCLK
恢复时钟输出
电压峰峰值
近端远端都开端接电阻 400 700 800 mV
仅远端打开端接电阻 800 1000 1300 mV
VCMRECCLK
恢复时钟输出
共模电压
近端远端都开端接电阻
到地时
200 350 400 mV
RRESREF
外部参考电阻
阻值
精度
要求
+/-
1%
PH1P100SBG676 － 200 － Ω
PH1P100SBG677、
PH1P100SBG484
－ 100 － Ω
IRESREFMAX
外部参考电阻
最大电流
－ － － 2 mA

<!-- 原 PDF 第 89 页 -->

参数 描述 条件 Min Typ Max
单
位
CRESREFLOAD
外部参考电阻
PCB 走线寄生电
容
－ － － 10 pF
RRESREFROUTE
外部参考电阻
PCB 走线寄生电
阻
－ － － 1 Ω
注：
输出摆幅和预加重电平可编程，此处为设置最大摆幅情况下的实际测量值。
测量从管脚到地的电压。
自定义协议遵照此表。标准协议规范， 请参考《UG1307_安路科技PH1P 系列FPGA 硬件设计指南》。
#### 3.3.2 HXT串行收发器的交流参数
下表概括了PH1P 系列FPGA 的HXT 串行收发器的性能参数。
表 3-63 HXT 串行收发器性能参数
参数 描述 器件 最小值 最大值 单位
FMAXRATE 最高线速率 PH1P100 - 10.3125 Gbps
FMINRATE 最低线速率 PH1P 500 - Mbps
FPLLRANGE
COMMON PLL 输出频率范围 PH1P 7 8 GHz
LANE PLL 输出频率范围 PH1P100 3.25 6.6 GHz
#### 3.3.3 HXT串行收发器APB接口时钟性能
下表给出HXT 串行收发器的APB（Advanced Peripheral Bus）接口时钟最高频率
表 3-64 APB 接口交流特性
参数 描述 数值 单位
FAPBCLKMAX APB 接口时钟最高频率 150 Mhz
#### 3.3.4 HXT串行收发器PLL和CDR性能
下表概括HXT 串行收发器PLL 和CDR 的锁定时间
表 3-65 HXT 串行收发器 PLL 锁定时间
参数 描述 条件 Min Typ Max 单位
TLOCK PLL 锁定时间
COMMON PLL － － 1 ms
LANE PLL － － 1 ms

<!-- 原 PDF 第 90 页 -->

参数 描述 条件 Min Typ Max 单位
TDLOCK
CDR 恢复时钟
时间
1
非SSC PRBS 码型 － 6560 －
UI SSC
PRBS 码型
－ 36800 －
注：
在本产品支持的协议范围内，CDR 锁定时间如表所示。 对于嵌入时钟链路存在较大或不稳定频偏或
链路信道条件（抖动，插损，反射） 超过spec 规定时，链路存在意外失锁可能,产品提供额外功能
自动重新锁定，其每次重新锁定最大锁定时间和表中一致。
#### 3.3.5 HXT串行收发器的用户时钟交流特性
下表概括PH1P 系列FPGA 的HXT 串行收发器的用户时钟交流特性和要求
表 3-66 HXT 用户时钟输入交流特性
参数 描述 器件 条件 数值 单位
FTXOUT TXOUTCLK 最高频率 PH1P100 － 250 MHz
FTXOUT2 TXOUT2CLK 最高频率 PH1P100 － 250 MHz
FRXOUT RXOUTCLK 最高频率 PH1P100 － 250 MHz
FRXOUT2 RXOUT2CLK 最高频率 PH1P100 － 250 MHz
FTXIN_16bit TXUSRCLK 16bit 最高频率 PH1P100 － 250 MHz
FRXIN_16bit RXUSRCLK 16bit 最高频率 PH1P100 － 250 MHz
FTXIN_20bit TXUSRCLK 20bit 最高频率 PH1P100 － 250 MHz
FRXIN20bit RXUSRCLK 20bit 最高频率 PH1P100 － 250 MHz
FTXIN_32bit TXUSRCLK 32bit 最高频率 PH1P100 － 250 MHz
FRXIN_32bit RXUSRCLK 32bit 最高频率 PH1P100 － 250 MHz
FTXIN_40bit TXUSRCLK 40bit 最高频率 PH1P100 － 250 MHz
FRXIN_40bit RXUSRCLK 40bit 最高频率 PH1P100 － 250 MHz
FTXIN_64bit TXUSRCLK 64bit 最高频率 PH1P100 － 161.133 MHz
FRXIN_64bit RXUSRCLK 64bit 最高频率 PH1P100 － 161.133 MHz
FTXIN_80bit TXUSRCLK 80bit 最高频率 PH1P100 － 128.91 MHz
FRXIN_80bit RXUSRCLK 80bit 最高频率 PH1P100 － 128.91 MHz
#### 3.3.6 HXT发送器的交流特性
下表概括PH1P 系列FPGA 的HXT 发送器的交流特性

<!-- 原 PDF 第 91 页 -->

表 3-67 HXT 串行收发器发送交流特性
参数 描述 条件 Min Typ Max 单位
FMAXTX TX 最高线速率 － FMINRATE － FMAXRATE Gbps
TRTX TX 上升沿时间 20%-80% － 60 － ps
TFTX TX 下降沿时间 80%-20% － 60 － ps
TLLSKEW
TX 各个Lane 之间
skew
－ － －
2UI+100ps -
TOSKEW
TXP 和TXN 差分对
之间 skew
－ － － 15 ps
VTXOOBVDPP 电气空闲输出幅度 － － － 15 mV
TXSST
TX SS（spread
spectrum）扩频范
围
调制频率
@33Khz
-5000
1
－ 5000
1
ppm
TJ10.3125 Total Jitter
10.3125
Gbps
－ － 0.3 UI
DJ10.3125
Deterministic
Jitter
10.3125
Gbps
－ － 0.15 UI
TJ8 Total Jitter 8Gbps － － 0.25 UI
DJ8
Deterministic
Jitter
8Gbps － － 0.1 UI
TJ6.25 Total Jitter 6.25Gbps － － 0.25 UI
DJ6.25
Deterministic
Jitter
6.25Gbps － － 0.1 UI
TJ5 Total Jitter 5Gbps － － 0.25 UI
DJ5
Deterministic
Jitter
5Gbps － － 0.1 UI
TJ0.5 Total Jitter 500Mbps － － 0.25 UI
DJ0.5
Deterministic
Jitter
500Mbps － － 0.1 UI
注：
最大SSC 扩频范围是5000 ppm,可调节范围如参数所示。
#### 3.3.7 HXT接收器的交流特性
概括PH1P 系列FPGA 的 HXT 接收器的交流特性。

<!-- 原 PDF 第 92 页 -->

表 3-68  HXT 收发器 RX 交流特性
参数 描述 条件 Min Typ Max 单位
FMAXRX RX 线速率 － FMINRATE － FMAXRATE Gbps
RXsignaldetecVDPP
RX 信号检测阈值峰
对峰
- 40 120 200 mV
RXSST
RX SS
（spread
spectrum）扩频支持
范围
调制频率
33Khz
-5000 － 5000 ppm
RXRL 接收 Run Length － － － 512 UI
RXPPMTOL
输入数据和参考时钟
PPM 频偏
－ -350 － 350 ppm
JT_SJ10.3125 Sinusoidal Jitter 10.3125Gbps 0.35 － － UI
JT_SJ8 Sinusoidal Jitter 8Gbps 0.35 － － UI
JT_SJ6.25 Sinusoidal Jitter 6.25Gbps 0.35 － － UI
JT_SJ5 Sinusoidal Jitter 5Gbps 0.35 － － UI
JT_SJ2.5 Sinusoidal Jitter 2.5Gbps 0.35 － － UI
#### 3.3.8 HXT串行收发器参考时钟性能
下表给出PH1P 系列FPGA 的HXT 串行收发器参考时钟的规格要求
表 3-69  HXT 收发器参考时钟要求
1
参数 DC 参数 条件 Min Typ Max 单位
VIDIFFREFCLK 差分输入电压 － 300 － 1800 mV
VISEREFCLK
差分时钟单端输入电
压
－
-300
－
900
mV
VICMREFCLK 共模输入电压 － － 350 － mV
FREFCLK 参考时钟频率范围 － 60 － 500 MHz
TDCREFCLK 参考时钟占空比 － 40 － 60 %
SRREFCLK 斜率（Slew rate） 20%-80% 0.6 － － V/ns
注：
根据不同协议规范来选择。

<!-- 原 PDF 第 93 页 -->

#### 3.3.9 PCI Express控制器输入时钟频率要求
下表给出PH1P 系列FPGA PCI Express 控制器输入时钟频率要求
表 3-70 PCI Express 控制器输入时钟频率要求
参数 参数说明 条件 Min Typ Max 单位
FAPBCLK APB 时钟频率 － － － 150 MHz
FPCIE_USRCLK PCIE 用户时钟频率 － － － 150 MHz

<!-- 原 PDF 第 94 页 -->

## 4 引脚和封装
### 4.1 IO 命名规则
表 4-1 引脚命名规则
Pin 名称 通用 IO 差分 IO 复用 IO
命名规则1
没有对应功能
则为空白
IO X1 X2 X3 X4 X5，X6，X7，X8通用IO
IO类型，真差分不显示，伪差分E标识
IO位置L/R/M标识
left/right/top/bottom
编号0-25
差分极性P/N,非差分对管脚，不显示
所在BANK号
复用功能1
复用功能2
复用功能3
示例
（1）IO_L1N_12,D1,DIN,MISO,T0：此管脚为通用IO，同时为真差分端口，在封装
的 L（left）位置，是编号为1 的差分对管脚的N 端，位于FPGA 的BANK12 上，具
有 D1,DIN,MISO,TO 的复用功能。
（2）IO_L0_12：此管脚是通用IO，在封装的L（left）位置，是编号为0 的非差
分对管脚，位于FPGA 的BANK12 上。
Pin 名称 HXT 管脚 BANK 供电管脚 Pin 名称
命名规则2
X1 X2名称
所在BANK号
示例
（1）TX0P_91：HXT TX 端口0 的 P（P/N 标识极性）端口，位于FPGA BANK91。
（2）REFCLK0P_91：HXT REFCLK 端口0 的P（P/N 标识极性）端，位于FPGA 的
BANK91。
（3）PHYVCCA_91：HXT 供电管脚。
（4）RX_CDRCLKN_91/RX_CDRCLKP_91：HXT 接收恢复时钟负端口/正端口

<!-- 原 PDF 第 95 页 -->

（5）RESREF_91：HXT 参考电阻端口,对地参考电阻值200 欧姆误差应小于1%。
Pin 名称 GND 空白功能管脚（NC） 核心供电管脚
命名规则4
X1名称
示例
（1）GND：电源供电负极，芯片0 电平参考管脚。
（2）NC：空白功能管脚。
（3）VCCINT：FPGA 核心供电管脚。
（4）VCCAUX：FPGA 辅助电路的供电电源管脚。
### 4.2 引脚定义和规则
表 4-2 引脚定义和规则
功能名称 输入/输出 功能描述
电源管脚
VCCINT － 内部核心模块电源
VCCAUX － 辅助电源
VCCAUX_IO － I/O 辅助电源
VCCIO － I/O 组电源
PHYVCCA － HXT 1.8V 供电电源
PHYVCCT － HXT 1.2V 供电电源
VCCIO_DDR － DDR I/O 驱动供电电压
VDDR_VREF － DDR 参考电压
VCCDPHY － MIPI DPHY 电源
VCCADC －
ADC 模拟电源
使用 ADC 时，VCCADC 可接单独模拟电压供电或通过磁耦隔离接
VCCAUX；
不使用ADC 时，VCCADC 也需满足上述供电要求，不允许悬空或
接地。
GND － 电源地
GNDADC －
ADC 模拟地
使用 ADC 时，GNDADC 可接单独模拟地或通过磁耦隔离接系统地
GND；
不使用ADC 时，GNDADC 也需满足上述接地要求，不允许悬空。
JTAG 等配置相关管脚
D0_MOSI
复用功能，
输入/输出
SPI 模式：数据输出管脚，连接到SPI Flash 的数据输入管

<!-- 原 PDF 第 96 页 -->

功能名称 输入/输出 功能描述
脚，在x1/x2/x4 模式下作为D0 数据输入管脚。
并行配置模式：作为D0 数据管脚。
其它模式：未使用。
D1_DIN_MISO
复用功能，
输入/输出
串行模式：DIN 是数据输入管脚，在CCLK 上升沿被采样。
SPI 模式：在x1 模式下MISO 是数据输入管脚，在x2/x4 模式
下作为D1 数据输入管脚。
并行配置模式：作为D1 数据管脚。
D2_WPN
复用功能，
输入/输出
SPI 模式：在x4 模式下作为D2 输入数据管脚。
并行配置模式：作为D2 数据管脚。
D3_HOLDN
复用功能，
输入/输出
SPI 模式：在x4 模式下作为D3 输入数据管脚。
并行配置模式：作为D3 数据管脚
D[31:4]
复用功能，
输入/输出
配置数据总线
并行配置模式：x8 模式使用D0～D7，x16 模式使用D0～D15，
x32 模式使用D0～D31。
在所有模式下，未使用的数据管脚可以悬空处理。
CSN
复用功能，
输入
并行配置接口片选信号，低电平有效。
MP 模式：CSN 需接地
SP 模式：外部控制器可通过CSN 使能并行接口；或者并行级
联，连接到前一级CSON。
其他模式：无要求
RDWRN
复用功能，
输入
配置读写控制。
MP 模式：RDWRN 需接地；
SP 模式：RDWRN 将由外部配置控制器驱动，当RDWRN 为低电平
时，写入配置数据；当RDWRN 为高电平时，可以将配置数据读
出。
其他模式：无要求
CSON_DOUT
复用功能，
输出
片选输出
在并行级联配置时，前一级器件的CSON_DOUT 连接到下一级器
件的 CSN 管脚。当CSON_DOUT 为低电平时，下一级器件将被选
中。
数据输出
在串行级联配置时，DOUT 作为数据输出管脚
在串行和SPI 配置（x1）配置模式下，如果器件处于级联配
置，CSON_DOUT 连接到下一个器件的DIN 管脚
非级联模式：CSON_DOUT 可以悬空
SPICSN_BUSY 复用功能， SPI 模式：Flash 片选信号

<!-- 原 PDF 第 97 页 -->

功能名称 输入/输出 功能描述
输出 SP 模式：当RDWRN 为高电平时，BUSY 回读数据指示信号，低
有效。
HSWAPEN
复用功能，
输入
控制 I/O 管脚在芯片上电完成后到程序加载完成前为弱上/下
拉状态/高阻态
HSWAPEN=0 时，
PH1P100 器件用户I/O 管脚在配置过程中为弱上拉状态
PH1P35 器件用户I/O 管脚在配置过程中为弱下拉状态
HSWAPEN=1 时，用户I/O 管脚在配置过程中处于高阻态。
USRCLK
复用功能，
输入
PH1P100 器件：测试引脚
PH1P35 器件：在MSPI 模式下可做为CCLK 的时钟源
PROGRAMN 输入 配置逻辑复位信号，低电平有效。
DONE 输入/输出
配置完成管脚，高电平有效。
DONE 管脚需要通过连接1 个4.7K 欧姆的电阻上拉到VCCIO。
M[2:0] 输入 配置模式选择管脚
INITN 输入/输出
配置初始化管脚，高电平有效。
当 FPGA 处于复位状态时，INITN 为低电平；
当 FPGA 处于初始化过程或者检测到配置错误时，配置模块也
将拉低INITN 管脚；
当检测到PROGRAMN 管脚拉高后，FPGA 开始启动初始化过程，
在初始化完成后，INITN 将变成高电平。在初始化未完成前，
用户可以拉低INITN 来延迟初始化过程；
初始化过程完成后，FPGA 开始下载码流数据到内部配置RAM。
INITN 管脚需要通过连接1 个4.7K 欧姆的电阻上拉到VCCIO。
TDO 输出
JTAG 串行数据输出。当多个器件级联时，当前器件的TDO 管脚
接入到下一个器件的TDI 管脚。
TMS 输入
JTAG 测试模式选择输入。当多个器件级联配置时，需要加驱动
缓冲。
CCLK
复用功能，
输入/输出
配置时钟
从模式：CCLK 方向为输入；
主模式：CCLK 方向为输出。
TDI 输入
JTAG 串行数据输入。当多个器件级联配置时，下一个器件的
TDI 管脚接上一个器件的TDO 管脚。
TCK 输入
JTAG 时钟输入。
需要通过4.7k 电阻上拉。
TRSTN 输入
当 TRSTN=0，JTAG 连接到配置模块
当 TRSTN=1，保留

<!-- 原 PDF 第 98 页 -->

功能名称 输入/输出 功能描述
HXT 相关管脚
REFCLK0N/
REFCLK1N
专用 I/O，
输入/输出
HXT 参考时钟负端口
PH1P100：单向输入
REFCLK0P/
REFCLK1P
专用 I/O，
输入/输出
HXT 参考时钟正端口
PH1P100：单向输入
RX0N～RX3N
专用 I/O，
输入
HXT 接收负端口
RX0P～RX3P
专用 I/O，
输入
HXT 接收正端口
TX0N～TX3N
专用 I/O，
输出
HXT 发送负端口
TX0P～TX3P
专用 I/O，
输出
HXT 发送正端口
RX_CDRCLKN_91
专用 I/O，
输出
HXT 接收恢复时钟负端口
仅 PH1P100SBG676 器件支持
RX_CDRCLKP_91
专用 I/O，
输出
HXT 接收恢复时钟正端口
仅 PH1P100SBG676 器件支持
RESREF －
PH1P100SBG676：HXT 参考电阻端口,参考电阻值200 欧姆（误
差为±1%）下拉到GND。
PH1P100SBG677、PH1P100SBG484：HXT 参考电阻端口,参考电阻
值 100 欧姆（误差为±1%）上拉到PHYVCCT。
DDR 相关引脚
T0_VREF～
T3_VREF
复用功能，
输入
参考电压
T0_DQS_P/
T0_DQS_N～
T3_DQS_P/
T3_DQS_N
复用功能，
输入/输出
数据同步信号
Tx
复用功能，
输入/输出
DDR DQS 分组
MIPI 相关引脚
CKP_0/ CKN_0～
CKP_1/ CKN_1
复用功能输
入/输出
MIPI 模式接口时钟
DPx_0/ DNx_0～
DPx_1/ DNx_1
复用功能，
输入/输出
MIPI 模式数据接口
IO_xP_DPHY0/ 复用功能， 非 MIPI 模式接口具备输入输出功能

<!-- 原 PDF 第 99 页 -->

功能名称 输入/输出 功能描述
IO_xN_DPHY0～
IO_xP_DPHY1/
IO_xN_DPHY1
输入/输出
ADC 相关引脚
ADC1N～ADC8N 输入 ADC 复用模拟输入N 端
ADC1P～ADC8P 输入 ADC 复用模拟输入P 端
VP_0 输入 ADC 专用模拟输入N 端
VN_0 输入 ADC 专用模拟输入P 端
VREFN_0 输入 ADC 模块参考电压(N 端)，该管脚必须接到GNDADC
VREFP_0 输入 ADC 模块参考电压(P 端)，外部参考源
其他
GCLKIOT0～
GCLKIOT3
复用功能，
输入/输出
全局时钟True PAD0～3 端口
GCLKIOC0～
GCLKIOC3
复用功能，
输入/输出
全局时钟Comp PAD0～3 端口
NC － 必须悬空
TVS 相关
PH1P TVS 模块，具备内部温度和电压检测功能。

<!-- 原 PDF 第 100 页 -->

### 4.3 PH1P100SBG676引脚信息

| 编号 | 类型 | BANK | PH1P100SBG676引脚名称 | 编号 | 类型 | BANK | PH1P100SBG676引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| U24 | HR | 11 | IO_L0_11 | U21 | HR | 11 | IO_L13P_11,GCLKIOT1,T2 |
| U25 | HR | 11 | IO_L1P_11,T0 | V21 | HR | 11 | IO_L13N_11,GCLKIOC1,T2 |
| U26 | HR | 11 | IO_L1N_11,T0 | W21 | HR | 11 | IO_L14P_11,GCLKIOT0,T2 |
| V26 | HR | 11 | IO_L2P_11,T0 | Y21 | HR | 11 | IO_L14N_11,GCLKIOC0,T2 |
| W26 | HR | 11 | IO_L2N_11,T0 | T20 | HR | 11 | IO_L15P_11,T2_DQS_P |
| AB26 | HR | 11 | IO_L3P_11,T0_DQS_P | U20 | HR | 11 | IO_L15N_11,T2_DQS_N |
| AC26 | HR | 11 | IO_L3N_11,T0_DQS_N | W20 | HR | 11 | IO_L16P_11,T2 |
| W25 | HR | 11 | IO_L4P_11,T0 | Y20 | HR | 11 | IO_L16N_11,T2 |
| Y26 | HR | 11 | IO_L4N_11,T0 | T19 | HR | 11 | IO_L17P_11,T2 |
| Y25 | HR | 11 | IO_L5P_11,T0 | U19 | HR | 11 | IO_L17N_11,T2 |
| AA25 | HR | 11 | IO_L5N_11,T0 | V19 | HR | 11 | IO_L18P_11,T2 |
| V24 | HR | 11 | IO_L6P_11,T0 | W19 | HR | 11 | IO_L18N_11,T2 |
| W24 | HR | 11 | IO_L6N_11,T0_VREF,T0 | V18 | HR | 11 | IO_L19P_11,T3 |
| AA24 | HR | 11 | IO_L7P_11,T1 | W18 | HR | 11 | IO_L19N_11,T3_VREF,T3 |
| AB25 | HR | 11 | IO_L7N_11,T1 | T14 | HR | 11 | IO_L20P_11,T3 |
| AA22 | HR | 11 | IO_L8P_11,T1 | T15 | HR | 11 | IO_L20N_11,T3 |
| AA23 | HR | 11 | IO_L8N_11,T1 | T17 | HR | 11 | IO_L21P_11,T3_DQS_P |
| AB24 | HR | 11 | IO_L9P_11,T1_DQS_P | T18 | HR | 11 | IO_L21N_11,T3_DQS_N |
| AC24 | HR | 11 | IO_L9N_11,T1_DQS_N | U15 | HR | 11 | IO_L22P_11,T3 |
| V23 | HR | 11 | IO_L10P_11,T1 | U16 | HR | 11 | IO_L22N_11,T3 |
| W23 | HR | 11 | IO_L10N_11,T1 | U14 | HR | 11 | IO_L23P_11,T3 |
| Y22 | HR | 11 | IO_L11P_11,GCLKIOT3,T1 | V14 | HR | 11 | IO_L23N_11,T3 |
| Y23 | HR | 11 | IO_L11N_11,GCLKIOC3,T1 | V16 | HR | 11 | IO_L24P_11,T3 |
| U22 | HR | 11 | IO_L12P_11,GCLKIOT2,T1 | V17 | HR | 11 | IO_L24N_11,T3 |
| V22 | HR | 11 | IO_L12N_11,GCLKIOC2,T1 | U17 | HR | 11 | IO_L25_11 |

<!-- 原 PDF 第 101 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M19 | HR | 12 | IO_L0_12 | N21 | HR | 12 | IO_L13P_12,GCLKIOT1,T2 |
| R14 | HR | 12 | IO_L1P_12,D0,MOSI,T0 | N22 | HR | 12 | IO_L13N_12,GCLKIOC1,T2 |
| R15 | HR | 12 | IO_L1N_12,D1,DIN,MISO,T0 | P20 | HR | 12 | IO_L14P_12,GCLKIOT0,T2 |
| P14 | HR | 12 | IO_L2P_12,D2,WPN,T0 | P21 | HR | 12 | IO_L14N_12,GCLKIOC0,T2 |
| N14 | HR | 12 | IO_L2N_12,D3,HOLDN,T0 | N23 | HR | 12 | IO_L15P_12,RDWRN,T2_DQS_P |
| P15 | HR | 12 | IO_L3P_12,HSWAPEN,T0_DQS_P | N24 | HR | 12 | IO_L15N_12,CSON,DOUT,T2_DQS_N |
| P16 | HR | 12 | IO_L3N_12,USRCLK,T0_DQS_N | P19 | HR | 12 | IO_L16P_12,CSN,T2 |
| N16 | HR | 12 | IO_L4P_12,D4,T0 | N19 | HR | 12 | IO_L16N_12,D31,T2 |
| N17 | HR | 12 | IO_L4N_12,D5,T0 | P23 | HR | 12 | IO_L17P_12,D30,T2 |
| R16 | HR | 12 | IO_L5P_12,D6,T0 | P24 | HR | 12 | IO_L17N_12,D29,T2 |
| R17 | HR | 12 | IO_L5N_12,D7,T0 | R20 | HR | 12 | IO_L18P_12,D28,T2 |
| P18 | HR | 12 | IO_L6P_12,SPICSN,BUSY,T0 | R21 | HR | 12 | IO_L18N_12,D27,T2 |
| N18 | HR | 12 | IO_L6N_12,D8,T0_VREF,T0 | R25 | HR | 12 | IO_L19P_12,D26,T3 |
| K25 | HR | 12 | IO_L7P_12,D9,T1 | P25 | HR | 12 | IO_L19N_12,D25,T3_VREF,T3 |
| K26 | HR | 12 | IO_L7N_12,D10,T1 | N26 | HR | 12 | IO_L20P_12,D24,T3 |
| M20 | HR | 12 | IO_L8P_12,D11,T1 | M26 | HR | 12 | IO_L20N_12,D23,T3 |
| L20 | HR | 12 | IO_L8N_12,D12,T1 | T24 | HR | 12 | IO_L21P_12,T3_DQS_P |
| L24 | HR | 12 | IO_L9P_12,T1_DQS_P | T25 | HR | 12 | IO_L21N_12,D22,T3_DQS_N |
| L25 | HR | 12 | IO_L9N_12,D13,T1_DQS_N | R26 | HR | 12 | IO_L22P_12,D21,T3 |
| M24 | HR | 12 | IO_L10P_12,D14,T1 | P26 | HR | 12 | IO_L22N_12,D20,T3 |
| M25 | HR | 12 | IO_L10N_12,D15,T1 | T22 | HR | 12 | IO_L23P_12,D19,T3 |
| L22 | HR | 12 | IO_L11P_12,GCLKIOT3,T1 | R22 | HR | 12 | IO_L23N_12,D18,T3 |
| L23 | HR | 12 | IO_L11N_12,GCLKIOC3,T1 | T23 | HR | 12 | IO_L24P_12,D17,T3 |
| M21 | HR | 12 | IO_L12P_12,GCLKIOT2,T1 | R23 | HR | 12 | IO_L24N_12,D16,T3 |
| M22 | HR | 12 | IO_L12N_12,GCLKIOC2,T1 | R18 | HR | 12 | IO_L25_12 |

<!-- 原 PDF 第 102 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K18 | HR | 13 | IO_L0_13 | H21 | HR | 13 | IO_L13P_13,GCLKIOT1,T2 |
| K15 | HR | 13 | IO_L1P_13,T0 | H22 | HR | 13 | IO_L13N_13,GCLKIOC1,T2 |
| J16 | HR | 13 | IO_L1N_13,T0 | J23 | HR | 13 | IO_L14P_13,GCLKIOT0,T2 |
| J14 | HR | 13 | IO_L2P_13,T0 | H23 | HR | 13 | IO_L14N_13,GCLKIOC0,T2 |
| J15 | HR | 13 | IO_L2N_13,T0 | G22 | HR | 13 | IO_L15P_13,T2_DQS_P |
| K16 | HR | 13 | IO_L3P_13,T0_DQS_P | F22 | HR | 13 | IO_L15N_13,T2_DQS_N |
| K17 | HR | 13 | IO_L3N_13,T0_DQS_N | J24 | HR | 13 | IO_L16P_13,T2 |
| M14 | HR | 13 | IO_L4P_13,T0 | H24 | HR | 13 | IO_L16N_13,T2 |
| L14 | HR | 13 | IO_L4N_13,T0 | F23 | HR | 13 | IO_L17P_13,T2 |
| M15 | HR | 13 | IO_L5P_13,T0 | E23 | HR | 13 | IO_L17N_13,T2 |
| L15 | HR | 13 | IO_L5N_13,T0 | K22 | HR | 13 | IO_L18P_13,T2 |
| M16 | HR | 13 | IO_L6P_13,T0 | K23 | HR | 13 | IO_L18N_13,T2 |
| M17 | HR | 13 | IO_L6N_13,T0_VREF,T0 | G24 | HR | 13 | IO_L19P_13,T3 |
| J19 | HR | 13 | IO_L7P_13,T1 | F24 | HR | 13 | IO_L19N_13,T3_VREF,T3 |
| H19 | HR | 13 | IO_L7N_13,T1 | E25 | HR | 13 | IO_L20P_13,T3 |
| L17 | HR | 13 | IO_L8P_13,T1 | D25 | HR | 13 | IO_L20N_13,T3 |
| L18 | HR | 13 | IO_L8N_13,T1 | E26 | HR | 13 | IO_L21P_13,T3_DQS_P |
| J20 | HR | 13 | IO_L9N_13,T1_DQS_N | D26 | HR | 13 | IO_L21N_13,T3_DQS_N |
| K20 | HR | 13 | IO_L9P_13,T1_DQS_P | H26 | HR | 13 | IO_L22P_13,T3 |
| J18 | HR | 13 | IO_L10P_13,T1 | G26 | HR | 13 | IO_L22N_13,T3 |
| H18 | HR | 13 | IO_L10N_13,T1 | G25 | HR | 13 | IO_L23P_13,T3 |
| G20 | HR | 13 | IO_L11P_13,GCLKIOT3,T1 | F25 | HR | 13 | IO_L23N_13,T3 |
| G21 | HR | 13 | IO_L11N_13,GCLKIOC3,T1 | J25 | HR | 13 | IO_L24P_13,T3 |
| K21 | HR | 13 | IO_L12P_13,GCLKIOT2,T1 | J26 | HR | 13 | IO_L24N_13,T3 |
| J21 | HR | 13 | IO_L12N_13,GCLKIOC2,T1 | L19 | HR | 13 | IO_L25_13 |

<!-- 原 PDF 第 103 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H17 | HR | 14 | IO_L0_14 | D19 | HR | 14 | IO_L13P_14,GCLKIOT1,T2 |
| H14 | HR | 14 | IO_L1P_14,T0 | C19 | HR | 14 | IO_L13N_14,GCLKIOC1,T2 |
| H15 | HR | 14 | IO_L1N_14,T0 | E20 | HR | 14 | IO_L14P_14,GCLKIOT0,T2 |
| G17 | HR | 14 | IO_L2P_14,T0 | D20 | HR | 14 | IO_L14N_14,GCLKIOC0,T2 |
| F17 | HR | 14 | IO_L2N_14,T0 | B20 | HR | 14 | IO_L15P_14,T2_DQS_P |
| F18 | HR | 14 | IO_L3P_14,T0_DQS_P | A20 | HR | 14 | IO_L15N_14,T2_DQS_N |
| F19 | HR | 14 | IO_L3N_14,T0_DQS_N | C21 | HR | 14 | IO_L16P_14,T2 |
| G15 | HR | 14 | IO_L4P_14,T0 | B21 | HR | 14 | IO_L16N_14,T2 |
| F15 | HR | 14 | IO_L4N_14,T0 | B22 | HR | 14 | IO_L17P_14,T2 |
| G19 | HR | 14 | IO_L5P_14,T0 | A22 | HR | 14 | IO_L17N_14,T2 |
| F20 | HR | 14 | IO_L5N_14,T0 | E21 | HR | 14 | IO_L18P_14,T2 |
| H16 | HR | 14 | IO_L6P_14,T0 | D21 | HR | 14 | IO_L18N_14,T2 |
| G16 | HR | 14 | IO_L6N_14,T0_VREF,T0 | C22 | HR | 14 | IO_L19P_14,T3 |
| C17 | HR | 14 | IO_L7P_14,T1 | C23 | HR | 14 | IO_L19N_14,T3_VREF,T3 |
| B17 | HR | 14 | IO_L7N_14,T1 | B25 | HR | 14 | IO_L20P_14,T3 |
| E16 | HR | 14 | IO_L8P_14,T1 | A25 | HR | 14 | IO_L20N_14,T3 |
| D16 | HR | 14 | IO_L8N_14,T1 | A23 | HR | 14 | IO_L21P_14,T3_DQS_P |
| A17 | HR | 14 | IO_L9P_14,T1_DQS_P | A24 | HR | 14 | IO_L21N_14,T3_DQS_N |
| A18 | HR | 14 | IO_L9N_14,T1_DQS_N | C26 | HR | 14 | IO_L22P_14,T3 |
| B19 | HR | 14 | IO_L10P_14,T1 | B26 | HR | 14 | IO_L22N_14,T3 |
| A19 | HR | 14 | IO_L10N_14,T1 | C24 | HR | 14 | IO_L23P_14,T3 |
| E17 | HR | 14 | IO_L11P_14,GCLKIOT3,T1 | B24 | HR | 14 | IO_L23N_14,T3 |
| E18 | HR | 14 | IO_L11N_14,GCLKIOC3,T1 | D23 | HR | 14 | IO_L24P_14,T3 |
| D18 | HR | 14 | IO_L12P_14,GCLKIOT2,T1 | D24 | HR | 14 | IO_L24N_14,T3 |
| C18 | HR | 14 | IO_L12N_14,GCLKIOC2,T1 | E22 | HR | 14 | IO_L25_14 |

<!-- 原 PDF 第 104 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N8 | HR | 32 | IO_R0_32 | R3 | HR | 32 | IO_R13P_32,GCLKIOT1,T2 |
| K3 | HR | 32 | IO_R1P_32,T0 | P3 | HR | 32 | IO_R13N_32,GCLKIOC1,T2 |
| J3 | HR | 32 | IO_R1N_32,T0 | P4 | HR | 32 | IO_R14P_32,GCLKIOT0,T2 |
| M7 | HR | 32 | IO_R2P_32,T0 | N4 | HR | 32 | IO_R14N_32,GCLKIOC0,T2 |
| L7 | HR | 32 | IO_R2N_32,T0 | R1 | HR | 32 | IO_R15P_32,T2_DQS_P |
| M4 | HR | 32 | IO_R3P_32,T0_DQS_P | P1 | HR | 32 | IO_R15N_32,T2_DQS_N |
| L4 | HR | 32 | IO_R3N_32,T0_DQS_N | T4 | HR | 32 | IO_R16P_32,T2 |
| L5 | HR | 32 | IO_R4P_32,T0 | T3 | HR | 32 | IO_R16N_32,T2 |
| K5 | HR | 32 | IO_R4N_32,T0 | T2 | HR | 32 | IO_R17P_32,T2 |
| N7 | HR | 32 | IO_R5P_32,T0 | R2 | HR | 32 | IO_R17N_32,T2 |
| N6 | HR | 32 | IO_R5N_32,T0 | U2 | HR | 32 | IO_R18P_32,T2 |
| M6 | HR | 32 | IO_R6P_32,T0 | U1 | HR | 32 | IO_R18N_32,T2 |
| M5 | HR | 32 | IO_R6N_32,T0_VREF,T0 | P6 | HR | 32 | IO_R19P_32,T3 |
| K1 | HR | 32 | IO_R7P_32,T1 | P5 | HR | 32 | IO_R19N_32,T3_VREF,T3 |
| J1 | HR | 32 | IO_R7N_32,T1 | T5 | HR | 32 | IO_R20P_32,T3 |
| L3 | HR | 32 | IO_R8P_32,T1 | R5 | HR | 32 | IO_R20N_32,T3 |
| K2 | HR | 32 | IO_R8N_32,T1 | U6 | HR | 32 | IO_R21P_32,T3_DQS_P |
| N1 | HR | 32 | IO_R9P_32,T1_DQS_P | U5 | HR | 32 | IO_R21N_32,T3_DQS_N |
| M1 | HR | 32 | IO_R9N_32,T1_DQS_N | R8 | HR | 32 | IO_R22P_32,T3 |
| H2 | HR | 32 | IO_R10P_32,T1 | P8 | HR | 32 | IO_R22N_32,T3 |
| H1 | HR | 32 | IO_R10N_32,T1 | R7 | HR | 32 | IO_R23P_32,T3 |
| M2 | HR | 32 | IO_R11P_32,GCLKIOT3,T1 | R6 | HR | 32 | IO_R23N_32,T3 |
| L2 | HR | 32 | IO_R11N_32,GCLKIOC3,T1 | T8 | HR | 32 | IO_R24P_32,T3 |
| N3 | HR | 32 | IO_R12P_32,GCLKIOT2,T1 | T7 | HR | 32 | IO_R24N_32,T3 |
| N2 | HR | 32 | IO_R12N_32,GCLKIOC2,T1 | U4 | HR | 32 | IO_R25_32 |

<!-- 原 PDF 第 105 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J8 | HR | 33 | IO_R0_33 | E5 | HR | 33 | IO_R13P_33,GCLKIOT1,T2 |
| E6 | HR | 33 | IO_R1P_33,T0 | D5 | HR | 33 | IO_R13N_33,GCLKIOC1,T2 |
| D6 | HR | 33 | IO_R1N_33,T0 | D4 | HR | 33 | IO_R14P_33,GCLKIOT0,T2 |
| H8 | HR | 33 | IO_R2P_33,T0 | C4 | HR | 33 | IO_R14N_33,GCLKIOC0,T2 |
| G8 | HR | 33 | IO_R2N_33,T0 | B5 | HR | 33 | IO_R15P_33,T2_DQS_P |
| H7 | HR | 33 | IO_R3P_33,T0_DQS_P | A5 | HR | 33 | IO_R15N_33,T2_DQS_N |
| G7 | HR | 33 | IO_R3N_33,T0_DQS_N | B4 | HR | 33 | IO_R16P_33,T2 |
| F8 | HR | 33 | IO_R4P_33,T0 | A4 | HR | 33 | IO_R16N_33,T2 |
| F7 | HR | 33 | IO_R4N_33,T0 | D3 | HR | 33 | IO_R17P_33,T2 |
| H6 | HR | 33 | IO_R5P_33,T0 | C3 | HR | 33 | IO_R17N_33,T2 |
| G6 | HR | 33 | IO_R5N_33,T0 | F3 | HR | 33 | IO_R18P_33,T2 |
| H9 | HR | 33 | IO_R6P_33,T0 | E3 | HR | 33 | IO_R18N_33,T2 |
| G9 | HR | 33 | IO_R6N_33,T0_VREF,T0 | C2 | HR | 33 | IO_R19P_33,T3 |
| J6 | HR | 33 | IO_R7P_33,T1 | B2 | HR | 33 | IO_R19N_33,T3_VREF,T3 |
| J5 | HR | 33 | IO_R7N_33,T1 | A3 | HR | 33 | IO_R20P_33,T3 |
| L8 | HR | 33 | IO_R8P_33,T1 | A2 | HR | 33 | IO_R20N_33,T3 |
| K8 | HR | 33 | IO_R8N_33,T1 | C1 | HR | 33 | IO_R21P_33,T3_DQS_P |
| J4 | HR | 33 | IO_R9P_33,T1_DQS_P | B1 | HR | 33 | IO_R21N_33,T3_DQS_N |
| H4 | HR | 33 | IO_R9N_33,T1_DQS_N | F2 | HR | 33 | IO_R22P_33,T3 |
| K7 | HR | 33 | IO_R10P_33,T1 | E2 | HR | 33 | IO_R22N_33,T3 |
| K6 | HR | 33 | IO_R10N_33,T1 | E1 | HR | 33 | IO_R23P_33,T3 |
| G4 | HR | 33 | IO_R11P_33,GCLKIOT3,T1 | D1 | HR | 33 | IO_R23N_33,T3 |
| F4 | HR | 33 | IO_R11N_33,GCLKIOC3,T1 | G2 | HR | 33 | IO_R24P_33,T3 |
| G5 | HR | 33 | IO_R12P_33,GCLKIOT2,T1 | G1 | HR | 33 | IO_R24N_33,T3 |
| F5 | HR | 33 | IO_R12N_33,GCLKIOC2,T1 | H3 | HR | 33 | IO_R25_33 |

<!-- 原 PDF 第 106 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AA11 | - | 91 | REFCLK0P_91 | D11 | - | 94 | PHYVCCA_94 |
| AB11 | - | 91 | REFCLK0N_91 | D13 | - | 94 | PHYVCCA_94 |
| AA13 | - | 91 | REFCLK1P_91 | D9 | - | 94 | PHYVCCA_94 |
| AB13 | - | 91 | REFCLK1N_91 | F10 | - | 94 | PHYVCCA_94 |
| AA8 | - | 91 | RX_CDRCLKP_91 | F12 | - | 94 | PHYVCCA_94 |
| AA7 | - | 91 | RX_CDRCLKN_91 | F11 | - | 94 | REFCLK0P_94 |
| AA10 | - | 91 | PHYVCCA_91 | E11 | - | 94 | REFCLK0N_94 |
| AA12 | - | 91 | PHYVCCA_91 | F13 | - | 94 | REFCLK1P_94 |
| AC11 | - | 91 | PHYVCCA_91 | E13 | - | 94 | REFCLK1N_94 |
| AC13 | - | 91 | PHYVCCA_91 | B11 | - | 94 | RX0P_94 |
| AC9 | - | 91 | PHYVCCA_91 | A11 | - | 94 | RX0N_94 |
| AE11 | - | 91 | RX0P_91 | D14 | - | 94 | RX1P_94 |
| AF11 | - | 91 | RX0N_91 | C14 | - | 94 | RX1N_94 |
| AC14 | - | 91 | RX1P_91 | B13 | - | 94 | RX2P_94 |
| AD14 | - | 91 | RX1N_91 | A13 | - | 94 | RX2N_94 |
| AE13 | - | 91 | RX2P_91 | D12 | - | 94 | RX3P_94 |
| AF13 | - | 91 | RX2N_91 | C12 | - | 94 | RX3N_94 |
| AC12 | - | 91 | RX3P_91 | B7 | - | 94 | TX0P_94 |
| AD12 | - | 91 | RX3N_91 | A7 | - | 94 | TX0N_94 |
| AE7 | - | 91 | TX0P_91 | D8 | - | 94 | TX1P_94 |
| AF7 | - | 91 | TX0N_91 | C8 | - | 94 | TX1N_94 |
| AC8 | - | 91 | TX1P_91 | B9 | - | 94 | TX2P_94 |
| AD8 | - | 91 | TX1N_91 | A9 | - | 94 | TX2N_94 |
| AE9 | - | 91 | TX2P_91 | D10 | - | 94 | TX3P_94 |
| AF9 | - | 91 | TX2N_91 | C10 | - | 94 | TX3N_94 |
| AC10 | - | 91 | TX3P_91 | A15 | - | 94 | RESREF_94 |
| AD10 | - | 91 | TX3N_91 |  |  |  |  |
| AF15 | - | 91 | RESREF_91 |  |  |  |  |

<!-- 原 PDF 第 107 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W11 | - | 0 | VCCIO_0 | AA1 | - | 22 | VCCIO_22 |
| Y14 | - | 0 | VCCIO_0 | AC5 | - | 22 | VCCIO_22 |
| AC25 | - | 11 | VCCIO_11 | AD2 | - | 22 | VCCIO_22 |
| T16 | - | 11 | VCCIO_11 | U3 | - | 22 | VCCIO_22 |
| T26 | - | 11 | VCCIO_11 | W7 | - | 22 | VCCIO_22 |
| U23 | - | 11 | VCCIO_11 | Y4 | - | 22 | VCCIO_22 |
| V20 | - | 11 | VCCIO_11 | K4 | - | 32 | VCCIO_32 |
| Y24 | - | 11 | VCCIO_11 | L1 | - | 32 | VCCIO_32 |
| K24 | - | 12 | VCCIO_12 | M8 | - | 32 | VCCIO_32 |
| L21 | - | 12 | VCCIO_12 | N5 | - | 32 | VCCIO_32 |
| N15 | - | 12 | VCCIO_12 | P2 | - | 32 | VCCIO_32 |
| N25 | - | 12 | VCCIO_12 | T6 | - | 32 | VCCIO_32 |
| P22 | - | 12 | VCCIO_12 | A1 | - | 33 | VCCIO_33 |
| R19 | - | 12 | VCCIO_12 | C5 | - | 33 | VCCIO_33 |
| F26 | - | 13 | VCCIO_13 | D2 | - | 33 | VCCIO_33 |
| G23 | - | 13 | VCCIO_13 | F6 | - | 33 | VCCIO_33 |
| H20 | - | 13 | VCCIO_13 | G3 | - | 33 | VCCIO_33 |
| J17 | - | 13 | VCCIO_13 | J7 | - | 33 | VCCIO_33 |
| K14 | - | 13 | VCCIO_13 |  |  |  |  |
| M18 | - | 13 | VCCIO_13 |  |  |  |  |
| A21 | - | 14 | VCCIO_14 |  |  |  |  |
| B18 | - | 14 | VCCIO_14 |  |  |  |  |
| C25 | - | 14 | VCCIO_14 |  |  |  |  |
| D22 | - | 14 | VCCIO_14 |  |  |  |  |
| E19 | - | 14 | VCCIO_14 |  |  |  |  |
| F16 | - | 14 | VCCIO_14 |  |  |  |  |
| AA21 | - | 21 | VCCIO_21 |  |  |  |  |
| AB18 | - | 21 | VCCIO_21 |  |  |  |  |
| AD22 | - | 21 | VCCIO_21 |  |  |  |  |
| AE19 | - | 21 | VCCIO_21 |  |  |  |  |
| AF26 | - | 21 | VCCIO_21 |  |  |  |  |
| W17 | - | 21 | VCCIO_21 |  |  |  |  |

<!-- 原 PDF 第 108 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H13 | HR | 0 | IO_C0_0,CCLK_0 | AA26 | - | - | GND |
| W10 | - | 0 | DONE_0 | T11 | - | - | GND |
| V11 | - | 0 | INITN_0 | T13 | - | - | GND |
| AB7 | - | 0 | M0_0 | T21 | - | - | GND |
| Y9 | - | 0 | M1_0 | T9 | - | - | GND |
| W9 | - | 0 | M2_0 | U10 | - | - | GND |
| AE16 | - | 0 | PROGRAMN_0 | U12 | - | - | GND |
| H12 | - | 0 | TCK_0 | U18 | - | - | GND |
| H10 | - | 0 | TDI_0 | U8 | - | - | GND |
| J10 | - | 0 | TDO_0 | V13 | - | - | GND |
| H11 | - | 0 | TMS_0 | V15 | - | - | GND |
| AB15 | - | 0 | TRSTN_0 | AA6 | - | - | GND |
| J11 | - | - | VCCINT | V25 | - | - | GND |
| J13 | - | - | VCCINT | V5 | - | - | GND |
| K10 | - | - | VCCINT | W12 | - | - | GND |
| K12 | - | - | VCCINT | W2 | - | - | GND |
| L11 | - | - | VCCINT | W22 | - | - | GND |
| L13 | - | - | VCCINT | Y10 | - | - | GND |
| M10 | - | - | VCCINT | Y11 | - | - | GND |
| P10 | - | - | VCCINT | Y12 | - | - | GND |
| T10 | - | - | VCCINT | Y13 | - | - | GND |
| T12 | - | - | VCCINT | Y19 | - | - | GND |
| U11 | - | - | VCCINT | AA9 | - | - | GND |
| V10 | - | - | VCCINT | AB10 | - | - | GND |
| V12 | - | - | VCCINT | AB12 | - | - | GND |
| J9 | - | - | VCCAUX | AB14 | - | - | GND |
| U9 | - | - | VCCAUX | AB23 | - | - | GND |
| L9 | - | - | VCCAUX_IO | AB3 | - | - | GND |
| N9 | - | - | VCCAUX_IO | AB8 | - | - | GND |
| R9 | - | - | VCCAUX_IO | AB9 | - | - | GND |
| A12 | - | - | GND |  |  |  |  |
| AC15 | - | - | GND |  |  |  |  |
| AC20 | - | - | GND |  |  |  |  |
| AC7 | - | - | GND |  |  |  |  |
| AD11 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 109 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AD13 | - | - | GND | E14 | - | - | GND |
| AD16 | - | - | GND | E15 | - | - | GND |
| AD6 | - | - | GND | E24 | - | - | GND |
| AD9 | - | - | GND | E4 | - | - | GND |
| AE15 | - | - | GND | A6 | - | - | GND |
| AE24 | - | - | GND | E7 | - | - | GND |
| A14 | - | - | GND | E8 | - | - | GND |
| AE4 | - | - | GND | E9 | - | - | GND |
| AE6 | - | - | GND | F1 | - | - | GND |
| AF1 | - | - | GND | F14 | - | - | GND |
| AF10 | - | - | GND | F21 | - | - | GND |
| AF12 | - | - | GND | F9 | - | - | GND |
| AF14 | - | - | GND | G10 | - | - | GND |
| AF16 | - | - | GND | G11 | - | - | GND |
| AF21 | - | - | GND | G12 | - | - | GND |
| AF6 | - | - | GND | A8 | - | - | GND |
| AF8 | - | - | GND | G13 | - | - | GND |
| A16 | - | - | GND | G18 | - | - | GND |
| B15 | - | - | GND | H25 | - | - | GND |
| B16 | - | - | GND | H5 | - | - | GND |
| B23 | - | - | GND | J12 | - | - | GND |
| B3 | - | - | GND | J2 | - | - | GND |
| B6 | - | - | GND | J22 | - | - | GND |
| C11 | - | - | GND | K11 | - | - | GND |
| C13 | - | - | GND | K13 | - | - | GND |
| C16 | - | - | GND | K19 | - | - | GND |
| C20 | - | - | GND | AA14 | - | - | GND |
| C6 | - | - | GND | K9 | - | - | GND |
| A26 | - | - | GND | L10 | - | - | GND |
| C9 | - | - | GND | L12 | - | - | GND |
| D15 | - | - | GND | L16 | - | - | GND |
| D17 | - | - | GND | L26 | - | - | GND |
| D7 | - | - | GND | L6 | - | - | GND |
| E10 | - | - | GND | M13 | - | - | GND |
| E12 | - | - | GND | M23 | - | - | GND |

<!-- 原 PDF 第 110 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M3 | - | - | GND | AC16 | - | - | NC |
| M9 | - | - | GND | AA17 | - | - | NC |
| AA16 | - | - | GND | W14 | - | - | NC |
| N10 | - | - | GND | W15 | - | - | NC |
| N20 | - | - | GND | AD7 | - | - | NC |
| P13 | - | - | GND | AE10 | - | - | NC |
| P17 | - | - | GND | AE8 | - | - | NC |
| P7 | - | - | GND | AD15 | - | - | NC |
| P9 | - | - | GND | AE12 | - | - | NC |
| R10 | - | - | GND | AE14 | - | - | NC |
| R24 | - | - | GND | B12 | - | - | NC |
| R4 | - | - | GND | B14 | - | - | NC |
| T1 | - | - | GND | AF17 | - | - | NC |
| A10 | - | - | GND | C15 | - | - | NC |
| V6 | - | - | NC | B10 | - | - | NC |
| V7 | - | - | NC | B8 | - | - | NC |
| W1 | - | - | NC | C7 | - | - | NC |
| W16 | - | - | NC | V9 | - | - | NC |
| W3 | - | - | NC | V8 | - | - | NC |
| W4 | - | - | NC | AA15 | - | - | NC |
| W5 | - | - | NC | W8 | - | - | NC |
| AB17 | - | - | NC | Y15 | - | - | NC |
| W6 | - | - | NC | Y8 | - | - | NC |
| Y1 | - | - | NC | AE17 | - | - | NC |
| Y16 | - | - | NC | N13 | - | - | NC |
| Y17 | - | - | NC | R13 | - | - | NC |
| Y18 | - | - | NC | U13 | - | - | NC |
| Y2 | - | - | NC | W13 | - | - | NC |
| Y3 | - | - | NC | AA18 | - | - | NC |
| Y5 | - | - | NC | AA19 | - | - | NC |
| Y6 | - | - | NC | AA2 | - | - | NC |
| Y7 | - | - | NC | AA20 | - | - | NC |
| AE1 | - | - | NC | AA3 | - | - | NC |
| AE18 | - | - | NC | AA4 | - | - | NC |
| AE2 | - | - | NC | AA5 | - | - | NC |

<!-- 原 PDF 第 111 页 -->


| 编号 | 类型 | BANK | PH1P100SBG676引脚说明 | 编号 | 类型 | BANK | PH1P100SBG676引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AB16 | - | - | NC | AE22 | - | - | NC |
| AB1 | - | - | NC | AE23 | - | - | NC |
| AB19 | - | - | NC | AE25 | - | - | NC |
| AB2 | - | - | NC | AE26 | - | - | NC |
| AB20 | - | - | NC | AE3 | - | - | NC |
| AB21 | - | - | NC | AE5 | - | - | NC |
| AB22 | - | - | NC | AF19 | - | - | NC |
| AB4 | - | - | NC | AF18 | - | - | NC |
| AB5 | - | - | NC | AF2 | - | - | NC |
| AB6 | - | - | NC | AF20 | - | - | NC |
| AC1 | - | - | NC | AF22 | - | - | NC |
| AD17 | - | - | NC | AF23 | - | - | NC |
| AC19 | - | - | NC | AF24 | - | - | NC |
| AC2 | - | - | NC | AF25 | - | - | NC |
| AC21 | - | - | NC | AF3 | - | - | NC |
| AC22 | - | - | NC | AF4 | - | - | NC |
| AC23 | - | - | NC | AF5 | - | - | NC |
| AC3 | - | - | NC | G14 | - | - | NC |
| AC4 | - | - | NC | AC18 | - | - | NC |
| AC6 | - | - | NC | M11 | - | - | NC |
| AD1 | - | - | NC | M12 | - | - | NC |
| AD19 | - | - | NC | N11 | - | - | NC |
| AC17 | - | - | NC | N12 | - | - | NC |
| AD20 | - | - | NC | P11 | - | - | NC |
| AD21 | - | - | NC | P12 | - | - | NC |
| AD23 | - | - | NC | R11 | - | - | NC |
| AD24 | - | - | NC | R12 | - | - | NC |
| AD25 | - | - | NC | U7 | - | - | NC |
| AD26 | - | - | NC | V1 | - | - | NC |
| AD3 | - | - | NC | AD18 | - | - | NC |
| AD4 | - | - | NC | V2 | - | - | NC |
| AD5 | - | - | NC | V3 | - | - | NC |
| AE20 | - | - | NC | V4 | - | - | NC |
| AE21 | - | - | NC |  |  |  |  |

<!-- 原 PDF 第 112 页 -->

### 4.4 PH1P100SBG677引脚信息

| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| U24 | HR | 11 | IO_L0_11 | U21 | HR | 11 | IO_L13P_11,GCLKIOT1,T2 |
| U25 | HR | 11 | IO_L1P_11,T0 | V21 | HR | 11 | IO_L13N_11,GCLKIOC1,T2 |
| U26 | HR | 11 | IO_L1N_11,T0 | W21 | HR | 11 | IO_L14P_11,GCLKIOT0,T2 |
| V26 | HR | 11 | IO_L2P_11,T0 | Y21 | HR | 11 | IO_L14N_11,GCLKIOC0,T2 |
| W26 | HR | 11 | IO_L2N_11,T0 | T20 | HR | 11 | IO_L15P_11,T2_DQS_P |
| AB26 | HR | 11 | IO_L3P_11,T0_DQS_P | U20 | HR | 11 | IO_L15N_11,T2_DQS_N |
| AC26 | HR | 11 | IO_L3N_11,T0_DQS_N | W20 | HR | 11 | IO_L16P_11,T2 |
| W25 | HR | 11 | IO_L4P_11,T0 | Y20 | HR | 11 | IO_L16N_11,T2 |
| Y26 | HR | 11 | IO_L4N_11,T0 | T19 | HR | 11 | IO_L17P_11,T2 |
| Y25 | HR | 11 | IO_L5P_11,T0 | U19 | HR | 11 | IO_L17N_11,T2 |
| AA25 | HR | 11 | IO_L5N_11,T0 | V19 | HR | 11 | IO_L18P_11,T2 |
| V24 | HR | 11 | IO_L6P_11,T0 | W19 | HR | 11 | IO_L18N_11,T2 |
| W24 | HR | 11 | IO_L6N_11,T0_VREF,T0 | V18 | HR | 11 | IO_L19P_11,T3 |
| AA24 | HR | 11 | IO_L7P_11,T1 | W18 | HR | 11 | IO_L19N_11,T3_VREF,T3 |
| AB25 | HR | 11 | IO_L7N_11,T1 | T14 | HR | 11 | IO_L20P_11,T3 |
| AA22 | HR | 11 | IO_L8P_11,T1 | T15 | HR | 11 | IO_L20N_11,T3 |
| AA23 | HR | 11 | IO_L8N_11,T1 | T17 | HR | 11 | IO_L21P_11,T3_DQS_P |
| AB24 | HR | 11 | IO_L9P_11,T1_DQS_P | T18 | HR | 11 | IO_L21N_11,T3_DQS_N |
| AC24 | HR | 11 | IO_L9N_11,T1_DQS_N | U15 | HR | 11 | IO_L22P_11,T3 |
| V23 | HR | 11 | IO_L10P_11,T1 | U16 | HR | 11 | IO_L22N_11,T3 |
| W23 | HR | 11 | IO_L10N_11,T1 | U14 | HR | 11 | IO_L23P_11,T3 |
| Y22 | HR | 11 | IO_L11P_11,GCLKIOT3,T1 | V14 | HR | 11 | IO_L23N_11,T3 |
| Y23 | HR | 11 | IO_L11N_11,GCLKIOC3,T1 | V16 | HR | 11 | IO_L24P_11,T3 |
| U22 | HR | 11 | IO_L12P_11,GCLKIOT2,T1 | V17 | HR | 11 | IO_L24N_11,T3 |
| V22 | HR | 11 | IO_L12N_11,GCLKIOC2,T1 | U17 | HR | 11 | IO_L25_11 |

<!-- 原 PDF 第 113 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M19 | HR | 12 | IO_L0_12 | N21 | HR | 12 | IO_L13P_12,GCLKIOT1,T2 |
| R14 | HR | 12 | IO_L1P_12,D0,MOSI,T0 | N22 | HR | 12 | IO_L13N_12,GCLKIOC1,T2 |
| R15 | HR | 12 | IO_L1N_12,D1,DIN,MISO,T0 | P20 | HR | 12 | IO_L14P_12,GCLKIOT0,T2 |
| P14 | HR | 12 | IO_L2P_12,D2,WPN,T0 | P21 | HR | 12 | IO_L14N_12,GCLKIOC0,T2 |
| N14 | HR | 12 | IO_L2N_12,D3,HOLDN,T0 | N23 | HR | 12 | IO_L15P_12,RDWRN,T2_DQS_P |
| P15 | HR | 12 | IO_L3P_12,HSWAPEN,T0_DQS_P | N24 | HR | 12 | IO_L15N_12,CSON,DOUT,T2_DQS_N |
| P16 | HR | 12 | IO_L3N_12,USRCLK,T0_DQS_N | P19 | HR | 12 | IO_L16P_12,CSN,T2 |
| N16 | HR | 12 | IO_L4P_12,D4,T0 | N19 | HR | 12 | IO_L16N_12,D31,T2 |
| N17 | HR | 12 | IO_L4N_12,D5,T0 | P23 | HR | 12 | IO_L17P_12,D30,T2 |
| R16 | HR | 12 | IO_L5P_12,D6,T0 | P24 | HR | 12 | IO_L17N_12,D29,T2 |
| R17 | HR | 12 | IO_L5N_12,D7,T0 | R20 | HR | 12 | IO_L18P_12,D28,T2 |
| P18 | HR | 12 | IO_L6P_12,SPICSN,BUSY,T0 | R21 | HR | 12 | IO_L18N_12,D27,T2 |
| N18 | HR | 12 | IO_L6N_12,D8,T0_VREF,T0 | R25 | HR | 12 | IO_L19P_12,D26,T3 |
| K25 | HR | 12 | IO_L7P_12,D9,T1 | P25 | HR | 12 | IO_L19N_12,D25,T3_VREF,T3 |
| K26 | HR | 12 | IO_L7N_12,D10,T1 | N26 | HR | 12 | IO_L20P_12,D24,T3 |
| M20 | HR | 12 | IO_L8P_12,D11,T1 | M26 | HR | 12 | IO_L20N_12,D23,T3 |
| L20 | HR | 12 | IO_L8N_12,D12,T1 | T24 | HR | 12 | IO_L21P_12,T3_DQS_P |
| L24 | HR | 12 | IO_L9P_12,T1_DQS_P | T25 | HR | 12 | IO_L21N_12,D22,T3_DQS_N |
| L25 | HR | 12 | IO_L9N_12,D13,T1_DQS_N | R26 | HR | 12 | IO_L22P_12,D21,T3 |
| M24 | HR | 12 | IO_L10P_12,D14,T1 | P26 | HR | 12 | IO_L22N_12,D20,T3 |
| M25 | HR | 12 | IO_L10N_12,D15,T1 | T22 | HR | 12 | IO_L23P_12,D19,T3 |
| L22 | HR | 12 | IO_L11P_12,GCLKIOT3,T1 | R22 | HR | 12 | IO_L23N_12,D18,T3 |
| L23 | HR | 12 | IO_L11N_12,GCLKIOC3,T1 | T23 | HR | 12 | IO_L24P_12,D17,T3 |
| M21 | HR | 12 | IO_L12P_12,GCLKIOT2,T1 | R23 | HR | 12 | IO_L24N_12,D16,T3 |
| M22 | HR | 12 | IO_L12N_12,GCLKIOC2,T1 | R18 | HR | 12 | IO_L25_12 |

<!-- 原 PDF 第 114 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K18 | HR | 13 | IO_L0_13 | H21 | HR | 13 | IO_L13P_13,GCLKIOT1,T2 |
| K15 | HR | 13 | IO_L1P_13,T0 | H22 | HR | 13 | IO_L13N_13,GCLKIOC1,T2 |
| J16 | HR | 13 | IO_L1N_13,T0 | J23 | HR | 13 | IO_L14P_13,GCLKIOT0,T2 |
| J14 | HR | 13 | IO_L2P_13,T0 | H23 | HR | 13 | IO_L14N_13,GCLKIOC0,T2 |
| J15 | HR | 13 | IO_L2N_13,T0 | G22 | HR | 13 | IO_L15P_13,T2_DQS_P |
| K16 | HR | 13 | IO_L3P_13,T0_DQS_P | F22 | HR | 13 | IO_L15N_13,T2_DQS_N |
| K17 | HR | 13 | IO_L3N_13,T0_DQS_N | J24 | HR | 13 | IO_L16P_13,T2 |
| M14 | HR | 13 | IO_L4P_13,T0 | H24 | HR | 13 | IO_L16N_13,T2 |
| L14 | HR | 13 | IO_L4N_13,T0 | F23 | HR | 13 | IO_L17P_13,T2 |
| M15 | HR | 13 | IO_L5P_13,T0 | E23 | HR | 13 | IO_L17N_13,T2 |
| L15 | HR | 13 | IO_L5N_13,T0 | K22 | HR | 13 | IO_L18P_13,T2 |
| M16 | HR | 13 | IO_L6P_13,T0 | K23 | HR | 13 | IO_L18N_13,T2 |
| M17 | HR | 13 | IO_L6N_13,T0_VREF,T0 | G24 | HR | 13 | IO_L19P_13,T3 |
| J19 | HR | 13 | IO_L7P_13,T1 | F24 | HR | 13 | IO_L19N_13,T3_VREF,T3 |
| H19 | HR | 13 | IO_L7N_13,T1 | E25 | HR | 13 | IO_L20P_13,T3 |
| L17 | HR | 13 | IO_L8P_13,T1 | D25 | HR | 13 | IO_L20N_13,T3 |
| L18 | HR | 13 | IO_L8N_13,T1 | E26 | HR | 13 | IO_L21P_13,T3_DQS_P |
| J20 | HR | 13 | IO_L9N_13,T1_DQS_N | D26 | HR | 13 | IO_L21N_13,T3_DQS_N |
| K20 | HR | 13 | IO_L9P_13,T1_DQS_P | H26 | HR | 13 | IO_L22P_13,T3 |
| J18 | HR | 13 | IO_L10P_13,T1 | G26 | HR | 13 | IO_L22N_13,T3 |
| H18 | HR | 13 | IO_L10N_13,T1 | G25 | HR | 13 | IO_L23P_13,T3 |
| G20 | HR | 13 | IO_L11P_13,GCLKIOT3,T1 | F25 | HR | 13 | IO_L23N_13,T3 |
| G21 | HR | 13 | IO_L11N_13,GCLKIOC3,T1 | J25 | HR | 13 | IO_L24P_13,T3 |
| K21 | HR | 13 | IO_L12P_13,GCLKIOT2,T1 | J26 | HR | 13 | IO_L24N_13,T3 |
| J21 | HR | 13 | IO_L12N_13,GCLKIOC2,T1 | L19 | HR | 13 | IO_L25_13 |

<!-- 原 PDF 第 115 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H17 | HR | 14 | IO_L0_14 | D19 | HR | 14 | IO_L13P_14,GCLKIOT1,T2 |
| H14 | HR | 14 | IO_L1P_14,T0 | C19 | HR | 14 | IO_L13N_14,GCLKIOC1,T2 |
| H15 | HR | 14 | IO_L1N_14,T0 | E20 | HR | 14 | IO_L14P_14,GCLKIOT0,T2 |
| G17 | HR | 14 | IO_L2P_14,T0 | D20 | HR | 14 | IO_L14N_14,GCLKIOC0,T2 |
| F17 | HR | 14 | IO_L2N_14,T0 | B20 | HR | 14 | IO_L15P_14,T2_DQS_P |
| F18 | HR | 14 | IO_L3P_14,T0_DQS_P | A20 | HR | 14 | IO_L15N_14,T2_DQS_N |
| F19 | HR | 14 | IO_L3N_14,T0_DQS_N | C21 | HR | 14 | IO_L16P_14,T2 |
| G15 | HR | 14 | IO_L4P_14,T0 | B21 | HR | 14 | IO_L16N_14,T2 |
| F15 | HR | 14 | IO_L4N_14,T0 | B22 | HR | 14 | IO_L17P_14,T2 |
| G19 | HR | 14 | IO_L5P_14,T0 | A22 | HR | 14 | IO_L17N_14,T2 |
| F20 | HR | 14 | IO_L5N_14,T0 | E21 | HR | 14 | IO_L18P_14,T2 |
| H16 | HR | 14 | IO_L6P_14,T0 | D21 | HR | 14 | IO_L18N_14,T2 |
| G16 | HR | 14 | IO_L6N_14,T0_VREF,T0 | C22 | HR | 14 | IO_L19P_14,T3 |
| C17 | HR | 14 | IO_L7P_14,T1 | C23 | HR | 14 | IO_L19N_14,T3_VREF,T3 |
| B17 | HR | 14 | IO_L7N_14,T1 | B25 | HR | 14 | IO_L20P_14,T3 |
| E16 | HR | 14 | IO_L8P_14,T1 | A25 | HR | 14 | IO_L20N_14,T3 |
| D16 | HR | 14 | IO_L8N_14,T1 | A23 | HR | 14 | IO_L21P_14,T3_DQS_P |
| A17 | HR | 14 | IO_L9P_14,T1_DQS_P | A24 | HR | 14 | IO_L21N_14,T3_DQS_N |
| A18 | HR | 14 | IO_L9N_14,T1_DQS_N | C26 | HR | 14 | IO_L22P_14,T3 |
| B19 | HR | 14 | IO_L10P_14,T1 | B26 | HR | 14 | IO_L22N_14,T3 |
| A19 | HR | 14 | IO_L10N_14,T1 | C24 | HR | 14 | IO_L23P_14,T3 |
| E17 | HR | 14 | IO_L11P_14,GCLKIOT3,T1 | B24 | HR | 14 | IO_L23N_14,T3 |
| E18 | HR | 14 | IO_L11N_14,GCLKIOC3,T1 | D23 | HR | 14 | IO_L24P_14,T3 |
| D18 | HR | 14 | IO_L12P_14,GCLKIOT2,T1 | D24 | HR | 14 | IO_L24N_14,T3 |
| C18 | HR | 14 | IO_L12N_14,GCLKIOC2,T1 | E22 | HR | 14 | IO_L25_14 |

<!-- 原 PDF 第 116 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N8 | HR | 32 | IO_R0_32 | R3 | HR | 32 | IO_R13P_32,GCLKIOT1,T2 |
| K3 | HR | 32 | IO_R1P_32,T0 | P3 | HR | 32 | IO_R13N_32,GCLKIOC1,T2 |
| J3 | HR | 32 | IO_R1N_32,T0 | P4 | HR | 32 | IO_R14P_32,GCLKIOT0,T2 |
| M7 | HR | 32 | IO_R2P_32,T0 | N4 | HR | 32 | IO_R14N_32,GCLKIOC0,T2 |
| L7 | HR | 32 | IO_R2N_32,T0 | R1 | HR | 32 | IO_R15P_32,T2_DQS_P |
| M4 | HR | 32 | IO_R3P_32,T0_DQS_P | P1 | HR | 32 | IO_R15N_32,T2_DQS_N |
| L4 | HR | 32 | IO_R3N_32,T0_DQS_N | T4 | HR | 32 | IO_R16P_32,T2 |
| L5 | HR | 32 | IO_R4P_32,T0 | T3 | HR | 32 | IO_R16N_32,T2 |
| K5 | HR | 32 | IO_R4N_32,T0 | T2 | HR | 32 | IO_R17P_32,T2 |
| N7 | HR | 32 | IO_R5P_32,T0 | R2 | HR | 32 | IO_R17N_32,T2 |
| N6 | HR | 32 | IO_R5N_32,T0 | U2 | HR | 32 | IO_R18P_32,T2 |
| M6 | HR | 32 | IO_R6P_32,T0 | U1 | HR | 32 | IO_R18N_32,T2 |
| M5 | HR | 32 | IO_R6N_32,T0_VREF,T0 | P6 | HR | 32 | IO_R19P_32,T3 |
| K1 | HR | 32 | IO_R7P_32,T1 | P5 | HR | 32 | IO_R19N_32,T3_VREF,T3 |
| J1 | HR | 32 | IO_R7N_32,T1 | T5 | HR | 32 | IO_R20P_32,T3 |
| L3 | HR | 32 | IO_R8P_32,T1 | R5 | HR | 32 | IO_R20N_32,T3 |
| K2 | HR | 32 | IO_R8N_32,T1 | U6 | HR | 32 | IO_R21P_32,T3_DQS_P |
| N1 | HR | 32 | IO_R9P_32,T1_DQS_P | U5 | HR | 32 | IO_R21N_32,T3_DQS_N |
| M1 | HR | 32 | IO_R9N_32,T1_DQS_N | R8 | HR | 32 | IO_R22P_32,T3 |
| H2 | HR | 32 | IO_R10P_32,T1 | P8 | HR | 32 | IO_R22N_32,T3 |
| H1 | HR | 32 | IO_R10N_32,T1 | R7 | HR | 32 | IO_R23P_32,T3 |
| M2 | HR | 32 | IO_R11P_32,GCLKIOT3,T1 | R6 | HR | 32 | IO_R23N_32,T3 |
| L2 | HR | 32 | IO_R11N_32,GCLKIOC3,T1 | T8 | HR | 32 | IO_R24P_32,T3 |
| N3 | HR | 32 | IO_R12P_32,GCLKIOT2,T1 | T7 | HR | 32 | IO_R24N_32,T3 |
| N2 | HR | 32 | IO_R12N_32,GCLKIOC2,T1 | U4 | HR | 32 | IO_R25_32 |

<!-- 原 PDF 第 117 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J8 | HR | 33 | IO_R0_33 | E5 | HR | 33 | IO_R13P_33,GCLKIOT1,T2 |
| E6 | HR | 33 | IO_R1P_33,T0 | D5 | HR | 33 | IO_R13N_33,GCLKIOC1,T2 |
| D6 | HR | 33 | IO_R1N_33,T0 | D4 | HR | 33 | IO_R14P_33,GCLKIOT0,T2 |
| H8 | HR | 33 | IO_R2P_33,T0 | C4 | HR | 33 | IO_R14N_33,GCLKIOC0,T2 |
| G8 | HR | 33 | IO_R2N_33,T0 | B5 | HR | 33 | IO_R15P_33,T2_DQS_P |
| H7 | HR | 33 | IO_R3P_33,T0_DQS_P | A5 | HR | 33 | IO_R15N_33,T2_DQS_N |
| G7 | HR | 33 | IO_R3N_33,T0_DQS_N | B4 | HR | 33 | IO_R16P_33,T2 |
| F8 | HR | 33 | IO_R4P_33,T0 | A4 | HR | 33 | IO_R16N_33,T2 |
| F7 | HR | 33 | IO_R4N_33,T0 | D3 | HR | 33 | IO_R17P_33,T2 |
| H6 | HR | 33 | IO_R5P_33,T0 | C3 | HR | 33 | IO_R17N_33,T2 |
| G6 | HR | 33 | IO_R5N_33,T0 | F3 | HR | 33 | IO_R18P_33,T2 |
| H9 | HR | 33 | IO_R6P_33,T0 | E3 | HR | 33 | IO_R18N_33,T2 |
| G9 | HR | 33 | IO_R6N_33,T0_VREF,T0 | C2 | HR | 33 | IO_R19P_33,T3 |
| J6 | HR | 33 | IO_R7P_33,T1 | B2 | HR | 33 | IO_R19N_33,T3_VREF,T3 |
| J5 | HR | 33 | IO_R7N_33,T1 | A3 | HR | 33 | IO_R20P_33,T3 |
| L8 | HR | 33 | IO_R8P_33,T1 | A2 | HR | 33 | IO_R20N_33,T3 |
| K8 | HR | 33 | IO_R8N_33,T1 | C1 | HR | 33 | IO_R21P_33,T3_DQS_P |
| J4 | HR | 33 | IO_R9P_33,T1_DQS_P | B1 | HR | 33 | IO_R21N_33,T3_DQS_N |
| H4 | HR | 33 | IO_R9N_33,T1_DQS_N | F2 | HR | 33 | IO_R22P_33,T3 |
| K7 | HR | 33 | IO_R10P_33,T1 | E2 | HR | 33 | IO_R22N_33,T3 |
| K6 | HR | 33 | IO_R10N_33,T1 | E1 | HR | 33 | IO_R23P_33,T3 |
| G4 | HR | 33 | IO_R11P_33,GCLKIOT3,T1 | D1 | HR | 33 | IO_R23N_33,T3 |
| F4 | HR | 33 | IO_R11N_33,GCLKIOC3,T1 | G2 | HR | 33 | IO_R24P_33,T3 |
| G5 | HR | 33 | IO_R12P_33,GCLKIOT2,T1 | G1 | HR | 33 | IO_R24N_33,T3 |
| F5 | HR | 33 | IO_R12N_33,GCLKIOC2,T1 | H3 | HR | 33 | IO_R25_33 |

<!-- 原 PDF 第 118 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AE11 | - | 91 | RX0P_91 | B11 | - | 94 | RX0P_94 |
| AF11 | - | 91 | RX0N_91 | A11 | - | 94 | RX0N_94 |
| AC14 | - | 91 | RX1P_91 | D14 | - | 94 | RX1P_94 |
| AD14 | - | 91 | RX1N_91 | C14 | - | 94 | RX1N_94 |
| AE13 | - | 91 | RX2P_91 | B13 | - | 94 | RX2P_94 |
| AF13 | - | 91 | RX2N_91 | A13 | - | 94 | RX2N_94 |
| AC12 | - | 91 | RX3P_91 | D12 | - | 94 | RX3P_94 |
| AD12 | - | 91 | RX3N_91 | C12 | - | 94 | RX3N_94 |
| AE7 | - | 91 | TX0P_91 | B7 | - | 94 | TX0P_94 |
| AF7 | - | 91 | TX0N_91 | A7 | - | 94 | TX0N_94 |
| AC8 | - | 91 | TX1P_91 | D8 | - | 94 | TX1P_94 |
| AD8 | - | 91 | TX1N_91 | C8 | - | 94 | TX1N_94 |
| AE9 | - | 91 | TX2P_91 | B9 | - | 94 | TX2P_94 |
| AF9 | - | 91 | TX2N_91 | A9 | - | 94 | TX2N_94 |
| AC10 | - | 91 | TX3P_91 | D10 | - | 94 | TX3P_94 |
| AD10 | - | 91 | TX3N_91 | C10 | - | 94 | TX3N_94 |

<!-- 原 PDF 第 119 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H13 | HR | 0 | IO_C0_0,CCLK_0 | W11 | - | 0 | VCCIO_0 |
| W10 | - | 0 | DONE_0 | Y14 | - | 0 | VCCIO_0 |
| V11 | - | 0 | INITN_0 | AC25 | - | 11 | VCCIO_11 |
| AB7 | - | 0 | M0_0 | T16 | - | 11 | VCCIO_11 |
| Y9 | - | 0 | M1_0 | T26 | - | 11 | VCCIO_11 |
| W9 | - | 0 | M2_0 | U23 | - | 11 | VCCIO_11 |
| AE16 | - | 0 | PROGRAMN_0 | V20 | - | 11 | VCCIO_11 |
| H12 | - | 0 | TCK_0 | Y24 | - | 11 | VCCIO_11 |
| H10 | - | 0 | TDI_0 | K24 | - | 12 | VCCIO_12 |
| J10 | - | 0 | TDO_0 | L21 | - | 12 | VCCIO_12 |
| H11 | - | 0 | TMS_0 | N15 | - | 12 | VCCIO_12 |
| N25 | - | 12 | VCCIO_12 |  |  |  |  |
| P22 | - | 12 | VCCIO_12 |  |  |  |  |
| R19 | - | 12 | VCCIO_12 |  |  |  |  |
| F26 | - | 13 | VCCIO_13 |  |  |  |  |
| G23 | - | 13 | VCCIO_13 |  |  |  |  |
| H20 | - | 13 | VCCIO_13 |  |  |  |  |
| J17 | - | 13 | VCCIO_13 |  |  |  |  |
| K14 | - | 13 | VCCIO_13 |  |  |  |  |
| M18 | - | 13 | VCCIO_13 |  |  |  |  |
| A21 | - | 14 | VCCIO_14 |  |  |  |  |
| B18 | - | 14 | VCCIO_14 |  |  |  |  |
| C25 | - | 14 | VCCIO_14 |  |  |  |  |
| D22 | - | 14 | VCCIO_14 |  |  |  |  |
| E19 | - | 14 | VCCIO_14 |  |  |  |  |
| F16 | - | 14 | VCCIO_14 |  |  |  |  |

<!-- 原 PDF 第 120 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K4 | - | 32 | VCCIO_32 | AD15 | - | 91 | PHYVCCT_91 |
| L1 | - | 32 | VCCIO_32 | AD7 | - | 91 | PHYVCCT_91 |
| M8 | - | 32 | VCCIO_32 | AE10 | - | 91 | PHYVCCT_91 |
| N5 | - | 32 | VCCIO_32 | AE12 | - | 91 | PHYVCCT_91 |
| P2 | - | 32 | VCCIO_32 | AE14 | - | 91 | PHYVCCT_91 |
| T6 | - | 32 | VCCIO_32 | AE8 | - | 91 | PHYVCCT_91 |
| A1 | - | 33 | VCCIO_33 | AA11 | - | 91 | REFCLK0P_91 |
| C5 | - | 33 | VCCIO_33 | AB11 | - | 91 | REFCLK0N_91 |
| D2 | - | 33 | VCCIO_33 | AA13 | - | 91 | REFCLK1P_91 |
| F6 | - | 33 | VCCIO_33 | AB13 | - | 91 | REFCLK1N_91 |
| G3 | - | 33 | VCCIO_33 | AF15 | - | 91 | RESREF_91 |
| J7 | - | 33 | VCCIO_33 | B10 | - | 94 | PHYVCCT_94 |
| AA21 | - | 21 | VCCIO_21 | B12 | - | 94 | PHYVCCT_94 |
| AB18 | - | 21 | VCCIO_21 | B14 | - | 94 | PHYVCCT_94 |
| AD22 | - | 21 | VCCIO_21 | B8 | - | 94 | PHYVCCT_94 |
| AE19 | - | 21 | VCCIO_21 | C15 | - | 94 | PHYVCCT_94 |
| AF26 | - | 21 | VCCIO_21 | C7 | - | 94 | PHYVCCT_94 |
| W17 | - | 21 | VCCIO_21 | F11 | - | 94 | REFCLK0P_94 |
| AA1 | - | 22 | VCCIO_22 | E11 | - | 94 | REFCLK0N_94 |
| AC5 | - | 22 | VCCIO_22 | F13 | - | 94 | REFCLK1P_94 |
| AD2 | - | 22 | VCCIO_22 | E13 | - | 94 | REFCLK1N_94 |
| U3 | - | 22 | VCCIO_22 | A15 | - | 94 | RESREF_94 |
| W7 | - | 22 | VCCIO_22 |  |  |  |  |
| Y4 | - | 22 | VCCIO_22 |  |  |  |  |

<!-- 原 PDF 第 121 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J11 | - | - | VCCINT | A10 | - | - | GND |
| J13 | - | - | VCCINT | A12 | - | - | GND |
| K10 | - | - | VCCINT | A14 | - | - | GND |
| K12 | - | - | VCCINT | A16 | - | - | GND |
| L11 | - | - | VCCINT | A26 | - | - | GND |
| L13 | - | - | VCCINT | A6 | - | - | GND |
| M10 | - | - | VCCINT | A8 | - | - | GND |
| P10 | - | - | VCCINT | AA14 | - | - | GND |
| T10 | - | - | VCCINT | AA16 | - | - | GND |
| T12 | - | - | VCCINT | AA26 | - | - | GND |
| U11 | - | - | VCCINT | AA6 | - | - | GND |
| V10 | - | - | VCCINT | AA9 | - | - | GND |
| V12 | - | - | VCCINT | AB10 | - | - | GND |
| L9 | - | - | VCCAUX_IO | AB12 | - | - | GND |
| N9 | - | - | VCCAUX_IO | AB14 | - | - | GND |
| R9 | - | - | VCCAUX_IO | AB23 | - | - | GND |
| J9 | - | - | VCCAUX | AB3 | - | - | GND |
| U9 | - | - | VCCAUX | AB8 | - | - | GND |
| AB9 | - | - | GND |  |  |  |  |
| AC15 | - | - | GND |  |  |  |  |
| AC20 | - | - | GND |  |  |  |  |
| AC7 | - | - | GND |  |  |  |  |
| AD11 | - | - | GND |  |  |  |  |
| AD13 | - | - | GND |  |  |  |  |
| AD16 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 122 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AD6 | - | - | GND | D15 | - | - | GND |
| AD9 | - | - | GND | D17 | - | - | GND |
| AE15 | - | - | GND | D7 | - | - | GND |
| AE24 | - | - | GND | E10 | - | - | GND |
| AE4 | - | - | GND | E12 | - | - | GND |
| AE6 | - | - | GND | E14 | - | - | GND |
| AF1 | - | - | GND | E15 | - | - | GND |
| AF10 | - | - | GND | E24 | - | - | GND |
| AF12 | - | - | GND | E4 | - | - | GND |
| AF14 | - | - | GND | E7 | - | - | GND |
| AF16 | - | - | GND | E8 | - | - | GND |
| AF21 | - | - | GND | E9 | - | - | GND |
| AF6 | - | - | GND | F1 | - | - | GND |
| AF8 | - | - | GND | F14 | - | - | GND |
| B15 | - | - | GND | F21 | - | - | GND |
| B16 | - | - | GND | F9 | - | - | GND |
| B23 | - | - | GND | G10 | - | - | GND |
| B3 | - | - | GND | G11 | - | - | GND |
| B6 | - | - | GND | G12 | - | - | GND |
| C11 | - | - | GND | G13 | - | - | GND |
| C13 | - | - | GND | G18 | - | - | GND |
| C16 | - | - | GND | H25 | - | - | GND |
| C20 | - | - | GND | H5 | - | - | GND |
| C6 | - | - | GND | J12 | - | - | GND |
| C9 | - | - | GND | J2 | - | - | GND |

<!-- 原 PDF 第 123 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J22 | - | - | GND | T13 | - | - | GND |
| K11 | - | - | GND | T21 | - | - | GND |
| K13 | - | - | GND | T9 | - | - | GND |
| K19 | - | - | GND | U10 | - | - | GND |
| K9 | - | - | GND | U12 | - | - | GND |
| L10 | - | - | GND | U18 | - | - | GND |
| L12 | - | - | GND | U8 | - | - | GND |
| L16 | - | - | GND | V13 | - | - | GND |
| L26 | - | - | GND | V15 | - | - | GND |
| L6 | - | - | GND | V25 | - | - | GND |
| M13 | - | - | GND | V5 | - | - | GND |
| M23 | - | - | GND | W12 | - | - | GND |
| M3 | - | - | GND | W2 | - | - | GND |
| M9 | - | - | GND | W22 | - | - | GND |
| N10 | - | - | GND | Y10 | - | - | GND |
| N20 | - | - | GND | Y11 | - | - | GND |
| P13 | - | - | GND | Y12 | - | - | GND |
| P17 | - | - | GND | Y13 | - | - | GND |
| P7 | - | - | GND | Y19 | - | - | GND |
| P9 | - | - | GND |  |  |  |  |
| R10 | - | - | GND |  |  |  |  |
| R24 | - | - | GND |  |  |  |  |
| R4 | - | - | GND |  |  |  |  |
| T1 | - | - | GND |  |  |  |  |
| T11 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 124 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AB15 | - | - | NC | AB1 | - | - | NC |
| R11 | - | - | NC | AB16 | - | - | NC |
| R12 | - | - | NC | AB17 | - | - | NC |
| M11 | - | - | NC | AB19 | - | - | NC |
| AA10 | - | - | NC | AB2 | - | - | NC |
| AA12 | - | - | NC | AB20 | - | - | NC |
| AC11 | - | - | NC | AB21 | - | - | NC |
| AC13 | - | - | NC | AB22 | - | - | NC |
| AC9 | - | - | NC | AB4 | - | - | NC |
| D11 | - | - | NC | AB5 | - | - | NC |
| D13 | - | - | NC | AB6 | - | - | NC |
| D9 | - | - | NC | AC1 | - | - | NC |
| F10 | - | - | NC | AC16 | - | - | NC |
| F12 | - | - | NC | AC17 | - | - | NC |
| AA15 | - | - | NC | AC18 | - | - | NC |
| AA17 | - | - | NC | AC19 | - | - | NC |
| AA18 | - | - | NC | AC2 | - | - | NC |
| AA19 | - | - | NC | AC21 | - | - | NC |
| AA2 | - | - | NC | AC22 | - | - | NC |
| AA20 | - | - | NC | AC23 | - | - | NC |
| AA3 | - | - | NC | AC3 | - | - | NC |
| AA4 | - | - | NC | AC4 | - | - | NC |
| AA5 | - | - | NC | AC6 | - | - | NC |
| AA7 | - | - | NC | AD1 | - | - | NC |
| AA8 | - | - | NC | AD17 | - | - | NC |

<!-- 原 PDF 第 125 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AD18 | - | - | NC | AF19 | - | - | NC |
| AD19 | - | - | NC | AF2 | - | - | NC |
| AD20 | - | - | NC | AF20 | - | - | NC |
| AD21 | - | - | NC | AF22 | - | - | NC |
| AD23 | - | - | NC | AF23 | - | - | NC |
| AD24 | - | - | NC | AF24 | - | - | NC |
| AD25 | - | - | NC | AF25 | - | - | NC |
| AD26 | - | - | NC | AF3 | - | - | NC |
| AD3 | - | - | NC | AF4 | - | - | NC |
| AD4 | - | - | NC | AF5 | - | - | NC |
| AD5 | - | - | NC | U7 | - | - | NC |
| AE1 | - | - | NC | V1 | - | - | NC |
| AE17 | - | - | NC | V2 | - | - | NC |
| AE18 | - | - | NC | V3 | - | - | NC |
| AE2 | - | - | NC | V4 | - | - | NC |
| AE20 | - | - | NC | V6 | - | - | NC |
| AE21 | - | - | NC | V7 | - | - | NC |
| AE22 | - | - | NC | V8 | - | - | NC |
| AE23 | - | - | NC | V9 | - | - | NC |
| AE25 | - | - | NC | W1 | - | - | NC |
| AE26 | - | - | NC | W16 | - | - | NC |
| AE3 | - | - | NC | W3 | - | - | NC |
| AE5 | - | - | NC | W4 | - | - | NC |
| AF17 | - | - | NC | W5 | - | - | NC |
| AF18 | - | - | NC | W6 | - | - | NC |

<!-- 原 PDF 第 126 页 -->


| 编号 | 类型 | BANK | PH1P100SBG677引脚名称 | 编号 | 类型 | BANK | PH1P100SBG677引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W8 | - | - | NC |  |  |  |  |
| Y1 | - | - | NC |  |  |  |  |
| Y15 | - | - | NC |  |  |  |  |
| Y16 | - | - | NC |  |  |  |  |
| Y17 | - | - | NC |  |  |  |  |
| Y18 | - | - | NC |  |  |  |  |
| Y2 | - | - | NC |  |  |  |  |
| Y3 | - | - | NC |  |  |  |  |
| Y5 | - | - | NC |  |  |  |  |
| Y6 | - | - | NC |  |  |  |  |
| Y7 | - | - | NC |  |  |  |  |
| Y8 | - | - | NC |  |  |  |  |
| W14 | - | - | NC |  |  |  |  |
| W15 | - | - | NC |  |  |  |  |
| M12 | - | - | NC |  |  |  |  |
| G14 | - | - | NC |  |  |  |  |
| N13 | - | - | NC |  |  |  |  |
| R13 | - | - | NC |  |  |  |  |
| U13 | - | - | NC |  |  |  |  |
| W13 | - | - | NC |  |  |  |  |
| P11 | - | - | NC |  |  |  |  |
| N12 | - | - | NC |  |  |  |  |
| N11 | - | - | NC |  |  |  |  |
| P12 | - | - | NC |  |  |  |  |

<!-- 原 PDF 第 127 页 -->

### 4.5 PH1P100SBG484引脚信息

| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Y17 | HR | 11 | IO_L0_11 | AA11 | HR | 11 | IO_L9N_11,T1_DQS_N |
| Y16 | HR | 11 | IO_L1P_11,T0 | V10 | HR | 11 | IO_L10P_11,T1 |
| AA16 | HR | 11 | IO_L1N_11,T0 | W10 | HR | 11 | IO_L10N_11,T1 |
| AB16 | HR | 11 | IO_L2P_11,T0 | Y11 | HR | 11 | IO_L11P_11,GCLKIOT3,T1 |
| AB17 | HR | 11 | IO_L2N_11,T0 | Y12 | HR | 11 | IO_L11N_11,GCLKIOC3,T1 |
| AA13 | HR | 11 | IO_L3P_11,T0_DQS_P | W11 | HR | 11 | IO_L12P_11,GCLKIOT2,T1 |
| AB13 | HR | 11 | IO_L3N_11,T0_DQS_N | W12 | HR | 11 | IO_L12N_11,GCLKIOC2,T1 |
| AA15 | HR | 11 | IO_L4P_11,T0 | V13 | HR | 11 | IO_L13P_11,GCLKIOT1,T2 |
| AB15 | HR | 11 | IO_L4N_11,T0 | V14 | HR | 11 | IO_L13N_11,GCLKIOC1,T2 |
| Y13 | HR | 11 | IO_L5P_11,T0 | U15 | HR | 11 | IO_L14P_11,GCLKIOT0,T2 |
| AA14 | HR | 11 | IO_L5N_11,T0 | V15 | HR | 11 | IO_L14N_11,GCLKIOC0,T2 |
| W14 | HR | 11 | IO_L6P_11,T0 | T14 | HR | 11 | IO_L15P_11,T2_DQS_P |
| Y14 | HR | 11 | IO_L6N_11,T0_VREF,T0 | T15 | HR | 11 | IO_L15N_11,T2_DQS_N |
| AB11 | HR | 11 | IO_L7P_11,T1 | W15 | HR | 11 | IO_L16P_11,T2 |
| AB12 | HR | 11 | IO_L7N_11,T1 | W16 | HR | 11 | IO_L16N_11,T2 |
| AA9 | HR | 11 | IO_L8P_11,T1 | T16 | HR | 11 | IO_L17P_11,T2 |
| AB10 | HR | 11 | IO_L8N_11,T1 | U16 | HR | 11 | IO_L17N_11,T2 |
| AA10 | HR | 11 | IO_L9P_11,T1_DQS_P |  |  |  |  |

<!-- 原 PDF 第 128 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P20 | HR | 12 | IO_L0_12 | Y18 | HR | 12 | IO_L13P_12,GCLKIOT1,T2 |
| P22 | HR | 12 | IO_L1P_12,D0,MOSI,T0 | Y19 | HR | 12 | IO_L13N_12,GCLKIOC1,T2 |
| R22 | HR | 12 | IO_L1N_12,D1,MISO,DIN,T0 | V18 | HR | 12 | IO_L14P_12,GCLKIOT0,T2 |
| P21 | HR | 12 | IO_L2P_12,D2,WPN,T0 | V19 | HR | 12 | IO_L14N_12,GCLKIOC0,T2 |
| R21 | HR | 12 | IO_L2N_12,D3,HOLDN,T0 | AA19 | HR | 12 | IO_L15P_12,RDWRN,T2_DQS_P |
| U22 | HR | 12 | IO_L3P_12,HSWAPEN,T0_DQS_P | AB20 | HR | 12 | IO_L15N_12,CSON,DOUT,T2_DQS_N |
| V22 | HR | 12 | IO_L3N_12,USRCLK,T0_DQS_N | V17 | HR | 12 | IO_L16P_12,CSN,T2 |
| T21 | HR | 12 | IO_L4P_12,D4,T0 | W17 | HR | 12 | IO_L16N_12,D31,T2 |
| U21 | HR | 12 | IO_L4N_12,D5,T0 | AA18 | HR | 12 | IO_L17P_12,D30,T2 |
| P19 | HR | 12 | IO_L5P_12,D6,T0 | AB18 | HR | 12 | IO_L17N_12,D29,T2 |
| R19 | HR | 12 | IO_L5N_12,D7,T0 | U17 | HR | 12 | IO_L18P_12,D28,T2 |
| T19 | HR | 12 | IO_L6P_12,SPICSN,BUSY,T0 | U18 | HR | 12 | IO_L18N_12,D27,T2 |
| T20 | HR | 12 | IO_L6N_12,D8,T0_VREF,T0 | P14 | HR | 12 | IO_L19P_12,D26,T3 |
| W21 | HR | 12 | IO_L7P_12,D9,T1 | R14 | HR | 12 | IO_L19N_12,D25,T3_VREF,T3 |
| W22 | HR | 12 | IO_L7N_12,D10,T1 | R18 | HR | 12 | IO_L20P_12,D24,T3 |
| AA20 | HR | 12 | IO_L8P_12,D11,T1 | T18 | HR | 12 | IO_L20N_12,D23,T3 |
| AA21 | HR | 12 | IO_L8N_12,D12,T1 | N17 | HR | 12 | IO_L21P_12,T3_DQS_P |
| Y21 | HR | 12 | IO_L9P_12,T1_DQS_P | P17 | HR | 12 | IO_L21N_12,D22,T3_DQS_N |
| Y22 | HR | 12 | IO_L9N_12,D13,T1_DQS_N | P15 | HR | 12 | IO_L22P_12,D21,T3 |
| AB21 | HR | 12 | IO_L10P_12,D14,T1 | R16 | HR | 12 | IO_L22N_12,D20,T3 |
| AB22 | HR | 12 | IO_L10N_12,D15,T1 | N13 | HR | 12 | IO_L23P_12,D19,T3 |
| U20 | HR | 12 | IO_L11P_12,GCLKIOT3,T1 | N14 | HR | 12 | IO_L23N_12,D18,T3 |
| V20 | HR | 12 | IO_L11N_12,GCLKIOC3,T1 | P16 | HR | 12 | IO_L24P_12,D17,T3 |
| W19 | HR | 12 | IO_L12P_12,GCLKIOT2,T1 | R17 | HR | 12 | IO_L24N_12,D16,T3 |
| W20 | HR | 12 | IO_L12N_12,GCLKIOC2,T1 | N15 | HR | 12 | IO_L25_12 |

<!-- 原 PDF 第 129 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| J16 | HR | 13 | IO_L0_13 | K18 | HR | 13 | IO_L13P_13,GCLKIOT1,T2 |
| H13 | HR | 13 | IO_L1P_13,T0 | K19 | HR | 13 | IO_L13N_13,GCLKIOC1,T2 |
| G13 | HR | 13 | IO_L1N_13,T0 | L19 | HR | 13 | IO_L14P_13,GCLKIOT0,T2 |
| G15 | HR | 13 | IO_L2P_13,T0 | L20 | HR | 13 | IO_L14N_13,GCLKIOC0,T2 |
| G16 | HR | 13 | IO_L2N_13,T0 | N22 | HR | 13 | IO_L15P_13,T2_DQS_P |
| J14 | HR | 13 | IO_L3P_13,T0_DQS_P | M22 | HR | 13 | IO_L15N_13,T2_DQS_N |
| H14 | HR | 13 | IO_L3N_13,T0_DQS_N | M18 | HR | 13 | IO_L16P_13,T2 |
| G17 | HR | 13 | IO_L4P_13,T0 | L18 | HR | 13 | IO_L16N_13,T2 |
| G18 | HR | 13 | IO_L4N_13,T0 | N18 | HR | 13 | IO_L17P_13,T2 |
| J15 | HR | 13 | IO_L5P_13,T0 | N19 | HR | 13 | IO_L17N_13,T2 |
| H15 | HR | 13 | IO_L5N_13,T0 | N20 | HR | 13 | IO_L18P_13,T2 |
| H17 | HR | 13 | IO_L6P_13,T0 | M20 | HR | 13 | IO_L18N_13,T2 |
| H18 | HR | 13 | IO_L6N_13,T0_VREF,T0 | K13 | HR | 13 | IO_L19P_13,T3 |
| J22 | HR | 13 | IO_L7P_13,T1 | K14 | HR | 13 | IO_L19N_13,T3_VREF,T3 |
| H22 | HR | 13 | IO_L7N_13,T1 | M13 | HR | 13 | IO_L20P_13,T3 |
| H20 | HR | 13 | IO_L8P_13,T1 | L13 | HR | 13 | IO_L20N_13,T3 |
| G20 | HR | 13 | IO_L8N_13,T1 | K17 | HR | 13 | IO_L21P_13,T3_DQS_P |
| K21 | HR | 13 | IO_L9P_13,T1_DQS_P | J17 | HR | 13 | IO_L21N_13,T3_DQS_N |
| K22 | HR | 13 | IO_L9N_13,T1_DQS_N | L14 | HR | 13 | IO_L22P_13,T3 |
| M21 | HR | 13 | IO_L10P_13,T1 | L15 | HR | 13 | IO_L22N_13,T3 |
| L21 | HR | 13 | IO_L10N_13,T1 | L16 | HR | 13 | IO_L23P_13,T3 |
| J20 | HR | 13 | IO_L11P_13,GCLKIOT3,T1 | K16 | HR | 13 | IO_L23N_13,T3 |
| J21 | HR | 13 | IO_L11N_13,GCLKIOC3,T1 | M15 | HR | 13 | IO_L24P_13,T3 |
| J19 | HR | 13 | IO_L12P_13,GCLKIOT2,T1 | M16 | HR | 13 | IO_L24N_13,T3 |
| H19 | HR | 13 | IO_L12N_13,GCLKIOC2,T1 | M17 | HR | 13 | IO_L25_13 |

<!-- 原 PDF 第 130 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F15 | HR | 14 | IO_L0_14 | C18 | HR | 14 | IO_L13P_14,GCLKIOT1,T2 |
| F13 | HR | 14 | IO_L1P_14,T0 | C19 | HR | 14 | IO_L13N_14,GCLKIOC1,T2 |
| F14 | HR | 14 | IO_L1N_14,T0 | E19 | HR | 14 | IO_L14P_14,GCLKIOT0,T2 |
| F16 | HR | 14 | IO_L2P_14,T0 | D19 | HR | 14 | IO_L14N_14,GCLKIOC0,T2 |
| E17 | HR | 14 | IO_L2N_14,T0 | F18 | HR | 14 | IO_L15P_14,T2_DQS_P |
| C14 | HR | 14 | IO_L3P_14,T0_DQS_P | E18 | HR | 14 | IO_L15N_14,T2_DQS_N |
| C15 | HR | 14 | IO_L3N_14,T0_DQS_N | B20 | HR | 14 | IO_L16P_14,T2 |
| E13 | HR | 14 | IO_L4P_14,T0 | A20 | HR | 14 | IO_L16N_14,T2 |
| E14 | HR | 14 | IO_L4N_14,T0 | A18 | HR | 14 | IO_L17P_14,T2 |
| E16 | HR | 14 | IO_L5P_14,T0 | A19 | HR | 14 | IO_L17N_14,T2 |
| D16 | HR | 14 | IO_L5N_14,T0 | F19 | HR | 14 | IO_L18P_14,T2 |
| D14 | HR | 14 | IO_L6P_14,T0 | F20 | HR | 14 | IO_L18N_14,T2 |
| D15 | HR | 14 | IO_L6N_14,T0_VREF,T0 | D20 | HR | 14 | IO_L19P_14,T3 |
| B15 | HR | 14 | IO_L7P_14,T1 | C20 | HR | 14 | IO_L19N_14,T3_VREF,T3 |
| B16 | HR | 14 | IO_L7N_14,T1 | C22 | HR | 14 | IO_L20P_14,T3 |
| C13 | HR | 14 | IO_L8P_14,T1 | B22 | HR | 14 | IO_L20N_14,T3 |
| B13 | HR | 14 | IO_L8N_14,T1 | B21 | HR | 14 | IO_L21P_14,T3_DQS_P |
| A15 | HR | 14 | IO_L9P_14,T1_DQS_P | A21 | HR | 14 | IO_L21N_14,T3_DQS_N |
| A16 | HR | 14 | IO_L9N_14,T1_DQS_N | E22 | HR | 14 | IO_L22P_14,T3 |
| A13 | HR | 14 | IO_L10P_14,T1 | D22 | HR | 14 | IO_L22N_14,T3 |
| A14 | HR | 14 | IO_L10N_14,T1 | E21 | HR | 14 | IO_L23P_14,T3 |
| B17 | HR | 14 | IO_L11P_14,GCLKIOT3,T1 | D21 | HR | 14 | IO_L23N_14,T3 |
| B18 | HR | 14 | IO_L11N_14,GCLKIOC3,T1 | G21 | HR | 14 | IO_L24P_14,T3 |
| D17 | HR | 14 | IO_L12P_14,GCLKIOT2,T1 | G22 | HR | 14 | IO_L24N_14,T3 |
| C17 | HR | 14 | IO_L12N_14,GCLKIOC2,T1 | F21 | HR | 14 | IO_L25_14 |

<!-- 原 PDF 第 131 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T3 | HR | 32 | IO_R0_32 | R4 | HR | 32 | IO_R13P_32,GCLKIOT1,T2 |
| T1 | HR | 32 | IO_R1P_32,T0 | T4 | HR | 32 | IO_R13N_32,GCLKIOC1,T2 |
| U1 | HR | 32 | IO_R1N_32,T0 | T5 | HR | 32 | IO_R14P_32,GCLKIOT0,T2 |
| U2 | HR | 32 | IO_R2P_32,T0 | U5 | HR | 32 | IO_R14N_32,GCLKIOC0,T2 |
| V2 | HR | 32 | IO_R2N_32,T0 | W6 | HR | 32 | IO_R15P_32,T2_DQS_P |
| R3 | HR | 32 | IO_R3P_32,T0_DQS_P | W5 | HR | 32 | IO_R15N_32,T2_DQS_N |
| R2 | HR | 32 | IO_R3N_32,T0_DQS_N | U6 | HR | 32 | IO_R16P_32,T2 |
| W2 | HR | 32 | IO_R4P_32,T0 | V5 | HR | 32 | IO_R16N_32,T2 |
| Y2 | HR | 32 | IO_R4N_32,T0 | R6 | HR | 32 | IO_R17P_32,T2 |
| W1 | HR | 32 | IO_R5P_32,T0 | T6 | HR | 32 | IO_R17N_32,T2 |
| Y1 | HR | 32 | IO_R5N_32,T0 | Y6 | HR | 32 | IO_R18P_32,T2 |
| U3 | HR | 32 | IO_R6P_32,T0 | AA6 | HR | 32 | IO_R18N_32,T2 |
| V3 | HR | 32 | IO_R6N_32,T0_VREF,T0 | V7 | HR | 32 | IO_R19P_32,T3 |
| AA1 | HR | 32 | IO_R7P_32,T1 | W7 | HR | 32 | IO_R19N_32,T3_VREF,T3 |
| AB1 | HR | 32 | IO_R7N_32,T1 | AB7 | HR | 32 | IO_R20P_32,T3 |
| AB3 | HR | 32 | IO_R8P_32,T1 | AB6 | HR | 32 | IO_R20N_32,T3 |
| AB2 | HR | 32 | IO_R8N_32,T1 | V9 | HR | 32 | IO_R21P_32,T3_DQS_P |
| Y3 | HR | 32 | IO_R9P_32,T1_DQS_P | V8 | HR | 32 | IO_R21N_32,T3_DQS_N |
| AA3 | HR | 32 | IO_R9N_32,T1_DQS_N | AA8 | HR | 32 | IO_R22P_32,T3 |
| AA5 | HR | 32 | IO_R10P_32,T1 | AB8 | HR | 32 | IO_R22N_32,T3 |
| AB5 | HR | 32 | IO_R10N_32,T1 | Y8 | HR | 32 | IO_R23P_32,T3 |
| Y4 | HR | 32 | IO_R11P_32,GCLKIOT3,T1 | Y7 | HR | 32 | IO_R23N_32,T3 |
| AA4 | HR | 32 | IO_R11N_32,GCLKIOC3,T1 | W9 | HR | 32 | IO_R24P_32,T3 |
| V4 | HR | 32 | IO_R12P_32,GCLKIOT2,T1 | Y9 | HR | 32 | IO_R24N_32,T3 |
| W4 | HR | 32 | IO_R12N_32,GCLKIOC2,T1 | U7 | HR | 32 | IO_R25_32 |

<!-- 原 PDF 第 132 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F4 | HR | 33 | IO_R0_33 | K4 | HR | 33 | IO_R13P_33,GCLKIOT1,T2 |
| B1 | HR | 33 | IO_R1P_33,T0 | J4 | HR | 33 | IO_R13N_33,GCLKIOC1,T2 |
| A1 | HR | 33 | IO_R1N_33,T0 | L3 | HR | 33 | IO_R14P_33,GCLKIOT0,T2 |
| C2 | HR | 33 | IO_R2P_33,T0 | K3 | HR | 33 | IO_R14N_33,GCLKIOC0,T2 |
| B2 | HR | 33 | IO_R2N_33,T0 | M1 | HR | 33 | IO_R15P_33,T2_DQS_P |
| E1 | HR | 33 | IO_R3P_33,T0_DQS_P | L1 | HR | 33 | IO_R15N_33,T2_DQS_N |
| D1 | HR | 33 | IO_R3N_33,T0_DQS_N | M3 | HR | 33 | IO_R16P_33,T2 |
| E2 | HR | 33 | IO_R4P_33,T0 | M2 | HR | 33 | IO_R16N_33,T2 |
| D2 | HR | 33 | IO_R4N_33,T0 | K6 | HR | 33 | IO_R17P_33,T2 |
| G1 | HR | 33 | IO_R5P_33,T0 | J6 | HR | 33 | IO_R17N_33,T2 |
| F1 | HR | 33 | IO_R5N_33,T0 | L5 | HR | 33 | IO_R18P_33,T2 |
| F3 | HR | 33 | IO_R6P_33,T0 | L4 | HR | 33 | IO_R18N_33,T2 |
| E3 | HR | 33 | IO_R6N_33,T0_VREF,T0 | N4 | HR | 33 | IO_R19P_33,T3 |
| K1 | HR | 33 | IO_R7P_33,T1 | N3 | HR | 33 | IO_R19N_33,T3_VREF,T3 |
| J1 | HR | 33 | IO_R7N_33,T1 | R1 | HR | 33 | IO_R20P_33,T3 |
| H2 | HR | 33 | IO_R8P_33,T1 | P1 | HR | 33 | IO_R20N_33,T3 |
| G2 | HR | 33 | IO_R8N_33,T1 | P5 | HR | 33 | IO_R21P_33,T3_DQS_P |
| K2 | HR | 33 | IO_R9P_33,T1_DQS_P | P4 | HR | 33 | IO_R21N_33,T3_DQS_N |
| J2 | HR | 33 | IO_R9N_33,T1_DQS_N | P2 | HR | 33 | IO_R22P_33,T3 |
| J5 | HR | 33 | IO_R10P_33,T1 | N2 | HR | 33 | IO_R22N_33,T3 |
| H5 | HR | 33 | IO_R10N_33,T1 | M6 | HR | 33 | IO_R23P_33,T3 |
| H3 | HR | 33 | IO_R11P_33,GCLKIOT3,T1 | M5 | HR | 33 | IO_R23N_33,T3 |
| G3 | HR | 33 | IO_R11N_33,GCLKIOC3,T1 | P6 | HR | 33 | IO_R24P_33,T3 |
| H4 | HR | 33 | IO_R12P_33,GCLKIOT2,T1 | N5 | HR | 33 | IO_R24N_33,T3 |
| G4 | HR | 33 | IO_R12N_33,GCLKIOC2,T1 | L6 | HR | 33 | IO_R25_33 |

<!-- 原 PDF 第 133 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F6 | - | 94 | REFCLK0P_94 | L12 | HR | 0 | IO_C0_0,CCLK_0 |
| E6 | - | 94 | REFCLK0N_94 | V12 | - | 0 | TCK_0 |
| F10 | - | 94 | REFCLK1P_94 | T13 | - | 0 | TMS_0 |
| E10 | - | 94 | REFCLK1N_94 | U13 | - | 0 | TDO_0 |
| B8 | - | 94 | RX0P_94 | R13 | - | 0 | TDI_0 |
| A8 | - | 94 | RX0N_94 | U12 | - | 0 | INITN_0 |
| D11 | - | 94 | RX1P_94 | N12 | - | 0 | PROGRAMN_0 |
| C11 | - | 94 | RX1N_94 | G11 | - | 0 | DONE_0 |
| B10 | - | 94 | RX2P_94 | U11 | - | 0 | M0_0 |
| A10 | - | 94 | RX2N_94 | U10 | - | 0 | M1_0 |
| D9 | - | 94 | RX3P_94 | U9 | - | 0 | M2_0 |
| C9 | - | 94 | RX3N_94 |  |  |  |  |
| B4 | - | 94 | TX0P_94 |  |  |  |  |
| A4 | - | 94 | TX0N_94 |  |  |  |  |
| D5 | - | 94 | TX1P_94 |  |  |  |  |
| C5 | - | 94 | TX1N_94 |  |  |  |  |
| B6 | - | 94 | TX2P_94 |  |  |  |  |
| A6 | - | 94 | TX2N_94 |  |  |  |  |
| D7 | - | 94 | TX3P_94 |  |  |  |  |
| C7 | - | 94 | TX3N_94 |  |  |  |  |
| F8 | - | 94 | RESREF_94 |  |  |  |  |
| B11 | - | 94 | PHYVCCT_94 |  |  |  |  |
| B5 | - | 94 | PHYVCCT_94 |  |  |  |  |
| B7 | - | 94 | PHYVCCT_94 |  |  |  |  |
| B9 | - | 94 | PHYVCCT_94 |  |  |  |  |
| C4 | - | 94 | PHYVCCT_94 |  |  |  |  |
| C8 | - | 94 | PHYVCCT_94 |  |  |  |  |

<!-- 原 PDF 第 134 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F12 | - | 0 | VCCIO_0 | AA7 | - | 32 | VCCIO_32 |
| T12 | - | 0 | VCCIO_0 | AB4 | - | 32 | VCCIO_32 |
| AA17 | - | 11 | VCCIO11 | R5 | - | 32 | VCCIO_32 |
| AB14 | - | 11 | VCCIO11 | T2 | - | 32 | VCCIO_32 |
| V16 | - | 11 | VCCIO11 | V6 | - | 32 | VCCIO_32 |
| W13 | - | 11 | VCCIO11 | W3 | - | 32 | VCCIO_32 |
| Y10 | - | 11 | VCCIO11 | C1 | - | 33 | VCCIO_33 |
| M14 | - | 12 | VCCIO12 | F2 | - | 33 | VCCIO_33 |
| P18 | - | 12 | VCCIO12 | H6 | - | 33 | VCCIO_33 |
| R15 | - | 12 | VCCIO12 | J3 | - | 33 | VCCIO_33 |
| T22 | - | 12 | VCCIO12 | M4 | - | 33 | VCCIO_33 |
| U19 | - | 12 | VCCIO12 | N1 | - | 33 | VCCIO_33 |
| Y20 | - | 12 | VCCIO12 |  |  |  |  |
| G19 | - | 13 | VCCIO_13 |  |  |  |  |
| H16 | - | 13 | VCCIO_13 |  |  |  |  |
| J13 | - | 13 | VCCIO_13 |  |  |  |  |
| K20 | - | 13 | VCCIO_13 |  |  |  |  |
| L17 | - | 13 | VCCIO_13 |  |  |  |  |
| N21 | - | 13 | VCCIO_13 |  |  |  |  |
| A17 | - | 14 | VCCIO_14 |  |  |  |  |
| B14 | - | 14 | VCCIO_14 |  |  |  |  |
| C21 | - | 14 | VCCIO_14 |  |  |  |  |
| D18 | - | 14 | VCCIO_14 |  |  |  |  |
| E15 | - | 14 | VCCIO_14 |  |  |  |  |
| F22 | - | 14 | VCCIO_14 |  |  |  |  |

<!-- 原 PDF 第 135 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H10 | - | - | VCCINT | A11 | - | - | GND |
| H8 | - | - | VCCINT | A12 | - | - | GND |
| J7 | - | - | VCCINT | A2 | - | - | GND |
| J9 | - | - | VCCINT | A22 | - | - | GND |
| K8 | - | - | VCCINT | A3 | - | - | GND |
| L7 | - | - | VCCINT | A5 | - | - | GND |
| M8 | - | - | VCCINT | A7 | - | - | GND |
| N7 | - | - | VCCINT | A9 | - | - | GND |
| P10 | - | - | VCCINT | AA12 | - | - | GND |
| P8 | - | - | VCCINT | AA2 | - | - | GND |
| R7 | - | - | VCCINT | AA22 | - | - | GND |
| R9 | - | - | VCCINT | AB19 | - | - | GND |
| T10 | - | - | VCCINT | AB9 | - | - | GND |
| T8 | - | - | VCCINT | B12 | - | - | GND |
| H12 | - | - | VCCAUX | B19 | - | - | GND |
| R11 | - | - | VCCAUX | B3 | - | - | GND |
| K12 | - | - | VCCAUX_IO | C10 | - | - | GND |
| M12 | - | - | VCCAUX_IO | C12 | - | - | GND |
| P12 | - | - | VCCAUX_IO | C16 | - | - | GND |
| C3 | - | - | GND |  |  |  |  |
| C6 | - | - | GND |  |  |  |  |
| D12 | - | - | GND |  |  |  |  |
| D13 | - | - | GND |  |  |  |  |
| D3 | - | - | GND |  |  |  |  |
| D4 | - | - | GND |  |  |  |  |
| D8 | - | - | GND |  |  |  |  |
| E11 | - | - | GND |  |  |  |  |
| E20 | - | - | GND |  |  |  |  |
| E4 | - | - | GND |  |  |  |  |
| E5 | - | - | GND |  |  |  |  |
| E7 | - | - | GND |  |  |  |  |
| E9 | - | - | GND |  |  |  |  |
| F11 | - | - | GND |  |  |  |  |
| F17 | - | - | GND |  |  |  |  |
| F5 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 136 页 -->


| 编号 | 类型 | BANK | PH1P100SBG484引脚说明 | 编号 | 类型 | BANK | PH1P100SBG484引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G10 | - | - | GND | R10 | - | - | GND |
| G12 | - | - | GND | R20 | - | - | GND |
| G14 | - | - | GND | R8 | - | - | GND |
| G5 | - | - | GND | T11 | - | - | GND |
| G6 | - | - | GND | T17 | - | - | GND |
| G7 | - | - | GND | T7 | - | - | GND |
| G8 | - | - | GND | U14 | - | - | GND |
| G9 | - | - | GND | U4 | - | - | GND |
| H1 | - | - | GND | V1 | - | - | GND |
| H11 | - | - | GND | V11 | - | - | GND |
| H21 | - | - | GND | V21 | - | - | GND |
| H7 | - | - | GND | W18 | - | - | GND |
| H9 | - | - | GND | W8 | - | - | GND |
| J10 | - | - | GND | Y15 | - | - | GND |
| J12 | - | - | GND | Y5 | - | - | GND |
| J18 | - | - | GND | R12 | - | - | GND |
| J8 | - | - | GND | T9 | - | - | GND |
| K11 | - | - | GND | K10 | - | - | NC |
| K15 | - | - | GND | K9 | - | - | NC |
| K5 | - | - | GND | M10 | - | - | NC |
| K7 | - | - | GND | L9 | - | - | NC |
| L2 | - | - | GND | L10 | - | - | NC |
| L22 | - | - | GND | M9 | - | - | NC |
| L8 | - | - | GND | U8 | - | - | NC |
| M11 | - | - | GND | N9 | - | - | NC |
| M19 | - | - | GND | N10 | - | - | NC |
| M7 | - | - | GND | E12 | - | - | NC |
| N16 | - | - | GND | D10 | - | - | NC |
| N6 | - | - | GND | D6 | - | - | NC |
| N8 | - | - | GND | E8 | - | - | NC |
| P11 | - | - | GND | F7 | - | - | NC |
| P13 | - | - | GND | F9 | - | - | NC |
| P3 | - | - | GND | J11 | - | - | NC |
| P7 | - | - | GND | L11 | - | - | NC |
| P9 | - | - | GND | N11 | - | - | NC |

<!-- 原 PDF 第 137 页 -->

### 4.6 PH1P100GEG324引脚信息

| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R11 | HR | 12 | IO_L0_12 | P15 | HR | 12 | IO_L13P_12,GCLKIOT1,T2 |
| K17 | HR | 12 | IO_L1P_12,D0,MOSI,T0 | R15 | HR | 12 | IO_L13N_12,GCLKIOC1,T2 |
| K18 | HR | 12 | IO_L1N_12,D1,MISO,DIN,T0 | T14 | HR | 12 | IO_L14P_12,GCLKIOT0,T2 |
| L14 | HR | 12 | IO_L2P_12,D2,WPN,T0 | T15 | HR | 12 | IO_L14N_12,GCLKIOC0,T2 |
| M14 | HR | 12 | IO_L2N_12,D3,HOLDN,T0 | R16 | HR | 12 | IO_L15P_12,RDWRN,T2_DQS_P |
| L15 | HR | 12 | IO_L3P_12,HSWAPEN,T0_DQS_P | T16 | HR | 12 | IO_L15N_12,CSON,DOUT,T2_DQS_N |
| L16 | HR | 12 | IO_L3N_12,USRCLK,T0_DQS_N | V15 | HR | 12 | IO_L16P_12,CSN,T2 |
| L18 | HR | 12 | IO_L4P_12,D4,T0 | V16 | HR | 12 | IO_L16N_12,D31,T2 |
| M18 | HR | 12 | IO_L4N_12,D5,T0 | U17 | HR | 12 | IO_L17P_12,D30,T2 |
| R12 | HR | 12 | IO_L5P_12,D6,T0 | U18 | HR | 12 | IO_L17N_12,D29,T2 |
| R13 | HR | 12 | IO_L5N_12,D7,T0 | U16 | HR | 12 | IO_L18P_12,D28,T2 |
| L13 | HR | 12 | IO_L6P_12,SPICSN,BUSY,T0 | V17 | HR | 12 | IO_L18N_12,D27,T2 |
| M13 | HR | 12 | IO_L6N_12,D8,T0_VREF,T0 | T11 | HR | 12 | IO_L19P_12,D26,T3 |
| R18 | HR | 12 | IO_L7P_12,D9,T1 | U11 | HR | 12 | IO_L19N_12,D25,T3_VREF,T3 |
| T18 | HR | 12 | IO_L7N_12,D10,T1 | U12 | HR | 12 | IO_L20P_12,D24,T3 |
| N14 | HR | 12 | IO_L8P_12,D11,T1 | V12 | HR | 12 | IO_L20N_12,D23,T3 |
| P14 | HR | 12 | IO_L8N_12,D12,T1 | V10 | HR | 12 | IO_L21P_12,T3_DQS_P |
| N17 | HR | 12 | IO_L9P_12,T1_DQS_P | V11 | HR | 12 | IO_L21N_12,D22,T3_DQS_N |
| P18 | HR | 12 | IO_L9N_12,D13,T1_DQS_N | U14 | HR | 12 | IO_L22P_12,D21,T3 |
| M16 | HR | 12 | IO_L10P_12,D14,T1 | V14 | HR | 12 | IO_L22N_12,D20,T3 |
| M17 | HR | 12 | IO_L10N_12,D15,T1 | T13 | HR | 12 | IO_L23P_12,D19,T3 |
| N15 | HR | 12 | IO_L11P_12,GCLKIOT3,T1 | U13 | HR | 12 | IO_L23N_12,D18,T3 |
| N16 | HR | 12 | IO_L11N_12,GCLKIOC3,T1 | T9 | HR | 12 | IO_L24P_12,D17,T3 |
| P17 | HR | 12 | IO_L12P_12,GCLKIOT2,T1 | T10 | HR | 12 | IO_L24N_12,D16,T3 |
| R17 | HR | 12 | IO_L12N_12,GCLKIOC2,T1 | R10 | HR | 12 | IO_L25_12 |

<!-- 原 PDF 第 138 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G13 | HR | 13 | IO_L0_13 | H16 | HR | 13 | IO_L13P_13,GCLKIOT1,T2 |
| D14 | HR | 13 | IO_L1P_13,T0 | G16 | HR | 13 | IO_L13N_13,GCLKIOC1,T2 |
| C14 | HR | 13 | IO_L1N_13,T0 | F15 | HR | 13 | IO_L14P_13,GCLKIOT0,T2 |
| B13 | HR | 13 | IO_L2P_13,T0 | F16 | HR | 13 | IO_L14N_13,GCLKIOC0,T2 |
| B14 | HR | 13 | IO_L2N_13,T0 | H14 | HR | 13 | IO_L15P_13,T2_DQS_P |
| C12 | HR | 13 | IO_L3P_13,T0_DQS_P | G14 | HR | 13 | IO_L15N_13,T2_DQS_N |
| B12 | HR | 13 | IO_L3N_13,T0_DQS_N | E17 | HR | 13 | IO_L16P_13,T2 |
| B11 | HR | 13 | IO_L4P_13,T0 | D17 | HR | 13 | IO_L16N_13,T2 |
| A11 | HR | 13 | IO_L4N_13,T0 | K13 | HR | 13 | IO_L17P_13,T2 |
| F13 | HR | 13 | IO_L5P_13,T0 | J13 | HR | 13 | IO_L17N_13,T2 |
| F14 | HR | 13 | IO_L5N_13,T0 | H17 | HR | 13 | IO_L18P_13,T2 |
| D12 | HR | 13 | IO_L6P_13,T0 | G17 | HR | 13 | IO_L18N_13,T2 |
| D13 | HR | 13 | IO_L6N_13,T0_VREF,T0 | J14 | HR | 13 | IO_L19P_13,T3 |
| B16 | HR | 13 | IO_L7P_13,T1 | H15 | HR | 13 | IO_L19N_13,T3_VREF,T3 |
| B17 | HR | 13 | IO_L7N_13,T1 | C16 | HR | 13 | IO_L20P_13,T3 |
| A15 | HR | 13 | IO_L8P_13,T1 | C17 | HR | 13 | IO_L20N_13,T3 |
| A16 | HR | 13 | IO_L8N_13,T1 | E18 | HR | 13 | IO_L21P_13,T3_DQS_P |
| A13 | HR | 13 | IO_L9P_13,T1_DQS_P | D18 | HR | 13 | IO_L21N_13,T3_DQS_N |
| A14 | HR | 13 | IO_L9N_13,T1_DQS_N | G18 | HR | 13 | IO_L22P_13,T3 |
| B18 | HR | 13 | IO_L10P_13,T1 | F18 | HR | 13 | IO_L22N_13,T3 |
| A18 | HR | 13 | IO_L10N_13,T1 | J17 | HR | 13 | IO_L23P_13,T3 |
| E15 | HR | 13 | IO_L11P_13,GCLKIOT3,T1 | J18 | HR | 13 | IO_L23N_13,T3 |
| E16 | HR | 13 | IO_L11N_13,GCLKIOC3,T1 | K15 | HR | 13 | IO_L24P_13,T3 |
| D15 | HR | 13 | IO_L12P_13,GCLKIOT2,T1 | J15 | HR | 13 | IO_L24N_13,T3 |
| C15 | HR | 13 | IO_L12N_13,GCLKIOC2,T1 | K16 | HR | 13 | IO_L25_13 |

<!-- 原 PDF 第 139 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| D9 | HR | 14 | IO_L0_14,T0_VREF,T0 | C11 | HR | 14 | IO_L3P_14,T2 |
| C9 | HR | 14 | IO_L1P_14,T1 | C10 | HR | 14 | IO_L3N_14,T2 |
| B9 | HR | 14 | IO_L1N_14,T1 | A10 | HR | 14 | IO_L4P_14,T2 |
| B8 | HR | 14 | IO_L2P_14,T1 | A9 | HR | 14 | IO_L4N_14,T2 |
| A8 | HR | 14 | IO_L2N_14,T1 | D10 | HR | 14 | IO_L5_14,T3_VREF,T3 |

<!-- 原 PDF 第 140 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K6 | HR | 32 | IO_R0_32 | N5 | HR | 32 | IO_R13P_32,GCLKIOT1,T2 |
| L1 | HR | 32 | IO_R1P_32,T0 | P5 | HR | 32 | IO_R13N_32,GCLKIOC1,T2 |
| M1 | HR | 32 | IO_R1N_32,T0 | P4 | HR | 32 | IO_R14P_32,GCLKIOT0,T2 |
| K3 | HR | 32 | IO_R2P_32,T0 | P3 | HR | 32 | IO_R14N_32,GCLKIOC0,T2 |
| L3 | HR | 32 | IO_R2N_32,T0 | P2 | HR | 32 | IO_R15P_32,T2_DQS_P |
| N2 | HR | 32 | IO_R3P_32,T0_DQS_P | R2 | HR | 32 | IO_R15N_32,T2_DQS_N |
| N1 | HR | 32 | IO_R3N_32,T0_DQS_N | M4 | HR | 32 | IO_R16P_32,T2 |
| M3 | HR | 32 | IO_R4P_32,T0 | N4 | HR | 32 | IO_R16N_32,T2 |
| M2 | HR | 32 | IO_R4N_32,T0 | R1 | HR | 32 | IO_R17P_32,T2 |
| K5 | HR | 32 | IO_R5P_32,T0 | T1 | HR | 32 | IO_R17N_32,T2 |
| L4 | HR | 32 | IO_R5N_32,T0 | M6 | HR | 32 | IO_R18P_32,T2 |
| L6 | HR | 32 | IO_R6P_32,T0 | N6 | HR | 32 | IO_R18N_32,T2 |
| L5 | HR | 32 | IO_R6N_32,T0_VREF,T0 | R6 | HR | 32 | IO_R19P_32,T3 |
| U1 | HR | 32 | IO_R7P_32,T1 | R5 | HR | 32 | IO_R19N_32,T3_VREF,T3 |
| V1 | HR | 32 | IO_R7N_32,T1 | V7 | HR | 32 | IO_R20P_32,T3 |
| U4 | HR | 32 | IO_R8P_32,T1 | V6 | HR | 32 | IO_R20N_32,T3 |
| U3 | HR | 32 | IO_R8N_32,T1 | U9 | HR | 32 | IO_R21P_32,T3_DQS_P |
| U2 | HR | 32 | IO_R9P_32,T1_DQS_P | V9 | HR | 32 | IO_R21N_32,T3_DQS_N |
| V2 | HR | 32 | IO_R9N_32,T1_DQS_N | U7 | HR | 32 | IO_R22P_32,T3 |
| V5 | HR | 32 | IO_R10P_32,T1 | U6 | HR | 32 | IO_R22N_32,T3 |
| V4 | HR | 32 | IO_R10N_32,T1 | R7 | HR | 32 | IO_R23P_32,T3 |
| R3 | HR | 32 | IO_R11P_32,GCLKIOT3,T1 | T6 | HR | 32 | IO_R23N_32,T3 |
| T3 | HR | 32 | IO_R11N_32,GCLKIOC3,T1 | R8 | HR | 32 | IO_R24P_32,T3 |
| T5 | HR | 32 | IO_R12P_32,GCLKIOT2,T1 | T8 | HR | 32 | IO_R24N_32,T3 |
| T4 | HR | 32 | IO_R12N_32,GCLKIOC2,T1 | U8 | HR | 32 | IO_R25_32 |

<!-- 原 PDF 第 141 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F5 | HR | 33 | IO_R0_33 | F4 | HR | 33 | IO_R13P_33,GCLKIOT1,T2 |
| C6 | HR | 33 | IO_R1P_33,T0 | F3 | HR | 33 | IO_R13N_33,GCLKIOC1,T2 |
| C5 | HR | 33 | IO_R1N_33,T0 | E2 | HR | 33 | IO_R14P_33,GCLKIOT0,T2 |
| B7 | HR | 33 | IO_R2P_33,T0 | D2 | HR | 33 | IO_R14N_33,GCLKIOC0,T2 |
| B6 | HR | 33 | IO_R2N_33,T0 | H2 | HR | 33 | IO_R15P_33,T2_DQS_P |
| A6 | HR | 33 | IO_R3P_33,T0_DQS_P | G2 | HR | 33 | IO_R15N_33,T2_DQS_N |
| A5 | HR | 33 | IO_R3N_33,T0_DQS_N | C2 | HR | 33 | IO_R16P_33,T2 |
| D8 | HR | 33 | IO_R4P_33,T0 | C1 | HR | 33 | IO_R16N_33,T2 |
| C7 | HR | 33 | IO_R4N_33,T0 | H1 | HR | 33 | IO_R17P_33,T2 |
| E6 | HR | 33 | IO_R5P_33,T0 | G1 | HR | 33 | IO_R17N_33,T2 |
| E5 | HR | 33 | IO_R5N_33,T0 | F1 | HR | 33 | IO_R18P_33,T2 |
| E7 | HR | 33 | IO_R6P_33,T0 | E1 | HR | 33 | IO_R18N_33,T2 |
| D7 | HR | 33 | IO_R6N_33,T0_VREF,T0 | G6 | HR | 33 | IO_R19P_33,T3 |
| C4 | HR | 33 | IO_R7P_33,T1 | F6 | HR | 33 | IO_R19N_33,T3_VREF,T3 |
| B4 | HR | 33 | IO_R7N_33,T1 | G4 | HR | 33 | IO_R20P_33,T3 |
| A4 | HR | 33 | IO_R8P_33,T1 | G3 | HR | 33 | IO_R20N_33,T3 |
| A3 | HR | 33 | IO_R8N_33,T1 | J4 | HR | 33 | IO_R21P_33,T3_DQS_P |
| B1 | HR | 33 | IO_R9P_33,T1_DQS_P | H4 | HR | 33 | IO_R21N_33,T3_DQS_N |
| A1 | HR | 33 | IO_R9N_33,T1_DQS_N | J3 | HR | 33 | IO_R22P_33,T3 |
| B3 | HR | 33 | IO_R10P_33,T1 | J2 | HR | 33 | IO_R22N_33,T3 |
| B2 | HR | 33 | IO_R10N_33,T1 | K2 | HR | 33 | IO_R23P_33,T3 |
| D5 | HR | 33 | IO_R11P_33,GCLKIOT3,T1 | K1 | HR | 33 | IO_R23N_33,T3 |
| D4 | HR | 33 | IO_R11N_33,GCLKIOC3,T1 | H6 | HR | 33 | IO_R24P_33,T3 |
| E3 | HR | 33 | IO_R12P_33,GCLKIOT2,T1 | H5 | HR | 33 | IO_R24N_33,T3 |
| D3 | HR | 33 | IO_R12N_33,GCLKIOC2,T1 | J5 | HR | 33 | IO_R25_33 |

<!-- 原 PDF 第 142 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E9 | - | 0 | IO_C0_0,CCLK_0 | R9 | - | 0 | VCCIO_0 |
| E10 | - | 0 | TCK_0 | L17 | - | 12 | VCCIO_12 |
| E11 | - | 0 | TDI_0 | N13 | - | 12 | VCCIO_12 |
| E13 | - | 0 | TDO_0 | P16 | - | 12 | VCCIO_12 |
| E12 | - | 0 | TMS_0 | U15 | - | 12 | VCCIO_12 |
| P7 | - | 0 | INITN_0 | V18 | - | 12 | VCCIO_12 |
| P9 | - | 0 | PROGRAMN_0 | T12 | - | 12 | VCCIO_12 |
| P10 | - | 0 | DONE_0 | D16 | - | 13 | VCCIO_13 |
| P12 | - | 0 | M0_0 | G15 | - | 13 | VCCIO_13 |
| P13 | - | 0 | M1_0 | H18 | - | 13 | VCCIO_13 |
| P11 | - | 0 | M2_0 | K14 | - | 13 | VCCIO_13 |
| A17 | - | 13 | VCCIO_13 |  |  |  |  |
| C13 | - | 13 | VCCIO_13 |  |  |  |  |
| B10 | - | 14 | VCCIO_14 |  |  |  |  |
| K4 | - | 32 | VCCIO_32 |  |  |  |  |
| N3 | - | 32 | VCCIO_32 |  |  |  |  |
| P6 | - | 32 | VCCIO_32 |  |  |  |  |
| T2 | - | 32 | VCCIO_32 |  |  |  |  |
| U5 | - | 32 | VCCIO_32 |  |  |  |  |
| V8 | - | 32 | VCCIO_32 |  |  |  |  |
| A7 | - | 33 | VCCIO_33 |  |  |  |  |
| C3 | - | 33 | VCCIO_33 |  |  |  |  |
| D6 | - | 33 | VCCIO_33 |  |  |  |  |
| F2 | - | 33 | VCCIO_33 |  |  |  |  |
| G5 | - | 33 | VCCIO_33 |  |  |  |  |
| J1 | - | 33 | VCCIO_33 |  |  |  |  |

<!-- 原 PDF 第 143 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| L7 | - | - | VCCINT | R14 | - | - | GND |
| N7 | - | - | VCCINT | T17 | - | - | GND |
| G7 | - | - | VCCINT | U10 | - | - | GND |
| J7 | - | - | VCCINT | V13 | - | - | GND |
| F8 | - | - | VCCINT | A12 | - | - | GND |
| G9 | - | - | VCCINT | A2 | - | - | GND |
| H8 | - | - | VCCINT | B15 | - | - | GND |
| J11 | - | - | VCCINT | B5 | - | - | GND |
| K8 | - | - | VCCINT | C18 | - | - | GND |
| L11 | - | - | VCCINT | C8 | - | - | GND |
| M10 | - | - | VCCINT | D1 | - | - | GND |
| M8 | - | - | VCCINT | D11 | - | - | GND |
| N11 | - | - | VCCINT | E14 | - | - | GND |
| N9 | - | - | VCCINT | E4 | - | - | GND |
| F12 | - | - | VCCAUX | F11 | - | - | GND |
| H12 | - | - | VCCAUX | F17 | - | - | GND |
| K12 | - | - | VCCAUX | F7 | - | - | GND |
| M12 | - | - | VCCAUX | F9 | - | - | GND |
| G10 | - | - | GND |  |  |  |  |
| G12 | - | - | GND |  |  |  |  |
| G8 | - | - | GND |  |  |  |  |
| H11 | - | - | GND |  |  |  |  |
| H13 | - | - | GND |  |  |  |  |
| H3 | - | - | GND |  |  |  |  |
| H7 | - | - | GND |  |  |  |  |
| J12 | - | - | GND |  |  |  |  |
| J16 | - | - | GND |  |  |  |  |
| J6 | - | - | GND |  |  |  |  |
| J8 | - | - | GND |  |  |  |  |
| K11 | - | - | GND |  |  |  |  |
| K7 | - | - | GND |  |  |  |  |
| L12 | - | - | GND |  |  |  |  |
| L2 | - | - | GND |  |  |  |  |
| L8 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 144 页 -->


| 编号 | 类型 | BANK | PH1P100GEG324引脚说明 | 编号 | 类型 | BANK | PH1P100GEG324引脚说明 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M11 | - | - | GND | P8 | - | - | NC |
| M15 | - | - | GND | H10 | - | - | NC |
| M5 | - | - | GND | H9 | - | - | NC |
| M7 | - | - | GND | J9 | - | - | NC |
| M9 | - | - | GND | K10 | - | - | NC |
| N10 | - | - | GND | J10 | - | - | NC |
| N12 | - | - | GND | K9 | - | - | NC |
| N18 | - | - | GND | E8 | - | - | NC |
| N8 | - | - | GND | F10 | - | - | NC |
| P1 | - | - | GND | G11 | - | - | NC |
| R4 | - | - | GND | L9 | - | - | NC |
| T7 | - | - | GND | L10 | - | - | NC |
| V3 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 145 页 -->

### 4.7 PH1P35MBG484引脚信息

| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AB2 | DDR | 11 | IO_L0_11,VREF | U1 | DDR | 11 | IO_L13P_11,GCLKIOT2,T1 |
| AA4 | DDR | 11 | IO_L1P_11,T3 | U2 | DDR | 11 | IO_L13N_11,GCLKIOC2,T1 |
| AB3 | DDR | 11 | IO_L1N_11,T3 | R5 | DDR | 11 | IO_L14P_11,GCLKIOT3,T1 |
| AA5 | DDR | 11 | IO_L2P_11,T3 | R6 | DDR | 11 | IO_L14N_11,GCLKIOC3,T1 |
| AB5 | DDR | 11 | IO_L2N_11,T3 | T3 | DDR | 11 | IO_L15P_11,T1 |
| W3 | DDR | 11 | IO_L3P_11,T3 | R3 | DDR | 11 | IO_L15N_11,T1 |
| Y3 | DDR | 11 | IO_L3N_11,T3 | R2 | DDR | 11 | IO_L16P_11,T1_DQS_P |
| AA3 | DDR | 11 | IO_L4P_11,T3_DQS_P | T2 | DDR | 11 | IO_L16N_11,T1_DQS_N |
| AA2 | DDR | 11 | IO_L4N_11,T3_DQS_N | P1 | DDR | 11 | IO_L17P_11,T1 |
| W1 | DDR | 11 | IO_L5P_11,T3 | R1 | DDR | 11 | IO_L17N_11,T1 |
| W2 | DDR | 11 | IO_L5N_11,T3 | P3 | DDR | 11 | IO_L18P_11,T1 |
| Y1 | DDR | 11 | IO_L6P_11,T3 | P4 | DDR | 11 | IO_L18N_11,T1 |
| AA1 | DDR | 11 | IO_L6N_11,T3 | P5 | DDR | 11 | IO_L19P_11,T0 |
| V6 | DDR | 11 | IO_L7P_11,T2 | P6 | DDR | 11 | IO_L19N_11,T0 |
| U6 | DDR | 11 | IO_L7N_11,T2 | M6 | DDR | 11 | IO_L20P_11,T0 |
| W5 | DDR | 11 | IO_L8P_11,T2 | N6 | DDR | 11 | IO_L20N_11,T0 |
| Y5 | DDR | 11 | IO_L8N_11,T2 | N2 | DDR | 11 | IO_L21P_11,T0 |
| T4 | DDR | 11 | IO_L9P_11,T2 | N3 | DDR | 11 | IO_L21N_11,T0 |
| T5 | DDR | 11 | IO_L9N_11,T2 | M4 | DDR | 11 | IO_L22P_11,T0_DQS_P |
| U4 | DDR | 11 | IO_L10P_11,T2_DQS_P | N4 | DDR | 11 | IO_L22N_11,T0_DQS_N |
| U5 | DDR | 11 | IO_L10N_11,T2_DQS_N | M1 | DDR | 11 | IO_L23P_11,T0 |
| V2 | DDR | 11 | IO_L11P_11,GCLKIOT0,T2 | M2 | DDR | 11 | IO_L23N_11,T0 |
| V3 | DDR | 11 | IO_L11N_11,GCLKIOC0,T2 | M5 | DDR | 11 | IO_L24P_11,T0 |
| W4 | DDR | 11 | IO_L12P_11,GCLKIOT1,T2 | L4 | DDR | 11 | IO_L24N_11,T0 |
| V4 | DDR | 11 | IO_L12N_11,GCLKIOC1,T2 | L5 | DDR | 11 | IO_L25_11,VREF |

<!-- 原 PDF 第 146 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| K6 | DDR | 12 | IO_L0_12,VREF | E3 | DDR | 12 | IO_L13P_12,GCLKIOT2,T1 |
| K2 | DDR | 12 | IO_L1P_12,T3 | F3 | DDR | 12 | IO_L13N_12,GCLKIOC2,T1 |
| K1 | DDR | 12 | IO_L1N_12,T3 | F5 | DDR | 12 | IO_L14P_12,GCLKIOT3,T1 |
| L2 | DDR | 12 | IO_L2P_12,T3 | F4 | DDR | 12 | IO_L14N_12,GCLKIOC3,T1 |
| L3 | DDR | 12 | IO_L2N_12,T3 | D5 | DDR | 12 | IO_L15P_12,T1 |
| H1 | DDR | 12 | IO_L3P_12,T3 | E5 | DDR | 12 | IO_L15N_12,T1 |
| J1 | DDR | 12 | IO_L3N_12,T3 | D4 | DDR | 12 | IO_L16P_12,T1_DQS_P |
| G2 | DDR | 12 | IO_L4P_12,T3_DQS_P | D3 | DDR | 12 | IO_L16N_12,T1_DQS_N |
| H2 | DDR | 12 | IO_L4N_12,T3_DQS_N | C4 | DDR | 12 | IO_L17P_12,T1 |
| E2 | DDR | 12 | IO_L5P_12,T3 | C3 | DDR | 12 | IO_L17N_12,T1 |
| E1 | DDR | 12 | IO_L5N_12,T3 | D6 | DDR | 12 | IO_L18P_12,T1 |
| G1 | DDR | 12 | IO_L6P_12,T3 | E6 | DDR | 12 | IO_L18N_12,T1 |
| F2 | DDR | 12 | IO_L6N_12,T3 | C6 | DDR | 12 | IO_L19P_12,T0 |
| J3 | DDR | 12 | IO_L7P_12,T2 | B6 | DDR | 12 | IO_L19N_12,T0 |
| K3 | DDR | 12 | IO_L7N_12,T2 | B2 | DDR | 12 | IO_L20P_12,T0 |
| J6 | DDR | 12 | IO_L8P_12,T2 | B1 | DDR | 12 | IO_L20N_12,T0 |
| K5 | DDR | 12 | IO_L8N_12,T2 | C1 | DDR | 12 | IO_L21P_12,T0 |
| H4 | DDR | 12 | IO_L9P_12,T2 | D1 | DDR | 12 | IO_L21N_12,T0 |
| H3 | DDR | 12 | IO_L9N_12,T2 | B4 | DDR | 12 | IO_L22P_12,T0_DQS_P |
| J5 | DDR | 12 | IO_L10P_12,T2_DQS_P | B5 | DDR | 12 | IO_L22N_12,T0_DQS_N |
| J4 | DDR | 12 | IO_L10N_12,T2_DQS_N | A4 | DDR | 12 | IO_L23P_12,T0 |
| G5 | DDR | 12 | IO_L12P_12,GCLKIOT0,T2 | A5 | DDR | 12 | IO_L23N_12,T0 |
| G4 | DDR | 12 | IO_L12N_12,GCLKIOC0,T2 | A2 | DDR | 12 | IO_L24P_12,T0 |
| H6 | DDR | 12 | IO_L12P_12,GCLKIOT1,T2 | A3 | DDR | 12 | IO_L24N_12,T0 |
| G6 | DDR | 12 | IO_L12N_12,GCLKIOC1,T2 | C2 | DDR | 12 | IO_L25_12,VREF |

<!-- 原 PDF 第 147 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- |
| U7 | HD | 21 | IO_B0_21 |
| R7 | HD | 21 | IO_BE1P_21 |
| R8 | HD | 21 | IO_BE1N_21 |
| T8 | HD | 21 | IO_BE2P_21 |
| T7 | HD | 21 | IO_BE2N_21 |
| V8 | HD | 21 | IO_BE3P_21 |
| V7 | HD | 21 | IO_BE3N_21 |
| W6 | HD | 21 | IO_BE4P_21 |
| Y6 | HD | 21 | IO_BE4N_21 |
| W8 | HD | 21 | IO_BE5P_21 |
| W9 | HD | 21 | IO_BE5N_21 |
| Y8 | HD | 21 | IO_BE6P_21 |
| Y7 | HD | 21 | IO_BE6N_21 |
| AA7 | HD | 21 | IO_BE7P_21 |
| AA8 | HD | 21 | IO_BE7N_21 |
| T9 | HD | 21 | IO_BE8P_21 |
| T10 | HD | 21 | IO_BE8N_21 |
| AB6 | HD | 21 | IO_BE9P_21 |
| AB7 | HD | 21 | IO_BE9N_21 |
| V9 | HD | 21 | IO_BE10P_21 |
| U9 | HD | 21 | IO_BE10N_21 |
| W10 | HD | 21 | IO_BE11P_21 |
| Y10 | HD | 21 | IO_BE11N_21 |
| AA9 | HD | 21 | IO_BE12P_21 |
| AA10 | HD | 21 | IO_BE12N_21 |

| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- |
| AB10 | HD | 21 | IO_BE13P_21 |
| AB9 | HD | 21 | IO_BE13N_21 |
| R10 | HD | 21 | IO_BE14P_21 |
| R11 | HD | 21 | IO_BE14N_21,D31 |
| W11 | HD | 21 | IO_BE15P_21,D30 |
| V11 | HD | 21 | IO_BE15N_21,D29 |
| AB11 | HD | 21 | IO_BE16P_21,D28 |
| AB12 | HD | 21 | IO_BE16N_21,D27 |
| U10 | HD | 21 | IO_BE17P_21,GCLKIOT0 |
| U11 | HD | 21 | IO_BE17N_21,GCLKIOT2 |

<!-- 原 PDF 第 148 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| U16 | HD | 22 | IO_B0_22,USRCLK | R12 | HD | 22 | IO_BE13P_22,D20 |
| U15 | HD | 22 | IO_BE1P_22,D0_MOSI | T12 | HD | 22 | IO_BE13N_22,D21 |
| U14 | HD | 22 | IO_BE1N_22,D1_MISO_DIN | AA14 | HD | 22 | IO_BE14P_22,D22 |
| T15 | HD | 22 | IO_BE2P_22,D2_WPN | AB14 | HD | 22 | IO_BE14N_22,D23 |
| T14 | HD | 22 | IO_BE2N_22,D3_HOLDN | W13 | HD | 22 | IO_BE15P_22,D24 |
| V17 | HD | 22 | IO_BE3P_22,D4 | Y13 | HD | 22 | IO_BE15N_22,D25 |
| V18 | HD | 22 | IO_BE3N_22,D5 | AA13 | HD | 22 | IO_BE16P_22,D26 |
| V16 | HD | 22 | IO_BE4P_22,D6 | AA12 | HD | 22 | IO_BE16N_22,HSWAPEN |
| W16 | HD | 22 | IO_BE4N_22,D7 | Y12 | HD | 22 | IO_BE17P_22,GCLKIOT1 |
| W18 | HD | 22 | IO_BE5P_22,D8 | Y11 | HD | 22 | IO_BE17N_22,GCLKIOT3 |
| W19 | HD | 22 | IO_BE5N_22,D9 |  |  |  |  |
| T13 | HD | 22 | IO_BE6P_22,D10 |  |  |  |  |
| R13 | HD | 22 | IO_BE6N_22,D11 |  |  |  |  |
| W15 | HD | 22 | IO_BE7P_22,D12 |  |  |  |  |
| W14 | HD | 22 | IO_BE7N_22,D13 |  |  |  |  |
| V14 | HD | 22 | IO_BE8P_22,D14 |  |  |  |  |
| V13 | HD | 22 | IO_BE8N_22,D15 |  |  |  |  |
| Y17 | HD | 22 | IO_BE9P_22,CSN |  |  |  |  |
| Y16 | HD | 22 | IO_BE9N_22,RDWRN |  |  |  |  |
| Y15 | HD | 22 | IO_BE10P_22,SPICSN_BUSY |  |  |  |  |
| AA16 | HD | 22 | IO_BE10N_22,CSON |  |  |  |  |
| AA15 | HD | 22 | IO_BE11P_22,D16 |  |  |  |  |
| AB15 | HD | 22 | IO_BE11N_22,D17 |  |  |  |  |
| U12 | HD | 22 | IO_BE12P_22,D18 |  |  |  |  |
| V12 | HD | 22 | IO_BE12N_22,D19 |  |  |  |  |

<!-- 原 PDF 第 149 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N22 | HR | 32 | IO_R0_32 | E22 | HR | 32 | IO_R13P_32,GCLKIOT2,T1 |
| N19 | HR | 32 | IO_R1P_32,T3 | F22 | HR | 32 | IO_R13N_32,GCLKIOC2,T1 |
| N18 | HR | 32 | IO_R1N_32,T3 | G21 | HR | 32 | IO_R14P_32,GCLKIOT3,T1 |
| P20 | HR | 32 | IO_R2P_32,T3 | G22 | HR | 32 | IO_R14N_32,GCLKIOC3,T1 |
| R20 | HR | 32 | IO_R2N_32,T3 | F19 | HR | 32 | IO_R15P_32,T1 |
| M20 | HR | 32 | IO_R3P_32,T3 | G19 | HR | 32 | IO_R15N_32,T1 |
| M19 | HR | 32 | IO_R3N_32,T3 | F20 | HR | 32 | IO_R16P_32,T1_DQS_P |
| N21 | HR | 32 | IO_R4P_32,T3_DQS_P | G20 | HR | 32 | IO_R16N_32,T1_DQS_N |
| P21 | HR | 32 | IO_R4N_32,T3_DQS_N | E20 | HR | 32 | IO_R17P_32,T1 |
| M22 | HR | 32 | IO_R5P_32,T3 | E21 | HR | 32 | IO_R17N_32,T1 |
| M21 | HR | 32 | IO_R5N_32,T3 | H18 | HR | 32 | IO_R18P_32,T1 |
| L18 | HR | 32 | IO_R6P_32,T3 | H19 | HR | 32 | IO_R18N_32,T1 |
| L19 | HR | 32 | IO_R6N_32,T3_VREF | D21 | HR | 32 | IO_R19P_32,T0 |
| K20 | HR | 32 | IO_R7P_32,T2 | D20 | HR | 32 | IO_R19N_32,T0_VREF |
| L20 | HR | 32 | IO_R7N_32,T2 | C19 | HR | 32 | IO_R20P_32,T0 |
| K22 | HR | 32 | IO_R8P_32,T2 | D19 | HR | 32 | IO_R20N_32,T0 |
| L22 | HR | 32 | IO_R8N_32,T2 | C21 | HR | 32 | IO_R21P_32,T0 |
| H21 | HR | 32 | IO_R9P_32,T2 | C22 | HR | 32 | IO_R21N_32,T0 |
| H22 | HR | 32 | IO_R9N_32,T2 | B21 | HR | 32 | IO_R22P_32,T0_DQS_P |
| J21 | HR | 32 | IO_R10P_32,T2_DQS_P | B22 | HR | 32 | IO_R22N_32,T0_DQS_N |
| K21 | HR | 32 | IO_R10N_32,T2_DQS_N | B20 | HR | 32 | IO_R23P_32,T0 |
| J19 | HR | 32 | IO_R11P_32,GCLKIOT0,T2 | A20 | HR | 32 | IO_R23N_32,T0 |
| J20 | HR | 32 | IO_R11N_32,GCLKIOC0,T2 | B19 | HR | 32 | IO_R24P_32,T0 |
| J18 | HR | 32 | IO_R12P_32,GCLKIOT1,T2 | A19 | HR | 32 | IO_R24N_32,T0 |
| K18 | HR | 32 | IO_R12N_32,GCLKIOC1,T2 | A21 | HR | 32 | IO_R25_32 |

<!-- 原 PDF 第 150 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E7 | HD | 41 | IO_T0_41 | G10 | HD | 41 | IO_TE13P_41 |
| F8 | HD | 41 | IO_TE1P_41 | G11 | HD | 41 | IO_TE13N_41 |
| E8 | HD | 41 | IO_TE1N_41 | B11 | HD | 41 | IO_TE14P_41 |
| H7 | HD | 41 | IO_TE2P_41 | C11 | HD | 41 | IO_TE14N_41 |
| H8 | HD | 41 | IO_TE2N_41 | D11 | HD | 41 | IO_TE15P_41 |
| H9 | HD | 41 | IO_TE3P_41 | E11 | HD | 41 | IO_TE15N_41 |
| G9 | HD | 41 | IO_TE3N_41 | A12 | HD | 41 | IO_TE16P_41 |
| G7 | HD | 41 | IO_TE4P_41 | B12 | HD | 41 | IO_TE16N_41 |
| F7 | HD | 41 | IO_TE4N_41 | A13 | HD | 41 | IO_TE17P_41,GCLKIOT0 |
| D8 | HD | 41 | IO_TE5P_41 | A14 | HD | 41 | IO_TE17N_41,GCLKIOT2 |
| C8 | HD | 41 | IO_TE5N_41 |  |  |  |  |
| B7 | HD | 41 | IO_TE6P_41 |  |  |  |  |
| C7 | HD | 41 | IO_TE6N_41 |  |  |  |  |
| A7 | HD | 41 | IO_TE7P_41 |  |  |  |  |
| A8 | HD | 41 | IO_TE7N_41 |  |  |  |  |
| F9 | HD | 41 | IO_TE8P_41 |  |  |  |  |
| F10 | HD | 41 | IO_TE8N_41 |  |  |  |  |
| D9 | HD | 41 | IO_TE9P_41 |  |  |  |  |
| C9 | HD | 41 | IO_TE9N_41 |  |  |  |  |
| B9 | HD | 41 | IO_TE10P_41 |  |  |  |  |
| B10 | HD | 41 | IO_TE10N_41 |  |  |  |  |
| A9 | HD | 41 | IO_TE11P_41 |  |  |  |  |
| A10 | HD | 41 | IO_TE11N_41 |  |  |  |  |
| E10 | HD | 41 | IO_TE12P_41 |  |  |  |  |
| D10 | HD | 41 | IO_TE12N_41 |  |  |  |  |

<!-- 原 PDF 第 151 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G12 | HD | 42 | IO_T0_42 | B15 | HD | 42 | IO_TE13P_42 |
| G16 | HD | 42 | IO_TE1P_42 | A15 | HD | 42 | IO_TE13N_42 |
| G17 | HD | 42 | IO_TE1N_42 | E13 | HD | 42 | IO_TE14P_42 |
| F17 | HD | 42 | IO_TE2P_42 | D13 | HD | 42 | IO_TE14N_42 |
| F18 | HD | 42 | IO_TE2N_42 | C14 | HD | 42 | IO_TE15P_42 |
| G15 | HD | 42 | IO_TE3P_42 | B14 | HD | 42 | IO_TE15N_42 |
| G14 | HD | 42 | IO_TE3N_42 | F12 | HD | 42 | IO_TE16P_42 |
| F15 | HD | 42 | IO_TE4P_42 | E12 | HD | 42 | IO_TE16N_42 |
| E15 | HD | 42 | IO_TE4N_42 | C13 | HD | 42 | IO_TE17P_42,GCLKIOT1 |
| E16 | HD | 42 | IO_TE5P_42 | C12 | HD | 42 | IO_TE17N_42,GCLKIOT3 |
| E17 | HD | 42 | IO_TE5N_42 |  |  |  |  |
| F14 | HD | 42 | IO_TE6P_42 |  |  |  |  |
| F13 | HD | 42 | IO_TE6N_42 |  |  |  |  |
| E18 | HD | 42 | IO_TE7P_42 |  |  |  |  |
| D18 | HD | 42 | IO_TE7N_42 |  |  |  |  |
| C18 | HD | 42 | IO_TE8P_42 |  |  |  |  |
| C17 | HD | 42 | IO_TE8N_42 |  |  |  |  |
| D16 | HD | 42 | IO_TE9P_42 |  |  |  |  |
| C16 | HD | 42 | IO_TE9N_42 |  |  |  |  |
| D15 | HD | 42 | IO_TE10P_42 |  |  |  |  |
| D14 | HD | 42 | IO_TE10N_42 |  |  |  |  |
| B17 | HD | 42 | IO_TE11P_42 |  |  |  |  |
| B16 | HD | 42 | IO_TE11N_42 |  |  |  |  |
| A18 | HD | 42 | IO_TE12P_42 |  |  |  |  |
| A17 | HD | 42 | IO_TE12N_42 |  |  |  |  |

<!-- 原 PDF 第 152 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| T18 | HD | 0 | CCLK_0 | AA20 | MIPI | - | IO_0N_DPHY0,CKN_0 |
| P18 | - | 0 | DONE_0 | AB19 | MIPI | - | IO_0P_DPHY0,CKP_0 |
| U17 | - | 0 | INITN_0 | AB17 | MIPI | - | IO_1P_DPHY0,DP0_0 |
| N17 | - | 0 | PROGRAMN_0 | AA18 | MIPI | - | IO_1N_DPHY0,DN0_0 |
| T17 | - | 0 | M0_0 | AB18 | MIPI | - | IO_2P_DPHY0,DP1_0 |
| R16 | - | 0 | M1_0 | AA19 | MIPI | - | IO_2N_DPHY0,DN1_0 |
| P19 | - | 0 | M2_0 | AB20 | MIPI | - | IO_3P_DPHY0,DP2_0 |
| T19 | - | 0 | TCK_0 | AA21 | MIPI | - | IO_3N_DPHY0,DN2_0 |
| U19 | - | 0 | TDI_0 | AB21 | MIPI | - | IO_4P_DPHY0,DP3_0 |
| V19 | - | 0 | TDO_0 | AA22 | MIPI | - | IO_4N_DPHY0,DN3_0 |
| R18 | - | 0 | TMS_0 | V22 | MIPI | - | IO_5P_DPHY1,CKP_1 |
| R17 | - | 0 | TRSTN_0 | V21 | MIPI | - | IO_5N_DPHY1,CKN_1 |
| Y22 | MIPI | - | IO_6P_DPHY1,DP0_1 |  |  |  |  |
| Y21 | MIPI | - | IO_6N_DPHY1,DN0_1 |  |  |  |  |
| W22 | MIPI | - | IO_7P_DPHY1,DP1_1 |  |  |  |  |
| W21 | MIPI | - | IO_7N_DPHY1,DN1_1 |  |  |  |  |
| U22 | MIPI | - | IO_8P_DPHY1,DP2_1 |  |  |  |  |
| U21 | MIPI | - | IO_8N_DPHY1,DN2_1 |  |  |  |  |
| T22 | MIPI | - | IO_9P_DPHY1,DP3_1 |  |  |  |  |
| T21 | MIPI | - | IO_9N_DPHY1,DN3_1 |  |  |  |  |

<!-- 原 PDF 第 153 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | - | - | GND | H20 | - | - | GND |
| A11 | - | - | GND | J11 | - | - | GND |
| A22 | - | - | GND | J13 | - | - | GND |
| A6 | - | - | GND | J17 | - | - | GND |
| AA11 | - | - | GND | J7 | - | - | GND |
| AA6 | - | - | GND | J9 | - | - | GND |
| AB1 | - | - | GND | K10 | - | - | GND |
| AB16 | - | - | GND | K12 | - | - | GND |
| AB22 | - | - | GND | K14 | - | - | GND |
| AB4 | - | - | GND | K4 | - | - | GND |
| AB8 | - | - | GND | K8 | - | - | GND |
| B18 | - | - | GND | L1 | - | - | GND |
| B8 | - | - | GND | L11 | - | - | GND |
| C15 | - | - | GND | L13 | - | - | GND |
| C5 | - | - | GND | L21 | - | - | GND |
| D12 | - | - | GND | L9 | - | - | GND |
| D2 | - | - | GND | M10 | - | - | GND |
| D22 | - | - | GND | M12 | - | - | GND |
| E19 | - | - | GND | M14 | - | - | GND |
| E9 | - | - | GND | M18 | - | - | GND |
| F16 | - | - | GND | M8 | - | - | GND |
| F6 | - | - | GND | N11 | - | - | GND |
| G13 | - | - | GND | N13 | - | - | GND |
| G3 | - | - | GND | N15 | - | - | GND |
| H10 | - | - | GND | N5 | - | - | GND |

<!-- 原 PDF 第 154 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| N9 | - | - | GND | K11 | - | - | VCCINT |
| P10 | - | - | GND | K13 | - | - | VCCINT |
| P12 | - | - | GND | K9 | - | - | VCCINT |
| P14 | - | - | GND | L10 | - | - | VCCINT |
| P2 | - | - | GND | L12 | - | - | VCCINT |
| P22 | - | - | GND | L8 | - | - | VCCINT |
| P8 | - | - | GND | M11 | - | - | VCCINT |
| R19 | - | - | GND | M13 | - | - | VCCINT |
| R21 | - | - | GND | M9 | - | - | VCCINT |
| R9 | - | - | GND | N10 | - | - | VCCINT |
| T16 | - | - | GND | N12 | - | - | VCCINT |
| T20 | - | - | GND | N8 | - | - | VCCINT |
| T6 | - | - | GND | P11 | - | - | VCCINT |
| U13 | - | - | GND | P9 | - | - | VCCINT |
| U3 | - | - | GND | J10 | - | - | VCCAUX |
| V1 | - | - | GND | J12 | - | - | VCCAUX |
| V10 | - | - | GND | J14 | - | - | VCCAUX |
| V20 | - | - | GND | J8 | - | - | VCCAUX |
| W17 | - | - | GND | L14 | - | - | VCCAUX |
| W7 | - | - | GND | N14 | - | - | VCCAUX |
| Y14 | - | - | GND | P13 | - | - | VCCAUX |
| Y18 | - | - | GND | R14 | - | - | VCCAUX |
| Y20 | - | - | GND |  |  |  |  |
| Y4 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 155 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| H11 | - | - | NC | P17 | - | 0 | VCCIO_0 |
| H12 | - | - | NC | U18 | - | 0 | VCCIO_0 |
| H13 | - | - | NC | M3 | - | 11 | VCCIO11 |
| H14 | - | - | NC | N1 | - | 11 | VCCIO11 |
| H15 | - | - | NC | R4 | - | 11 | VCCIO11 |
| H16 | - | - | NC | T1 | - | 11 | VCCIO11 |
| H17 | - | - | NC | V5 | - | 11 | VCCIO11 |
| J15 | - | - | NC | Y2 | - | 11 | VCCIO11 |
| J16 | - | - | NC | B3 | - | 12 | VCCIO12 |
| K15 | - | - | NC | E4 | - | 12 | VCCIO12 |
| K16 | - | - | NC | F1 | - | 12 | VCCIO12 |
| K17 | - | - | NC | H5 | - | 12 | VCCIO12 |
| K7 | - | - | NC | J2 | - | 12 | VCCIO12 |
| L15 | - | - | NC | L6 | - | 12 | VCCIO12 |
| L16 | - | - | NC | T11 | - | 21 | VCCIO_21 |
| L17 | - | - | NC | U8 | - | 21 | VCCIO_21 |
| L7 | - | - | NC | Y9 | - | 21 | VCCIO_21 |
| M15 | - | - | NC | AB13 | - | 22 | VCCIO_22 |
| M16 | - | - | NC | V15 | - | 22 | VCCIO_22 |
| M17 | - | - | NC | W12 | - | 22 | VCCIO_22 |
| M7 | - | - | NC | C20 | - | 32 | VCCIO_32 |
| N16 | - | - | NC | F21 | - | 32 | VCCIO_32 |
| N7 | - | - | NC | G18 | - | 32 | VCCIO_32 |
| P15 | - | - | NC | J22 | - | 32 | VCCIO_32 |
| P16 | - | - | NC | K19 | - | 32 | VCCIO_32 |
| P7 | - | - | NC | N20 | - | 32 | VCCIO_32 |
| R15 | - | - | NC |  |  |  |  |

<!-- 原 PDF 第 156 页 -->


| 编号 | 类型 | BANK | PH1P35MBG484引脚名称 | 编号 | 类型 | BANK | PH1P35MBG484引脚名称 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C10 | - | 41 | VCCIO41 |  |  |  |  |
| D7 | - | 41 | VCCIO41 |  |  |  |  |
| F11 | - | 41 | VCCIO41 |  |  |  |  |
| G8 | - | 41 | VCCIO41 |  |  |  |  |
| A16 | - | 42 | VCCIO42 |  |  |  |  |
| B13 | - | 42 | VCCIO42 |  |  |  |  |
| D17 | - | 42 | VCCIO42 |  |  |  |  |
| E14 | - | 42 | VCCIO42 |  |  |  |  |
| AA17 | - | - | VCCDPHY |  |  |  |  |
| R22 | - | - | VCCDPHY |  |  |  |  |
| U20 | - | - | VCCDPHY |  |  |  |  |
| W20 | - | - | VCCDPHY |  |  |  |  |
| Y19 | - | - | VCCDPHY |  |  |  |  |

<!-- 原 PDF 第 157 页 -->

### 4.8 PH1P35MDG324/PH1P35MHG324引脚信息

| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| M6 | DDR | 11 | IO_L0P_11 | H2 | HD | 21 | IO_B0_21 |
| L6 | DDR | 11 | IO_L0N_11 | R3 | HD | 21 | IO_BE1P_21 |
| K5 | DDR | 11 | IO_L1P_11,GCLKIOT2 | P3 | HD | 21 | IO_BE1N_21 |
| L5 | DDR | 11 | IO_L1N_11,GCLKIOC2 | H1 | HD | 21 | IO_BE2P_21 |
| J1 | HD | 21 | IO_BE2N_21 |  |  |  |  |
| K1 | HD | 21 | IO_BE3P_21 |  |  |  |  |
| K2 | HD | 21 | IO_BE3N_21 |  |  |  |  |
| L2 | HD | 21 | IO_BE4P_21 |  |  |  |  |
| L3 | HD | 21 | IO_BE4N_21 |  |  |  |  |
| J3 | HD | 21 | IO_BE5P_21 |  |  |  |  |
| K3 | HD | 21 | IO_BE5N_21 |  |  |  |  |
| M4 | HD | 21 | IO_BE6P_21 |  |  |  |  |
| N4 | HD | 21 | IO_BE6N_21 |  |  |  |  |
| M1 | HD | 21 | IO_BE7P_21 |  |  |  |  |
| M2 | HD | 21 | IO_BE7N_21 |  |  |  |  |
| N1 | HD | 21 | IO_BE8P_21 |  |  |  |  |
| P1 | HD | 21 | IO_BE8N_21 |  |  |  |  |
| R1 | HD | 21 | IO_BE9P_21 |  |  |  |  |
| R2 | HD | 21 | IO_BE9N_21 |  |  |  |  |
| N3 | HD | 21 | IO_BE10P_21 |  |  |  |  |
| N2 | HD | 21 | IO_BE10N_21 |  |  |  |  |
| P4 | HD | 21 | IO_BE11P_21 |  |  |  |  |
| P5 | HD | 21 | IO_BE11N_21 |  |  |  |  |
| T4 | HD | 21 | IO_BE12P_21 |  |  |  |  |
| T3 | HD | 21 | IO_BE12N_21 |  |  |  |  |

<!-- 原 PDF 第 158 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| R5 | HD | 21 | IO_BE13P_21 | T12 | HD | 22 | IO_B0_22,USRCLK |
| P6 | HD | 21 | IO_BE13N_21 | V12 | HD | 22 | IO_BE1P_22,D0_MOSI |
| M5 | HD | 21 | IO_BE14P_21 | U12 | HD | 22 | IO_BE1N_22,D1_MISO_DIN |
| L4 | HD | 21 | IO_BE14N_21,D31 | V11 | HD | 22 | IO_BE2P_22,D2_WPN |
| T2 | HD | 21 | IO_BE15P_21,D30 | U11 | HD | 22 | IO_BE2N_22,D3_HOLDN |
| U2 | HD | 21 | IO_BE15N_21,D29 | V8 | HD | 22 | IO_BE3P_22,D4 |
| U1 | HD | 21 | IO_BE16P_21,D28 | V9 | HD | 22 | IO_BE3N_22,D5 |
| V1 | HD | 21 | IO_BE16N_21,D27 | U10 | HD | 22 | IO_BE4P_22,D6 |
| N6 | HD | 21 | IO_BE17P_21,GCLKIOT0 | T10 | HD | 22 | IO_BE4N_22,D7 |
| N7 | HD | 21 | IO_BE17N_21,GCLKIOT2 | R12 | HD | 22 | IO_BE5P_22,D8 |
| P11 | HD | 22 | IO_BE5N_22,D9 |  |  |  |  |
| R11 | HD | 22 | IO_BE6P_22,D10 |  |  |  |  |
| R10 | HD | 22 | IO_BE6N_22,D11 |  |  |  |  |
| U9 | HD | 22 | IO_BE7P_22,D12 |  |  |  |  |
| T9 | HD | 22 | IO_BE7N_22,D13 |  |  |  |  |
| T8 | HD | 22 | IO_BE8P_22,D14 |  |  |  |  |
| T7 | HD | 22 | IO_BE8N_22,D15 |  |  |  |  |
| N9 | HD | 22 | IO_BE9P_22,CSN |  |  |  |  |
| N8 | HD | 22 | IO_BE9N_22,RDWRN |  |  |  |  |
| R8 | HD | 22 | IO_BE10P_22,SPICSN_BUSY |  |  |  |  |
| P8 | HD | 22 | IO_BE10N_22,CSON |  |  |  |  |
| V7 | HD | 22 | IO_BE11P_22,D16 |  |  |  |  |
| U7 | HD | 22 | IO_BE11N_22,D17 |  |  |  |  |
| P10 | HD | 22 | IO_BE12P_22,D18 |  |  |  |  |
| P9 | HD | 22 | IO_BE12N_22,D19 |  |  |  |  |

<!-- 原 PDF 第 159 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| V6 | HD | 22 | IO_BE13P_22,D20 | J14 | HR | 32 | IO_R0_32 |
| U6 | HD | 22 | IO_BE13N_22,D21 | L15 | HR | 32 | IO_R1P_32,T3 |
| R6 | HD | 22 | IO_BE14P_22,D22 | L16 | HR | 32 | IO_R1N_32,T3 |
| R7 | HD | 22 | IO_BE14N_22,D23 | J13 | HR | 32 | IO_R2P_32,T3 |
| U5 | HD | 22 | IO_BE15P_22,D24 | K13 | HR | 32 | IO_R2N_32,T3 |
| T5 | HD | 22 | IO_BE15N_22,D25 | J18 | HR | 32 | IO_R3P_32,T3 |
| V4 | HD | 22 | IO_BE16P_22,D26 | K17 | HR | 32 | IO_R3N_32,T3 |
| U4 | HD | 22 | IO_BE16N_22,HSWAPEN | K16 | HR | 32 | IO_R4P_32,T3_DQS_P |
| V3 | HD | 22 | IO_BE17P_22,GCLKIOT1 | K15 | HR | 32 | IO_R4N_32,T3_DQS_N |
| V2 | HD | 22 | IO_BE17N_22,GCLKIOT3 | H17 | HR | 32 | IO_R5P_32,T3 |
| H18 | HR | 32 | IO_R5N_32,T3 |  |  |  |  |
| J15 | HR | 32 | IO_R6P_32,T3 |  |  |  |  |
| J16 | HR | 32 | IO_R6N_32,T3_VREF |  |  |  |  |
| F18 | HR | 32 | IO_R7P_32,T2 |  |  |  |  |
| G17 | HR | 32 | IO_R7N_32,T2 |  |  |  |  |
| G16 | HR | 32 | IO_R8P_32,T2 |  |  |  |  |
| H16 | HR | 32 | IO_R8N_32,T2 |  |  |  |  |
| F17 | HR | 32 | IO_R9P_32,T2 |  |  |  |  |
| E18 | HR | 32 | IO_R9N_32,T2 |  |  |  |  |
| H14 | HR | 32 | IO_R10P_32,T2_DQS_P |  |  |  |  |
| H13 | HR | 32 | IO_R10N_32,T2_DQS_N |  |  |  |  |
| C17 | HR | 32 | IO_R11P_32,GCLKIOT0,T1 |  |  |  |  |
| D18 | HR | 32 | IO_R11N_32,GCLKIOC0,T2 |  |  |  |  |
| G15 | HR | 32 | IO_R12P_32,GCLKIOT1,T2 |  |  |  |  |
| G14 | HR | 32 | IO_R12N_32,GCLKIOC1,T2 |  |  |  |  |

<!-- 原 PDF 第 160 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| A17 | HR | 32 | IO_R13P_32,GCLKIOT2,T1 | C12 | HD | 42 | IO_T0_42 |
| A18 | HR | 32 | IO_R13N_32,GCLKIOC2,T1 | A12 | HD | 42 | IO_TE1P_42 |
| F14 | HR | 32 | IO_R14P_32,GCLKIOT3,T1 | B12 | HD | 42 | IO_TE1N_42 |
| F13 | HR | 32 | IO_R14N_32,GCLKIOC3,T1 | A8 | HD | 42 | IO_TE2P_42 |
| E17 | HR | 32 | IO_R15P_32,T1 | A7 | HD | 42 | IO_TE2N_42 |
| E16 | HR | 32 | IO_R15N_32,T1 | E8 | HD | 42 | IO_TE3P_42 |
| E15 | HR | 32 | IO_R16P_32,T1_DQS_P | D8 | HD | 42 | IO_TE3N_42 |
| F15 | HR | 32 | IO_R16N_32,T1_DQS_N | D9 | HD | 42 | IO_TE4P_42 |
| B17 | HR | 32 | IO_R17P_32,T1 | C9 | HD | 42 | IO_TE4N_42 |
| C18 | HR | 32 | IO_R17N_32,T1 | C11 | HD | 42 | IO_TE5P_42 |
| D15 | HR | 32 | IO_R18P_32,T1 | B11 | HD | 42 | IO_TE5N_42 |
| D14 | HR | 32 | IO_R18N_32,T1 | E7 | HD | 42 | IO_TE6P_42 |
| D16 | HR | 32 | IO_R19P_32,T0 | E6 | HD | 42 | IO_TE6N_42 |
| C16 | HR | 32 | IO_R19N_32,T0_VREF | B6 | HD | 42 | IO_TE7P_42 |
| A13 | HR | 32 | IO_R20P_32,T0 | B7 | HD | 42 | IO_TE7N_42 |
| B14 | HR | 32 | IO_R20N_32,T0 | E5 | HD | 42 | IO_TE8P_42 |
| B16 | HR | 32 | IO_R21P_32,T0 | D5 | HD | 42 | IO_TE8N_42 |
| A15 | HR | 32 | IO_R21N_32,T0 | A9 | HD | 42 | IO_TE9P_42 |
| B15 | HR | 32 | IO_R22P_32,T0_DQS_P | B9 | HD | 42 | IO_TE9N_42 |
| A14 | HR | 32 | IO_R22N_32,T0_DQS_N | C7 | HD | 42 | IO_TE10P_42 |
| E13 | HR | 32 | IO_R23P_32,T0 | C8 | HD | 42 | IO_TE10N_42 |
| D13 | HR | 32 | IO_R23N_32,T0 | A10 | HD | 42 | IO_TE11P_42 |
| C14 | HR | 32 | IO_R24P_32,T0 | B10 | HD | 42 | IO_TE11N_42 |
| C13 | HR | 32 | IO_R24N_32,T0 | A4 | HD | 42 | IO_TE12P_42 |
| E12 | HR | 32 | IO_R25_32 | B4 | HD | 42 | IO_TE12N_42 |

<!-- 原 PDF 第 161 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| E11 | HD | 42 | IO_TE13P_42 | V16 | MIPI | - | IO_0P_DPHY0,CKP_0 |
| D11 | HD | 42 | IO_TE13N_42 | U16 | MIPI | - | IO_0N_DPHY0,CKN_0 |
| D10 | HD | 42 | IO_TE14P_42 | V14 | MIPI | - | IO_1P_DPHY0,DP0_0 |
| E10 | HD | 42 | IO_TE14N_42 | U14 | MIPI | - | IO_1N_DPHY0,DN0_0 |
| C6 | HD | 42 | IO_TE15P_42 | V15 | MIPI | - | IO_2P_DPHY0,DP1_0 |
| D6 | HD | 42 | IO_TE15N_42 | U15 | MIPI | - | IO_2N_DPHY0,DN1_0 |
| A5 | HD | 42 | IO_TE16P_42 | V17 | MIPI | - | IO_3P_DPHY0,DP2_0 |
| B5 | HD | 42 | IO_TE16N_42 | U17 | MIPI | - | IO_3N_DPHY0,DN2_0 |
| C4 | HD | 42 | IO_TE17P_42,GCLKIOT1 | U18 | MIPI | - | IO_4P_DPHY0,DP3_0 |
| D4 | HD | 42 | IO_TE17N_42,GCLKIOT3 | V18 | MIPI | - | IO_4N_DPHY0,DN3_0 |
| N18 | MIPI | - | IO_5P_DPHY1,CKP_1 |  |  |  |  |
| P17 | MIPI | - | IO_5N_DPHY1,CKN_1 |  |  |  |  |
| R18 | MIPI | - | IO_6P_DPHY1,DP0_1 |  |  |  |  |
| T17 | MIPI | - | IO_6N_DPHY1,DN0_1 |  |  |  |  |
| P18 | MIPI | - | IO_7P_DPHY1,DP1_1 |  |  |  |  |
| R17 | MIPI | - | IO_7N_DPHY1,DN1_1 |  |  |  |  |
| M18 | MIPI | - | IO_8P_DPHY1,DP2_1 |  |  |  |  |
| N17 | MIPI | - | IO_8N_DPHY1,DN2_1 |  |  |  |  |
| L18 | MIPI | - | IO_9P_DPHY1,DP3_1 |  |  |  |  |
| M17 | MIPI | - | IO_9N_DPHY1,DN3_1 |  |  |  |  |

<!-- 原 PDF 第 162 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| R15 | HD | 0 | CCLK_0 | M13 | - | 0 | VCCIO_0 |
| P14 | - | 0 | DONE_0 | R14 | - | 0 | VCCIO_0 |
| M15 | - | 0 | INITN_0 | E4 | - | 11 | VCCIO_11 |
| N15 | - | 0 | PROGRAMN_0 | F1 | - | 11 | VCCIO_11 |
| N13 | - | 0 | M0_0 | F3 | - | 11 | VCCIO_11 |
| M14 | - | 0 | M1_0 | F5 | - | 11 | VCCIO_11 |
| N14 | - | 0 | M2_0 | G2 | - | 11 | VCCIO_11 |
| P15 | - | 0 | TCK_0 | G4 | - | 11 | VCCIO_11 |
| R13 | - | 0 | TDI_0 | G6 | - | 12 | VCCIO_12 |
| T13 | - | 0 | TDO_0 | H3 | - | 12 | VCCIO_12 |
| L14 | - | 0 | TMS_0 | H5 | - | 12 | VCCIO_12 |
| P13 | - | 0 | TRSTN_0 | J4 | - | 12 | VCCIO_12 |
| J6 | - | 12 | VCCIO_12 |  |  |  |  |
| M3 | - | 21 | VCCIO_21 |  |  |  |  |
| P7 | - | 21 | VCCIO_21 |  |  |  |  |
| R4 | - | 21 | VCCIO_21 |  |  |  |  |
| N10 | - | 22 | VCCIO_22 |  |  |  |  |
| T11 | - | 22 | VCCIO_22 |  |  |  |  |
| U8 | - | 22 | VCCIO_22 |  |  |  |  |
| V5 | - | 22 | VCCIO_22 |  |  |  |  |
| A16 | - | 32 | VCCIO_32 |  |  |  |  |
| B13 | - | 32 | VCCIO_32 |  |  |  |  |
| D17 | - | 32 | VCCIO_32 |  |  |  |  |
| E14 | - | 32 | VCCIO_32 |  |  |  |  |
| G18 | - | 32 | VCCIO_32 |  |  |  |  |
| H15 | - | 32 | VCCIO_32 |  |  |  |  |
| A6 | - | 42 | VCCIO_42 |  |  |  |  |
| C10 | - | 42 | VCCIO_42 |  |  |  |  |
| D7 | - | 42 | VCCIO_42 |  |  |  |  |

<!-- 原 PDF 第 163 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| A1 | - | - | GND | G9 | - | - | GND |
| A11 | - | - | GND | H10 | - | - | GND |
| B18 | - | - | GND | H12 | - | - | GND |
| B2 | - | - | GND | H4 | - | - | GND |
| B8 | - | - | GND | H6 | - | - | GND |
| C1 | - | - | GND | H8 | - | - | GND |
| C15 | - | - | GND | J11 | - | - | GND |
| C5 | - | - | GND | J17 | - | - | GND |
| D12 | - | - | GND | J2 | - | - | GND |
| D2 | - | - | GND | J5 | - | - | GND |
| E1 | - | - | GND | J7 | - | - | GND |
| E9 | - | - | GND | J9 | - | - | GND |
| F10 | - | - | GND | K10 | - | - | GND |
| F12 | - | - | GND | K12 | - | - | GND |
| F16 | - | - | GND | K14 | - | - | GND |
| F2 | - | - | GND | K18 | - | - | GND |
| F4 | - | - | GND | K4 | - | - | GND |
| F6 | - | - | GND | K6 | - | - | GND |
| F8 | - | - | GND | K8 | - | - | GND |
| G1 | - | - | GND | L1 | - | - | GND |
| G11 | - | - | GND | L11 | - | - | GND |
| G13 | - | - | GND | L17 | - | - | GND |
| G3 | - | - | GND | L7 | - | - | GND |
| G5 | - | - | GND | L9 | - | - | GND |
| G7 | - | - | GND | M10 | - | - | GND |

<!-- 原 PDF 第 164 页 -->


| PH1P35MDG324/PH1P35MHG324 | PH1P35MDG324/PH1P35MHG324 |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚名称 | 引脚名称 |  |  |  |  |  |  |
| M12 | - | - | GND | G10 | - | - | VCCINT |
| M16 | - | - | GND | G8 | - | - | VCCINT |
| M8 | - | - | GND | H11 | - | - | VCCINT |
| N11 | - | - | GND | H9 | - | - | VCCINT |
| N5 | - | - | GND | J10 | - | - | VCCINT |
| P12 | - | - | GND | J12 | - | - | VCCINT |
| P16 | - | - | GND | J8 | - | - | VCCINT |
| P2 | - | - | GND | K11 | - | - | VCCINT |
| R9 | - | - | GND | K9 | - | - | VCCINT |
| T1 | - | - | GND | L10 | - | - | VCCINT |
| T14 | - | - | GND | L12 | - | - | VCCINT |
| T16 | - | - | GND | L8 | - | - | VCCINT |
| T18 | - | - | GND | M11 | - | - | VCCINT |
| T6 | - | - | GND | M9 | - | - | VCCINT |
| U13 | - | - | GND | F11 | - | - | VCCAUX |
| U3 | - | - | GND | F7 | - | - | VCCAUX |
| V10 | - | - | GND | F9 | - | - | VCCAUX |
| A3 | - | - | GND | G12 | - | - | VCCAUX |
| C3 | - | - | GND | H7 | - | - | VCCAUX |
| E3 | - | - | GND | K7 | - | - | VCCAUX |
| N12 | - | - | NC | M7 | - | - | VCCAUX |
| L13 | - | - | NC | B1 | - | - | VCCIO_DDR |
| B3 | - | - | VCCIO_DDR |  |  |  |  |
| C2 | - | - | VCCIO_DDR |  |  |  |  |
| D1 | - | - | VCCIO_DDR |  |  |  |  |
| D3 | - | - | VCCIO_DDR |  |  |  |  |
| E2 | - | - | VCCIO_DDR |  |  |  |  |
| A2 | - | - | DDR_VREF |  |  |  |  |
| N16 | - | - | VCCDPHY |  |  |  |  |
| R16 | - | - | VCCDPHY |  |  |  |  |
| T15 | - | - | VCCDPHY |  |  |  |  |
| V13 | - | - | VCCDPHY |  |  |  |  |

<!-- 原 PDF 第 165 页 -->

### 4.9 PH1P35MEG324/PH1P35MEG324A引脚信息

| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| J6 | DDR | 12 | IO_L0_12,VREF | H2 | DDR | 12 | IO_L13P_12,GCLKIOT2,T1 |
| L3 | DDR | 12 | IO_L1P_12,T3 | H1 | DDR | 12 | IO_L13N_12,GCLKIOC2,T1 |
| L4 | DDR | 12 | IO_L1N_12,T3 | G2 | DDR | 12 | IO_L14P_12,GCLKIOT3,T1 |
| M4 | DDR | 12 | IO_L2P_12,T3 | G1 | DDR | 12 | IO_L14N_12,GCLKIOC3,T1 |
| M5 | DDR | 12 | IO_L2N_12,T3 | F2 | DDR | 12 | IO_L15P_12,T1 |
| M6 | DDR | 12 | IO_L3P_12,T3 | E1 | DDR | 12 | IO_L15N_12,T1 |
| L5 | DDR | 12 | IO_L3N_12,T3 | G4 | DDR | 12 | IO_L16P_12,T1_DQS_P |
| K5 | DDR | 12 | IO_L4P_12,T3_DQS_P | H4 | DDR | 12 | IO_L16N_12,T1_DQS_N |
| K6 | DDR | 12 | IO_L4N_12,T3_DQS_N | F3 | DDR | 12 | IO_L17P_12,T1 |
| N3 | DDR | 12 | IO_L5P_12,T3 | E3 | DDR | 12 | IO_L17N_12,T1 |
| N4 | DDR | 12 | IO_L5N_12,T3 | D1 | DDR | 12 | IO_L18P_12,T1 |
| J5 | DDR | 12 | IO_L6P_12,T3 | E2 | DDR | 12 | IO_L18N_12,T1 |
| H6 | DDR | 12 | IO_L6N_12,T3 | G5 | DDR | 12 | IO_L19P_12,T0 |
| N1 | DDR | 12 | IO_L7P_12,T2 | F5 | DDR | 12 | IO_L19N_12,T0 |
| N2 | DDR | 12 | IO_L7N_12,T2 | E5 | DDR | 12 | IO_L20P_12,T0 |
| J3 | DDR | 12 | IO_L8P_12,T2 | F4 | DDR | 12 | IO_L20N_12,T0 |
| K3 | DDR | 12 | IO_L8N_12,T2 | C2 | DDR | 12 | IO_L21P_12,T0 |
| M1 | DDR | 12 | IO_L9P_12,T2 | C1 | DDR | 12 | IO_L21N_12,T0 |
| M2 | DDR | 12 | IO_L9N_12,T2 | B1 | DDR | 12 | IO_L22P_12,T0_DQS_P |
| K1 | DDR | 12 | IO_L10P_12,T2_DQS_P | B2 | DDR | 12 | IO_L22N_12,T0_DQS_N |
| L2 | DDR | 12 | IO_L10N_12,T2_DQS_N | D3 | DDR | 12 | IO_L23P_12,T0 |
| J1 | DDR | 12 | IO_L11P_12,GCLKIOT0,T2 | C3 | DDR | 12 | IO_L23N_12,T0 |
| K2 | DDR | 12 | IO_L11N_12,GCLKIOC0,T2 | A2 | DDR | 12 | IO_L24P_12,T0 |
| H3 | DDR | 12 | IO_L12P_12,GCLKIOT1,T2 | A3 | DDR | 12 | IO_L24N_12,T0 |
| J4 | DDR | 12 | IO_L12N_12,GCLKIOC1,T2 | G6 | DDR | 12 | IO_L25_12,VREF |

<!-- 原 PDF 第 166 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| P4 | HD | 21 | IO_BE1P_21 | U1 | HD | 21 | IO_BE7N_21 |
| R4 | HD | 21 | IO_BE1N_21 | U2 | HD | 21 | IO_BE8P_21 |
| P5 | HD | 21 | IO_BE2P_21 | U3 | HD | 21 | IO_BE8N_21 |
| R6 | HD | 21 | IO_BE2N_21 | V2 | HD | 21 | IO_BE9P_21 |
| P3 | HD | 21 | IO_BE3P_21 | V3 | HD | 21 | IO_BE9N_21 |
| R2 | HD | 21 | IO_BE3N_21 | N7 | HD | 21 | IO_BE10P_21 |
| P1 | HD | 21 | IO_BE4P_21 | P7 | HD | 21 | IO_BE10N_21,D31 |
| R1 | HD | 21 | IO_BE4N_21 | N6 | HD | 21 | IO_BE11P_21,D30 |
| R3 | HD | 21 | IO_BE5P_21 | P6 | HD | 21 | IO_BE11N_21,D29 |
| T3 | HD | 21 | IO_BE5N_21 | U5 | HD | 21 | IO_BE12P_21,D28 |
| T5 | HD | 21 | IO_BE6P_21 | V4 | HD | 21 | IO_BE12N_21,D27 |
| T4 | HD | 21 | IO_BE6N_21 | T6 | HD | 21 | IO_BE13P_21,GCLKIOT0 |
| T1 | HD | 21 | IO_BE7P_21 | T7 | HD | 21 | IO_BE13N_21,GCLKIOT2 |

<!-- 原 PDF 第 167 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| R13 | HD | 22 | IO_B0_22,USRCLK | U9 | HD | 22 | IO_BE9N_22,RDWRN |
| N12 | HD | 22 | IO_BE1P_22,D0_MOSI | V8 | HD | 22 | IO_BE10P_22,SPICSN_BUSY |
| M11 | HD | 22 | IO_BE1N_22,D1_MISO_DIN | U8 | HD | 22 | IO_BE10N_22,CSON |
| N11 | HD | 22 | IO_BE2P_22,D2_WPN | V6 | HD | 22 | IO_BE11P_22,D16 |
| M10 | HD | 22 | IO_BE2N_22,D3_HOLDN | V7 | HD | 22 | IO_BE11N_22,D17 |
| R12 | HD | 22 | IO_BE3P_22,D4 | T9 | HD | 22 | IO_BE12P_22,D18 |
| T13 | HD | 22 | IO_BE3N_22,D5 | R9 | HD | 22 | IO_BE12N_22,D19 |
| T12 | HD | 22 | IO_BE4P_22,D6 | N10 | HD | 22 | IO_BE13P_22,D20 |
| U12 | HD | 22 | IO_BE4N_22,D7 | N9 | HD | 22 | IO_BE13N_22,D21 |
| V11 | HD | 22 | IO_BE5P_22,D8 | M8 | HD | 22 | IO_BE14P_22,D22 |
| U11 | HD | 22 | IO_BE5N_22,D9 | N8 | HD | 22 | IO_BE14N_22,D23 |
| P11 | HD | 22 | IO_BE6P_22,D10 | V5 | HD | 22 | IO_BE15P_22,D24 |
| P10 | HD | 22 | IO_BE6N_22,D11 | U6 | HD | 22 | IO_BE15N_22,D25 |
| R11 | HD | 22 | IO_BE7P_22,D12 | T8 | HD | 22 | IO_BE16P_22,D26 |
| T11 | HD | 22 | IO_BE7N_22,D13 | R8 | HD | 22 | IO_BE16N_22,HSWAPEN |
| U10 | HD | 22 | IO_BE8P_22,D14 | P9 | HD | 22 | IO_BE17P_22,GCLKIOT1 |
| T10 | HD | 22 | IO_BE8N_22,D15 | P8 | HD | 22 | IO_BE17N_22,GCLKIOT3 |
| V9 | HD | 22 | IO_BE9P_22,CSN |  |  |  |  |

<!-- 原 PDF 第 168 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| K13 | HR | 32 | IO_R0_32 | B17 | HR | 32 | IO_R13P_32,GCLKIOT2,T1 |
| K17 | HR | 32 | IO_R1P_32,T3 | A17 | HR | 32 | IO_R13N_32,GCLKIOC2,T1 |
| L16 | HR | 32 | IO_R1N_32,T3 | F14 | HR | 32 | IO_R14P_32,GCLKIOT3,T1 |
| J15 | HR | 32 | IO_R2P_32,T3 | F13 | HR | 32 | IO_R14N_32,GCLKIOC3,T1 |
| J16 | HR | 32 | IO_R2N_32,T3 | C16 | HR | 32 | IO_R15P_32,T1 |
| J18 | HR | 32 | IO_R3P_32,T3 | C17 | HR | 32 | IO_R15N_32,T1 |
| K18 | HR | 32 | IO_R3N_32,T3 | E15 | HR | 32 | IO_R16P_32,T1_DQS_P |
| K16 | HR | 32 | IO_R4P_32,T3_DQS_P | F15 | HR | 32 | IO_R16N_32,T1_DQS_N |
| K15 | HR | 32 | IO_R4N_32,T3_DQS_N | B18 | HR | 32 | IO_R17P_32,T1 |
| H17 | HR | 32 | IO_R5P_32,T3 | C18 | HR | 32 | IO_R17N_32,T1 |
| H18 | HR | 32 | IO_R5N_32,T3 | E16 | HR | 32 | IO_R18P_32,T1 |
| J14 | HR | 32 | IO_R6P_32,T3 | D16 | HR | 32 | IO_R18N_32,T1 |
| J13 | HR | 32 | IO_R6N_32,T3_VREF | D15 | HR | 32 | IO_R19P_32,T0 |
| F18 | HR | 32 | IO_R7P_32,T2 | D14 | HR | 32 | IO_R19N_32,T0_VREF |
| G17 | HR | 32 | IO_R7N_32,T2 | A13 | HR | 32 | IO_R20P_32,T0 |
| G16 | HR | 32 | IO_R8P_32,T2 | B14 | HR | 32 | IO_R20N_32,T0 |
| H16 | HR | 32 | IO_R8N_32,T2 | B16 | HR | 32 | IO_R21P_32,T0 |
| F17 | HR | 32 | IO_R9P_32,T2 | A15 | HR | 32 | IO_R21N_32,T0 |
| E18 | HR | 32 | IO_R9N_32,T2 | B15 | HR | 32 | IO_R22P_32,T0_DQS_P |
| H14 | HR | 32 | IO_R10P_32,T2_DQS_P | A14 | HR | 32 | IO_R22N_32,T0_DQS_N |
| H13 | HR | 32 | IO_R10N_32,T2_DQS_N | E13 | HR | 32 | IO_R23P_32,T0 |
| E17 | HR | 32 | IO_R11P_32,GCLKIOT0,T1 | D13 | HR | 32 | IO_R23N_32,T0 |
| D18 | HR | 32 | IO_R11N_32,GCLKIOC0,T2 | C14 | HR | 32 | IO_R24P_32,T0 |
| G15 | HR | 32 | IO_R12P_32,GCLKIOT1,T2 | C13 | HR | 32 | IO_R24N_32,T0 |
| G14 | HR | 32 | IO_R12N_32,GCLKIOC1,T2 | E12 | HR | 32 | IO_R25_32 |

<!-- 原 PDF 第 169 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| C12 | HD | 42 | IO_T0_42 | B9 | HD | 42 | IO_TE9N_42 |
| A12 | HD | 42 | IO_TE1P_42 | C7 | HD | 42 | IO_TE10P_42 |
| B12 | HD | 42 | IO_TE1N_42 | C8 | HD | 42 | IO_TE10N_42 |
| A8 | HD | 42 | IO_TE2P_42 | A10 | HD | 42 | IO_TE11P_42 |
| A7 | HD | 42 | IO_TE2N_42 | B10 | HD | 42 | IO_TE11N_42 |
| E9 | HD | 42 | IO_TE3P_42 | A4 | HD | 42 | IO_TE12P_42 |
| D8 | HD | 42 | IO_TE3N_42 | B4 | HD | 42 | IO_TE12N_42 |
| D9 | HD | 42 | IO_TE4P_42 | E11 | HD | 42 | IO_TE13P_42 |
| C9 | HD | 42 | IO_TE4N_42 | D11 | HD | 42 | IO_TE13N_42 |
| C11 | HD | 42 | IO_TE5P_42 | D10 | HD | 42 | IO_TE14P_42 |
| B11 | HD | 42 | IO_TE5N_42 | E10 | HD | 42 | IO_TE14N_42 |
| E8 | HD | 42 | IO_TE6P_42 | C6 | HD | 42 | IO_TE15P_42 |
| E7 | HD | 42 | IO_TE6N_42 | D6 | HD | 42 | IO_TE15N_42 |
| B6 | HD | 42 | IO_TE7P_42 | A5 | HD | 42 | IO_TE16N_42 |
| B7 | HD | 42 | IO_TE7N_42 | B5 | HD | 42 | IO_TE16P_42 |
| E6 | HD | 42 | IO_TE8P_42 | C4 | HD | 42 | IO_TE17P_42,GCLKIOT1 |
| D5 | HD | 42 | IO_TE8N_42 | D4 | HD | 42 | IO_TE17N_42,GCLKIOT3 |
| A9 | HD | 42 | IO_TE9P_42 |  |  |  |  |

<!-- 原 PDF 第 170 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| V15 | MIPI | - | IO_0P_DPHY0,CKP_0 | R15 | HD | 0 | CCLK_0 |
| U16 | MIPI | - | IO_0N_DPHY0,CKN_0 | N13 | - | 0 | DONE_0 |
| V13 | MIPI | - | IO_1P_DPHY0,DP0_0 | M15 | - | 0 | INITN_0 |
| U14 | MIPI | - | IO_1N_DPHY0,DN0_0 | N15 | - | 0 | PROGRAMN_0 |
| V14 | MIPI | - | IO_2P_DPHY0,DP1_0 | M12 | - | 0 | M0_0 |
| U15 | MIPI | - | IO_2N_DPHY0,DN1_0 | M14 | - | 0 | M1_0 |
| V16 | MIPI | - | IO_3P_DPHY0,DP2_0 | N14 | - | 0 | M2_0 |
| U17 | MIPI | - | IO_3N_DPHY0,DN2_0 | P15 | - | 0 | TCK_0 |
| V17 | MIPI | - | IO_4P_DPHY0,DP3_0 | P14 | - | 0 | TDI_0 |
| U18 | MIPI | - | IO_4N_DPHY0,DN3_0 | P13 | - | 0 | TDO_0 |
| P18 | MIPI | - | IO_5P_DPHY1,CKP_1 | L15 | - | 0 | TMS_0 |
| P17 | MIPI | - | IO_5N_DPHY1,CKN_1 |  |  |  |  |
| T18 | MIPI | - | IO_6P_DPHY1,DP0_1 |  |  |  |  |
| T17 | MIPI | - | IO_6N_DPHY1,DN0_1 |  |  |  |  |
| R18 | MIPI | - | IO_7P_DPHY1,DP1_1 |  |  |  |  |
| R17 | MIPI | - | IO_7N_DPHY1,DN1_1 |  |  |  |  |
| N18 | MIPI | - | IO_8P_DPHY1,DP2_1 |  |  |  |  |
| N17 | MIPI | - | IO_8N_DPHY1,DN2_1 |  |  |  |  |
| M18 | MIPI | - | IO_9P_DPHY1,DP3_1 |  |  |  |  |
| M17 | MIPI | - | IO_9N_DPHY1,DN3_1 |  |  |  |  |

<!-- 原 PDF 第 171 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| M13 | - | 0 | VCCIO_0 | V12 | - | - | VCCDPHY |
| R14 | - | 0 | VCCIO_0 | N16 | - | - | VCCDPHY |
| F1 | - | 12 | VCCIO_12 | R16 | - | - | VCCDPHY |
| J2 | - | 12 | VCCIO_12 | T15 | - | - | VCCDPHY |
| H5 | - | 12 | VCCIO_12 | L18 | - | - | VCCDPHY |
| L6 | - | 12 | VCCIO_12 | G10 | - | - | VCCINT |
| M3 | - | 12 | VCCIO_12 | G8 | - | - | VCCINT |
| E4 | - | 12 | VCCIO_12 | H11 | - | - | VCCINT |
| M7 | - | 21 | VCCIO_21 | H9 | - | - | VCCINT |
| R5 | - | 21 | VCCIO_21 | J10 | - | - | VCCINT |
| T2 | - | 21 | VCCIO_21 | J12 | - | - | VCCINT |
| M9 | - | 22 | VCCIO_22 | J8 | - | - | VCCINT |
| R10 | - | 22 | VCCIO_22 | K11 | - | - | VCCINT |
| U7 | - | 22 | VCCIO_22 | K9 | - | - | VCCINT |
| G18 | - | 32 | VCCIO_32 | L10 | - | - | VCCINT |
| A16 | - | 32 | VCCIO_32 | L12 | - | - | VCCINT |
| B13 | - | 32 | VCCIO_32 | L8 | - | - | VCCINT |
| D17 | - | 32 | VCCIO_32 | K7 | - | - | VCCINT |
| H15 | - | 32 | VCCIO_32 | F11 | - | - | VCCAUX |
| E14 | - | 32 | VCCIO_32 | F7 | - | - | VCCAUX |
| A6 | - | 42 | VCCIO_42 | F9 | - | - | VCCAUX |
| C10 | - | 42 | VCCIO_42 | G12 | - | - | VCCAUX |
| D7 | - | 42 | VCCIO_42 | H7 | - | - | VCCAUX |

<!-- 原 PDF 第 172 页 -->


| PH1P35MEG324/PH1P35MEG324A | PH1P35MEG324/PH1P35MEG324A |  |  |  |  |  |  |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 编号 | 类型 | BANK | 编号 | 类型 | BANK |  |  |
| 引脚说明 | 引脚说明 |  |  |  |  |  |  |
| A1 | - | - | GND | P12 | - | - | GND |
| A11 | - | - | GND | P16 | - | - | GND |
| B8 | - | - | GND | P2 | - | - | GND |
| C15 | - | - | GND | T14 | - | - | GND |
| C5 | - | - | GND | T16 | - | - | GND |
| D12 | - | - | GND | U13 | - | - | GND |
| D2 | - | - | GND | V10 | - | - | GND |
| H10 | - | - | GND | G7 | - | - | GND |
| H12 | - | - | GND | F10 | - | - | GND |
| H8 | - | - | GND | F6 | - | - | GND |
| J11 | - | - | GND | F8 | - | - | GND |
| J17 | - | - | GND | G9 | - | - | GND |
| J7 | - | - | GND | G11 | - | - | GND |
| J9 | - | - | GND | G3 | - | - | GND |
| K10 | - | - | GND | B3 | - | - | GND |
| K12 | - | - | GND | V1 | - | - | GND |
| K14 | - | - | GND | R7 | - | - | GND |
| K4 | - | - | GND | U4 | - | - | GND |
| K8 | - | - | GND | F16 | - | - | GND |
| L1 | - | - | GND | G13 | - | - | GND |
| L11 | - | - | GND | A18 | - | - | GND |
| L17 | - | - | GND | F12 | - | - | GND |
| L7 | - | - | GND | V18 | - | - | GND |
| L9 | - | - | GND | L14 | - | - | NC |
| M16 | - | - | GND | L13 | - | - | NC |
| N5 | - | - | GND |  |  |  |  |

<!-- 原 PDF 第 173 页 -->

### 4.10 封装信息
#### 4.10.1 PH1P100SBG676/PH1P100SBG677封装规格

![封装规格图纸，原 PDF 第 173 页](DS1300_PH1P_Datasheet_assets/package-173.png)

> 此页为封装尺寸图纸，原 PDF 中无独立可提取的文字，尺寸与公差请以图纸为准。

<!-- 原 PDF 第 174 页 -->

#### 4.10.2 PH1P35MBG484封装规格

![封装规格图纸，原 PDF 第 174 页](DS1300_PH1P_Datasheet_assets/package-174.png)

> 此页为封装尺寸图纸，原 PDF 中无独立可提取的文字，尺寸与公差请以图纸为准。

<!-- 原 PDF 第 175 页 -->

#### 4.10.3 PH1P35MDG324/PH1P35MHG324封装规格

![封装规格图纸，原 PDF 第 175 页](DS1300_PH1P_Datasheet_assets/package-175.png)

> 此页为封装尺寸图纸，原 PDF 中无独立可提取的文字，尺寸与公差请以图纸为准。

<!-- 原 PDF 第 176 页 -->

#### 4.10.4 PH1P35MEG324/PH1P35MEG324A封装规格

![封装规格图纸，原 PDF 第 176 页](DS1300_PH1P_Datasheet_assets/package-176.png)

> 此页为封装尺寸图纸，原 PDF 中无独立可提取的文字，尺寸与公差请以图纸为准。

<!-- 原 PDF 第 177 页 -->

#### 4.10.5 PH1P100SBG484封装规格

![封装规格图纸，原 PDF 第 177 页](DS1300_PH1P_Datasheet_assets/package-177.png)

> 此页为封装尺寸图纸，原 PDF 中无独立可提取的文字，尺寸与公差请以图纸为准。

<!-- 原 PDF 第 178 页 -->

#### 4.10.6 PH1P100GEG324封装规格

![封装规格图纸，原 PDF 第 178 页](DS1300_PH1P_Datasheet_assets/package-178.png)

> 此页为封装尺寸图纸，原 PDF 中无独立可提取的文字，尺寸与公差请以图纸为准。

<!-- 原 PDF 第 179 页 -->

## 5 订购信息
表 5-1 器件号缩写
器件名称 类别 查找表容量 封装类型 温度等级
PH1 P 100 SBG676 I
 产品系列
 PH1  PH1 系列
 类别
 P  逻辑器件
 查找表容量
 100  100k 查找表
 50  50K 查找表
 35  35K 查找表
 封装类型：<类型><#>
 SBG676 27mm x 27mm, 1mm pitch
 SBG677 27mm x 27mm, 1mm pitch
 MBG484 23mm x 23mm, 1mm pitch
 MDG324 15mm x 15mm, 0.8mm pitch
 MHG324 15mm x 15mm, 0.8mm pitch
 SBG484 23mm x 23mm, 1mm pitch
 MEG324 15mm x 15mm, 0.8mm pitch
 GEG324 15mm x 15mm, 0.8mm pitch
 #  引脚数（676 指 676 个引脚；PH1P100SBG677 中的677 仅用于区别与PH1P100SBG676
器件的SERDES 供电电源差异，实际为676 个管脚）
 温度等级
 I  工业等级（TJ = -40 – 100 ℃）
 A  汽车等级（TJ = -40 – 125 ℃）
 速度等级
 3  中速

<!-- 原 PDF 第 180 页 -->

 3L  中速低功耗
 吸湿敏感等级
   MSL3

<!-- 原 PDF 第 181 页 -->

PH1
P
100
SBG676
I
3
器件名称
PH1 FPGA
类型
P 逻辑器件
查找表容量
35  35K查找表
50  50K查找表
100 100K查找表
速度等级
3     中速
3L 中速低功耗
温度等级
I  工业级（TJ = -40 ~100 ）
A  车规级（TJ = -40 ~125 ）
封装类型
SBG676 27mm×27mm，  1mm pitch
SBG677 27mm×27mm，  1mm pitch
MBG484 23mm×23mm，  1mm pitch
SBG484 23mm×23mm，  1mm pitch
MDG324 15mm×15mm，0.8mm pitch
MHG324 15mm×15mm，0.8mm pitch
MEG324 15mm×15mm，0.8mm pitch
GEG324 15mm×15mm，0.8mm pitch

<!-- 原 PDF 第 182 页 -->

## 版本信息
日期 版本 修订记录
2023/12/21 0.1 编写初版本
2024/04/01 0.2
1.新增器件PH1X100SBG676、PH1P35MBG484、PH1S35MEG324
a.在 1.1 章节中
更新源同步输入/输出接口、高性能,灵活的输入/输出缓冲器、时钟资源、多
种封装形式；
新增 MIPI DPHY、RISC V MCU 硬核、Integrated Memory Interface；
更新表1-1 PH1P FPGA 系列选型表；
更新表 1-2 PH1P FPGA 封装，新增注释3、4
b.在 2 章节中，新增器件PH1X100、PH1P35 架构图；
2.3 章节中新增器件PH1X100、PH1P35 时钟资源示意图；
2.5 章节中新增支持9x9 乘法器功能（PH1P35）
2.6 章节中新增器件PH1X100 HXT 资源示意图，更新表2-3
2.7 章节中新增器件PH1X100、PH1P35
2.8 章节中新增器件PH1X100、PH1P35，更新表2-5
新增 2.12 章节Integrated Memory Interface、2.13 章节MIPI DPHY、2.14
章节 MCU
c.在第3、4、5 章节中，新增器件PH1X100、PH1P35
2.修改2.4 章节名称为PLL 和CLOCK ALIGNER,新增2.4.2 章节CLOCK
ALIGNER
2024/05/09 0.3
1.更新器件名称
PH1X100SBG676 修改为PH1P100SBG677
PH1S35MEG324 修改为PH1P35MDG324
2.更新表 1-2 PH1P FPGA 封装中 I/O 数量
3.MSPI 模式下，PH1P35 器件CCLK 时钟源为OSC 或者USRCLK
更新 2.8.4 章节主动SPI 配置模式
新增表 2-10 MSPI 时序规格表（CCLK 时钟来源为USRCLK）
更新 3.2.7 配置模块
4.更新4.1 章节IO 命名规则、4.2 章节引脚定义和规则、4.5 章节MBG484
引脚信息、4.6 章节MDG324 引脚信息
删除 MIPI 串并转换，并串转换
2024/05/30 0.4
全文删除锁存器
增加 MIPI 串并转换，并串转换功能
更新 Integrated Memory Interface 相关描述
更新表1-2 External Memory Interface PH1P35MBG484 器件Max DQ

<!-- 原 PDF 第 183 页 -->

日期 版本 修订记录
Width，更新注释2，新增注释5
在表 3-24 配置模式时序规格表中新增注释3
更新表 4-2-1 引脚定义和规则中 TRSTN 相关描述
2024/08/14 0.5
新增 PH1P35MHG324 器件
全文更新External Memory Interface 速率
在表 2-1 ERAM20K 特性中，更新注释2
在表 2 5 配置模式及对应位宽中新增注释1
全文更新参数规格
新增 3.1.3 节 IO BANK 基本供电要求
表 3-5 器件管脚电容新增注1
2024/09/09 0.6
1.在 1.1 节中，分布式和嵌入式存储器中更新伪双口为简单双口
2.在 1.1 节中，源同步输入/输出接口中更新LVDS33 的相关描述
3.在 1.1 节中，更新MIPI DPHY 中的相关描述
4.在 1.1 节中，External Memory Interface 中删除DDR4,并全文更新
5.在 1.1 节中，SEU 检错和纠错中更新错误注入的描述，并全文更新
6.在表 1-1 PH1P FPGA 系列选型表中，新增TVS
7.在 2.2.2 ERAM20K 功能节中，更新ECC 单bit、双bit 纠错、检错和插错
说明
8.更新图 2-6 PH1P35 器件时钟资源示意图
9.更新表 2-2 PLL 特性注1、2
10.更新2.7 节输入输出缓冲器（IOB），HR I/O 删除Bus Hold 功能
11.2.7 节输入输出缓冲器（IOB），新增注释6、7
12.表2-5 配置模式及对应位宽中更新注释1
13.表2-6 Configuration Pin Termination 中更新TMS TCK TDO TDI
/TRSTN 配置成功前的参数配置，更新注释2：新增IO GLITCH 相关描述
14.更新表3-1 最大绝对额定值：IDCIN-PHYVCCA/PHYVCCT、IDCOUT- PHYVCCA/PHYVCCT
15.更新表 3-5 推荐基本操作条件
16.更新表 3-6 PH1P100SBG676 最小供电要求注释
17.表 3-8 PH1P35MBG484 最小供电要求新增VCCDPHY
18.表 3-9 PH1P35MDG324/PH1P35MHG324 最小供电要求新增VCCDPHY
19.图 3-2 器件上电时序图删除注释1：删除PIR 监测JTAG 端口要求
20.表 3-11 上下电复位电压阈值
21.表 3-13 热插拔规格更新注释2：AC 定义
22.表 3-20 IO 单端I/O 标准规格（MIPI I/O）中删除LVCMOS15，全文更新
23.更新表 3-21 LVDS 直流规格(HR I/O)，删除注释
24.更新表 3-32 差分I/O 直流规格(HR I/O)
25.更新表 3 35 MIPI TX 直流特性|△VCMTX|参数描述
26.更新表 3-36 最大时钟操作频率，新增注释1
27.表 3-37 时钟最大skew 更新TMLCLK 性能

<!-- 原 PDF 第 184 页 -->

日期 版本 修订记录
28.表 3-39 存储器模块规格表中更新：Clk to dout (无寄存器模式)、Clk
to dout (寄存器模式)、Clk to dout with ECC (无寄存器模式)、Clk to
dout with ECC (寄存器模式)
29.表 3-40 PLL 规格更新FPFD、TSTATPHAOFFSET，更新注释3
30.表 3-42 TVS 模块指标更新最小脉冲宽度
31.3.2.7 I/O 接口性能新增SLEWRATE 内容
32.更新表 3-43 I/O 接口性能表（HR I/O 输入）
33.更新表 3-44 I/O 接口性能表（HR I/O 输出），新增注释1
34.更新表 3-55 MIPI TX 交流特性
35.更新表 3-57 HXT 串行收发器直流参数规格
36.表 3-58 HXT 串行收发器性能参数中更新LANE PLL 输出频率范围
37.更新表 3-59 APB 接口交流特性
38.更新表 3-60 HXT 串行收发器PLL 锁定时间
39.表 3-62 HXT 串行收发器发送交流特性更新：FMAXTX、TXSST，更新注释1
40.更新表 3-63  HXT 收发器RX 交流特性
41.更新表 3-64 HXT 收发器参考时钟要求
42.更新表 3-65 PCI Express 控制器输入时钟频率要求
43.更新表4-2-1 引脚定义和规则
44.更新4.7.1 节 PH1P100SBG676/PH1P100SBG677 封装规格
45.更新第5 章订购信息
46.更新表 3-61 HXT 用户时钟输入交流特性
47.在表 3-62 HXT 串行收发器发送交流特性中新增TJ0.5、DJ0.5
48.在表 3-63 HXT 收发器RX 交流特性中新增JT_SJ2.5
49.在表 3-64 HXT 收发器参考时钟要求删除phase noise,新增注3：phase
noise 根据不同协议规范来选择
2024/12/25 1.0 1.PH1P100SBG676 器件首次发布正式版
2025/04/14 1.1
1. PH1P35MBG484、PH1P35MDG324、PH1P35MHG324 器件首次发布正式版
2. 新增 PH1P100SBG484、 PH1P100GEG324、 PH1P35MEG324、 PH1P35MEG324A
器件,并全文更新描述
3. PH1P100SBG677 器件：
（1）在表 3-62 HXT 串行收发器直流参数规格中新增 RRESREF 规格；
（2）更新表 4-2 引脚定义和规则中HXT 相关管脚模块，HXT 接收恢复时
钟管脚相关描述
4. 更新图 2-1 PH1P100 器件架构图
更新
5. 表 2-7 主动串行时序规格表
更新
6. 表 2-7 主动串行时序规格表注释1，更新OSC 精度

<!-- 原 PDF 第 185 页 -->

日期 版本 修订记录
7. 更新表 2-9 MSPI 时序规格表（CCLK 时钟来源为 OSC）
8. 更新表 2-9 MSPI 时序规格表 （CCLK 时钟来源为 OSC） 注释1， 更新OSC
精度
9. 更新表 2-12 主动并行时序规格表
10. 更新表 2-12 主动并行时序规格表注释 1，更新OSC 精度
11. 更新表 3-17 IO 推荐基本操作条件(HR I/O)中的VHYST 规格
12. 更新表 3-24 LVDS 直流规格(HR I/O)中的VICM 规格
13. 更新表 3-48 I/O 接口性能表（HR I/O 输入）
14. 更新表 3-49 I/O 接口性能表（HR I/O 输出）
15. 删除表 3-69 HXT 收发器参考时钟要求中的注释2
2025/08/29 1.2
1. PH1P35MEG324 器件首次发布正式版
2. 新增 表 1-2 PH1P FPGA 封装中 Integrated Memory Interface 的
Capacity 规格
3. 更新 5 订购信息章节中速度等级
4. 更新表 3-41 最大时钟操作频率一表中IOCLK 和 MLCLK 性能， 更新注1 描
述，并新增注2 对IO 使用LVDS 时IOCLK 和MLCLK 的性能支持进行说明
5. 新增表 2-2 PLL 特性一表注3，补充PH1P 器件的小数分频精度说明
6. 删除表 2-5 配置模式及对应位宽注1，后续以IO BANK 基本供电要求一
节描述为准

<!-- 原 PDF 第 186 页 -->

版权所有©2025 上海安路信息科技股份有限公司
未经本公司书面许可， 任何单位和个人都不得擅自摘抄、 复制、 翻译本文档内容的部分或全部， 并不得
以任何形式传播。
## 免责声明
本文档并未授予任何知识产权的许可， 并未以明示或暗示， 或以禁止发言或其他方式授予任何知识产权
许可；本文档仅为向用户提供使用器件的参考， 协助用户正确地使用安路科技产品之用， 其著作权归安
路科技所有；本文档所展示的任何产品信息均不构成安路科技对所涉产品或服务作出任何明示或默示
的声明或保证。
安路科技将不定期地对本文档进行更新、 修订。 用户如需获取最新版本的文档， 可通过安路科技的官方
网站（网址为：https://www.anlogic.com）自行查询下载，也可联系安路科技的销售人员咨询获取。
