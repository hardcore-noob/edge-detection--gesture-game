# DBG 串口调试字段

本文是运行时 `DBG:` 日志的完整字段说明。README 只保留日志格式和快速判据；
修改 `debug_uart_logger.v`、字段宽度或字段复用规则时，必须同步更新本文。

## 连接与输出

- 板载 Type-C USB 提供 USB-UART，FPGA TXD 为 `H1`。
- 波特率：115200，8-N-1。
- 周期：每 1 s 输出一行。
- 行长度：152 字节，换行使用 CR/LF。
- 所有数值均为十六进制。

```text
DBG:F=xxxx A=xxxx G=xxxx T=xxxxxx N=xxxxx B=xxxxx C=xxxxx M=xxx L=xx D=xxxx E=xxxx W=xxx V=xxx K=xxxx S=xxxx P=xxxx Q=xxxx R=xxxx U=xxxx X=xxxx Y=xxxx
```

读取日志：

```powershell
.\tools\read_debug_uart.ps1 -Port COM3
```

脚本同时打印到终端并追加写入 `debug_uart.log`。

## 字段表

| 字段 | 位宽 | 含义 |
|---|---:|---|
| `F` | 16 | HDMI 显示帧计数 |
| `A` | 16 | AE 曝光目标值 |
| `G` | 16 | AG 增益目标值 |
| `T` | 24 | 流水线状态位图 |
| `N` | 20 | 当前帧非零像素计数 |
| `B` | 20 | 亮度 ≥64 的像素计数 |
| `C` | 20 | 亮度 ≥128 的像素计数 |
| `M` | 10 | RAW10 最大值 |
| `L` | 8 | 显示层最大值 |
| `D` | 16 | `video_in` FIFO 上一帧丢写次数 |
| `E` | 16 | `video_out` FIFO 上一帧丢写次数 |
| `W` | 9 | `video_in` FIFO 上一帧最大占用，范围 0..511 |
| `V` | 9 | `video_out` FIFO 上一帧最大占用，范围 0..511 |
| `K` | 16 | 已提交模式字 |
| `S` | 16 | 已生效 EDGE 门限 |
| `P` | 16 | 默认：选定掩码像素数 `>>4` |
| `Q` | 16 | 默认：`{x_min/16, x_max/16}` |
| `R` | 16 | 默认：`{y_min/16, y_max/16}` |
| `U` | 16 | VIDEO_TAP 每帧像素数 `>>10` |
| `X` | 16 | CTRL_SYNC 上行自检字 x |
| `Y` | 16 | CTRL_SYNC 上行自检字 y |

`K` 的默认布局：

```text
K = {4'b0, recog_algo[3:0], game_mode[3:0], display_mode[3:0]}
```

`K` 取自 mode sync 的回执，表示已经提交到 CSI 域的值；UART 请求值应通过
`param_wr_cnt` 和对应地址回读确认。

## T 位图

| bit | 含义 |
|---:|---|
| 23 | MC 初始化完成 |
| 22 | MC APP READY |
| 21 | MC WDF READY |
| 20 | MC CMD POP |
| 19 | DDR 读数据有效 |
| 18 | DDR 写请求 |
| 17 | DDR READY |
| 16 | DDR 写请求脉冲 |
| 15 | ISP valid |
| 14 | ISP frame-start |
| 13 | ISP 有数据 |
| 12 | RAW stream 有数据 |
| 11 | RAW10 有数据 |
| 10 | CSI 有数据 |
| 9 | MIPI HS 有效 |
| 8 | 摄像头配置完成 |
| 7 | EDGE 输出 valid |
| 6 | EDGE 输出数据非零 |
| 5 | DDR 读到非零视频 |
| 4 | HDMI 显示像素非零 |
| 3 | 算法状态：0=RAW，1=EDGE |
| 2 | HDMI OUT DE |
| 1 | HDMI DE |
| 0 | HDMI 窗口读使能 |

## 字段复用

`P/Q/R` 在识别调试档下会复用：

- 默认交付模式：掩码像素数和包围盒。
- `recog_algo` 运行档 8..15：由 `recog_top.v` 的调试输出 mux 重新解释。
- M2/M2.1 调试模式下可分别表示指尖、手型、挥手方向和帧位移。

字段复用只改变显示语义，不改变 DBG 行的位置和宽度。新增复用时必须在本表和
`recog_top.v` 输出 mux 同时登记。

## 采样规则

- 同一行的统计值必须来自同一完整帧；计数器在帧首锁存，日志上报上一完整帧。
- `tuser` 是直通信号，可能落在 `tvalid=0` 的拍上。像素计数按 `tvalid`，
  帧首锁存和跨域 toggle 按 `tuser`。
- `D/E` 恒为 0 表示这一秒没有 FIFO 满导致丢写；`W/V` 越接近 `0x1FF`
  表示 FIFO 越接近写满。
- `U=0x0384` 表示 1280×720 tap 每帧 921600 像素；`X=0x00a5`、`Y=0x00d3`
  是 M0 CTRL_SYNC 往返自检常数。

## 修改清单

修改字段时同时检查：

1. `debug_uart_logger.v` 的端口、模板、字段宽度和 `LINE_LAST`。
2. 顶层字段来源和跨域同步方式。
3. `tools/read_debug_uart.ps1` 的解析与输出。
4. 本文、README 第 7 节和相关测试期望值。
5. 新行长度在 115200 波特率下仍小于 1 s 发送周期。
