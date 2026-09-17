// ============================================================================
// ctrl_sync —— CTRL_SYNC 插座：每帧一个字的跨时钟域传输（上下行各实例化一次）
//
// 用途：CSI 域（识别支路 ~59 MHz）与 HDMI 像素域（游戏/渲染 75 MHz）之间每帧交换
// 一个字，**宽度是参数 WIDTH（默认 26）**；字义按方向不同（冻结布局见 README §12.1
// 与规划 §2.5.2）：
//   下行（像素域 → CSI 域）形状描述子 = {shape_type[2:0], progress[7:0],
//                                        hole_w[5:0], hole_h[5:0], variant[2:0]}
//   上行（CSI 域 → 像素域）判定结果   = {verdict[1:0], viol_cnt[11:0], fill[11:0]}
// 两个时钟在 SDC 里已声明为异步组，本模块用"数据锁存 + toggle 握手 +
// 接收侧两级同步 + 边沿检测"，每帧一次，不做全帧总线。
//
// 延迟：发送侧 1 拍锁存 + 跨域 2~3 拍；每帧只传一次，对画面无影响。
// 时钟域：跨域模块本身。调用方必须在 SDC 里给这两个时钟对加
//         set_max_delay -datapath_only（见 td_project/camera_to_dsi_display.sdc）。
// 资源：约 30 FF + 30 LUT（随 WIDTH 线性增长），无 ERAM / DSP。
// ============================================================================
module ctrl_sync #(
    parameter WIDTH = 26      // 数据宽度；默认 26 = CTRL_SYNC 冻结布局
)(
    // 发送侧
    input  wire        I_tx_clk,
    input  wire        I_tx_rst_n,
    input  wire        I_tx_valid,    // 1 拍脉冲：提交一个字
    input  wire [WIDTH-1:0] I_tx_data,
    // 接收侧
    input  wire        I_rx_clk,
    input  wire        I_rx_rst_n,
    output reg  [WIDTH-1:0] O_rx_data,     // 与 O_rx_valid 同拍有效，之后保持
    output reg         O_rx_valid     // 1 拍脉冲
);

    // ---- 发送侧：数据与 toggle 同时更新，接收侧等同步器稳定后再采数据 ----
    reg [WIDTH-1:0] S_tx_data;
    reg        S_tx_toggle;

    always @(posedge I_tx_clk or negedge I_tx_rst_n) begin
        if(!I_tx_rst_n) begin
            S_tx_data   <= {WIDTH{1'b0}};
            S_tx_toggle <= 1'b0;
        end
        else if(I_tx_valid) begin
            S_tx_data   <= I_tx_data;
            S_tx_toggle <= ~S_tx_toggle;
        end
    end

    // ---- 接收侧：两级同步 + 边沿检测 ----
    reg [2:0] S_rx_sync;

    always @(posedge I_rx_clk or negedge I_rx_rst_n) begin
        if(!I_rx_rst_n) begin
            S_rx_sync  <= 3'b000;
            O_rx_data  <= {WIDTH{1'b0}};
            O_rx_valid <= 1'b0;
        end
        else begin
            S_rx_sync  <= {S_rx_sync[1:0], S_tx_toggle};
            O_rx_valid <= 1'b0;
            // 两级同步之后再过一拍才比较：此时 toggle 与数据都已稳定。
            if(S_rx_sync[2] ^ S_rx_sync[1]) begin
                O_rx_data  <= S_tx_data;
                O_rx_valid <= 1'b1;
            end
        end
    end

endmodule
