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

# 2026-09-14（手势游戏 M0）：新增的跨域通路都是"两级同步 + 慢控制/每帧一次"的
# 握手信号（见 isp/ctrl_sync.v、mode_sync.v）：
#   * 像素域 → CSI 域：模式寄存器（display_mode + 门限档位，相机帧首提交）、
#     CTRL_SYNC 下行的形状几何；
#   * CSI 域 → 像素域：VIDEO_TAP 的每帧观测（tap 像素数 / 掩码统计 / 包围盒）、
#     CTRL_SYNC 上行的判定结果。
# 两组时钟在文件开头已声明为异步组，这里只按同一套路约束数据路径。
set_max_delay -datapath_only 5.000 \
    -from [get_clocks {HDMI_PIXEL_CLK}] \
    -to   [get_clocks {MIPI_RX_BYTE_CLK}]

set_max_delay -datapath_only 5.000 \
    -from [get_clocks {MIPI_RX_BYTE_CLK}] \
    -to   [get_clocks {HDMI_PIXEL_CLK}]
