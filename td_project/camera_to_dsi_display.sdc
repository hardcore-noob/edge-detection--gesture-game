create_clock -name {sys_clk_50m} -period 20.000 -waveform {0.000 10.000} [get_ports {I_sys_clk}]
create_clock -name {mipi_rx_ck_pad} -period 4.167 -waveform {0.000 2.083} [get_nets {IO_rx_clk_pad_p}]

derive_clocks

rename_clock -name {pll_clk_100m} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[0]}]
rename_clock -name {pll_clk_24m} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[1]}]
rename_clock -name {HDMI_PIXEL_CLK} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[4]}]
rename_clock -name {HDMI_SERIAL_CLK} [get_clocks {u_PLL/ph1p_phy_pll_wrapper_25a56e5ce2f9_Inst/u_PH1P_PHY_PLL.clkc[5]}]

rename_clock -name {MIPI_RX_BYTE_CLK} [get_clocks {u_mipi_dphy_rx_ph1p_mipiio_wrapper/u_ph1p_mipiio_rx_wrapper/u_PH1P_LOGIC_DPHY_MIPI_RX.o_fabric_div4_8_clk}]


set_clock_groups -asynchronous \
    -group [get_clocks {mipi_rx_ck_pad MIPI_RX_BYTE_CLK}] \
    -group [get_clocks {sys_clk_50m pll_clk_100m pll_clk_24m HDMI_PIXEL_CLK HDMI_SERIAL_CLK}] \
    -group [get_clocks {u_ph1p35_324_ddr_wrapper/u_ddr2/ddr_clk u_ph1p35_324_ddr_wrapper/u_ddr2/usr_clk}]

# Algorithm selection is transferred from the 24 MHz clock domain to the
# HDMI pixel clock domain through a three-stage metastability synchronizer.
# Constrain only the raw data path for this controlled CDC transfer.
set_max_delay -datapath_only 5.000 \
    -from [get_clocks {pll_clk_24m}] \
    -to   [get_clocks {HDMI_PIXEL_CLK}]

# 2026-09-14（手势游戏 M0）：新增的跨域通路都是"数据先锁存稳定、再用同步过的 toggle
# 使能去捕获"的握手（见 isp/ctrl_sync.v、mode_sync.v、recog_top.v 的整包捕获）：
#   * 像素域 → CSI 域：模式寄存器（display_mode + 门限档位，相机帧首提交）、
#     CTRL_SYNC 下行的形状几何；
#   * CSI 域 → 像素域：VIDEO_TAP 的每帧观测（tap 像素数 / 掩码统计 / 包围盒）、
#     CTRL_SYNC 上行的判定结果。
# **重要（2026-09-14 实测）**：TD 对**已声明为异步的时钟对**会直接忽略 `set_max_delay`
# ——报告 `camera_to_dsi_display_exception.timing` 里这两条被标成 "Set Max Delay
# (Ignored)"，把它们从 5.000 改成 15.000 后所有时序数字一个都没变。MIPI_RX_BYTE_CLK
# 与 HDMI_PIXEL_CLK 在文件开头就是两个异步组，所以这两个方向的路径本来就被切断了，
# **CSI 域 ↔ 像素域**的这类路径 TD 一律不管（保证手段只能是握手设计本身）。
# 因此这两条约束的真实作用是"记录意图"：万一以后有人取消异步组，约束立刻生效；而
# 24m↔像素域这类**同一异步组内**的路径（例如 24m 的 A/G → logger）照常按普通路径算，
# 那类路径才是要靠打拍/RTL 去满足的（A/G 已在顶层加了像素域寄存器）。
# 15 ns 的取值理由：这批传输是"数据先稳定、同步过的 toggle 再触发整包捕获"，接收侧
# 有约 2 拍（≈27 ns）的窗口，15 ns 既挡得住绕远路的长线，又不会把多拍握手误当单拍卡。
set_max_delay -datapath_only 15.000 \
    -from [get_clocks {HDMI_PIXEL_CLK}] \
    -to   [get_clocks {MIPI_RX_BYTE_CLK}]

set_max_delay -datapath_only 15.000 \
    -from [get_clocks {MIPI_RX_BYTE_CLK}] \
    -to   [get_clocks {HDMI_PIXEL_CLK}]
