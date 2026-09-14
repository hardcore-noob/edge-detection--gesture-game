// ============================================================================
// mode_sync —— 模式寄存器到 CSI 域的"帧首提交"桥（像素域 ↔ CSI 域）
//
// 为什么要它：alg mux 与边缘门限都在 CSI 域决定写入 DDR 的像素，而按键/参数在
// 像素域。如果让模式在任意时刻生效，正在写的那一帧会被切成两种算法（README 第 5
// 节记的"切换瞬间可能出现短暂撕裂"）。本模块把新值先送到 CSI 域挂起，等下一个
// **相机帧首**（I_frame_start = ISP 输出的 tuser）再提交，于是写入 DDR 的每一帧
// 都是单一模式。
//
// 结构：两条 ctrl_sync（下行请求、上行回执）——同一套跨域手法，不新增机制。
// 延迟：请求侧发现变化 1 拍 + 跨域 2~3 拍 + 等帧首（≤16.7 ms）+ 回执 2~3 拍。
// 时钟域：跨域模块。请在 SDC 里给这两个时钟对加 set_max_delay -datapath_only。
// 资源：两个 ctrl_sync，约 60 FF + 60 LUT。
// ============================================================================
module mode_sync (
    // 请求侧（像素域）
    input  wire       I_req_clk,
    input  wire       I_req_rst_n,
    input  wire [7:0] I_req_data,     // {display_mode[3:0], edge_th_sel[3:0]}
    output wire [7:0] O_echo_data,    // 已完成提交的值（像素域）
    output wire       O_echo_valid,   // 提交完成 1 拍脉冲（像素域）

    // 提交侧（CSI 域）
    input  wire       I_ack_clk,
    input  wire       I_ack_rst_n,
    input  wire       I_frame_start,  // 相机帧首（ISP 输出 tuser）
    output reg  [7:0] O_committed,    // 已提交值（CSI 域）
    output reg        O_commit_pulse  // 提交 1 拍脉冲（CSI 域）
);

    // ---- 下行：请求侧每次发现值变了就发一次 --------------------------------
    reg [7:0] S_sent;
    wire      S_fwd_valid = (I_req_data != S_sent);

    always @(posedge I_req_clk or negedge I_req_rst_n) begin
        if(!I_req_rst_n)          S_sent <= 8'd0;
        else if(S_fwd_valid)      S_sent <= I_req_data;
    end

    wire [25:0] S_fwd_data;
    wire        S_fwd_rx_valid;

    ctrl_sync u_fwd (
        .I_tx_clk  (I_req_clk),
        .I_tx_rst_n(I_req_rst_n),
        .I_tx_valid(S_fwd_valid),
        .I_tx_data ({18'b0, I_req_data}),
        .I_rx_clk  (I_ack_clk),
        .I_rx_rst_n(I_ack_rst_n),
        .O_rx_data (S_fwd_data),
        .O_rx_valid(S_fwd_rx_valid)
    );

    // ---- 提交侧：挂起到帧首再生效 ------------------------------------------
    reg [7:0] S_pending;
    reg       S_pending_flag;

    // 提交那一拍：数据用 S_pending（组合给出，与 valid 同拍稳定），
    // 同时把 O_committed 更新成同一个值。
    wire       S_ack_tx_valid = I_frame_start & S_pending_flag;
    wire [7:0] S_ack_word     = S_pending;

    always @(posedge I_ack_clk or negedge I_ack_rst_n) begin
        if(!I_ack_rst_n) begin
            S_pending      <= 8'd0;
            S_pending_flag <= 1'b0;
            O_committed    <= 8'd0;
            O_commit_pulse <= 1'b0;
        end
        else begin
            O_commit_pulse <= 1'b0;

            if(S_fwd_rx_valid) begin
                S_pending      <= S_fwd_data[7:0];
                S_pending_flag <= 1'b1;
            end

            if(S_ack_tx_valid) begin
                O_committed    <= S_pending;
                O_commit_pulse <= 1'b1;
                S_pending_flag <= 1'b0;
            end
        end
    end

    // ---- 上行：把提交结果回送（像素域）-------------------------------------
    wire [25:0] S_echo_data;

    ctrl_sync u_echo (
        .I_tx_clk  (I_ack_clk),
        .I_tx_rst_n(I_ack_rst_n),
        .I_tx_valid(S_ack_tx_valid),
        .I_tx_data ({18'b0, S_ack_word}),
        .I_rx_clk  (I_req_clk),
        .I_rx_rst_n(I_req_rst_n),
        .O_rx_data (S_echo_data),
        .O_rx_valid(O_echo_valid)
    );

    assign O_echo_data = S_echo_data[7:0];

endmodule
