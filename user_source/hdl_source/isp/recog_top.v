// ============================================================================
// recog_top —— 识别支路容器（VIDEO_TAP 插座的消费者，CSI 域）
//
// 取点位置：isp_top 内部、RAW/EDGE MUX **之前**——RAW 是 AWB 输出的彩色流，
// EDGE 是 edge_detect_96 的梯度流。EDGE 模式下彩色流依然存在，所以肤色/运动
// 掩码两种模式都能用（这是把取点放在 MUX 之前的原因）。
//
// M0 内容（只有地基，没有识别算法）：
//   * tap 监视：数每一帧的 tap 字数（像素数 = 字数×4），帧首锁存成 >>10 的输出，
//     1280x720 期望 0x0384 —— 用来证明抽头接的是完整的一帧；
//   * 掩码统计：掩码源先固定为"边缘非零"（M1 再接肤色/运动/融合），实例化
//     mask_stats，输出像素数 >>4 与包围盒（16 像素粒度）；
//   * CTRL_SYNC 上行端点：M0 把收到的下行字原样回传（往返自检），M1 换成真实
//     识别结果（质心/手型/事件）。
//
// 延迟：统计逻辑 0 拍，输出是帧锁存值；CTRL_SYNC 回传是组合直连。
// 时钟域：CSI 域单时钟，不跨域（到像素域的同步在 design_top_wrapper 里做）。
// 资源：约 150 FF + 100 LUT，无 ERAM / DSP。
// ============================================================================
module recog_top (
    input  wire        I_clk,
    input  wire        I_rst_n,

    // VIDEO_TAP：与 MUX 之前的流严格对齐
    input  wire [95:0] I_raw_tdata,
    input  wire        I_raw_tuser,
    input  wire        I_raw_tlast,
    input  wire        I_raw_tvalid,
    input  wire [95:0] I_edge_tdata,
    input  wire        I_edge_tuser,
    input  wire        I_edge_tlast,
    input  wire        I_edge_tvalid,

    // CTRL_SYNC（CSI 侧端点）：下行收到的字 + 上行要发的字
    input  wire [25:0] I_ctrl_rx_data,
    input  wire        I_ctrl_rx_valid,
    output wire [25:0] O_ctrl_tx_data,
    output wire        O_ctrl_tx_valid,

    // 观测输出（帧锁存，供 DBG 行；到像素域由顶层同步）
    output wire [15:0] O_tap_px_shift,    // 每帧 tap 像素数 >>10
    output wire [15:0] O_mask_cnt_shift,  // 掩码像素数 >>4
    output wire [15:0] O_bbox_x,          // {x_min/16[7:0], x_max/16[7:0]}
    output wire [15:0] O_bbox_y           // {y_min/16[7:0], y_max/16[7:0]}
);

    // ---- tap 监视：每帧字数 -------------------------------------------------
    reg [19:0] S_tap_cnt;
    reg [15:0] S_tap_hold;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_tap_cnt  <= 20'd0;
            S_tap_hold <= 16'd0;
        end
        else if(I_raw_tvalid) begin
            if(I_raw_tuser) begin
                // 帧首：锁存上一帧的字数。像素数 = 字数×4，所以
                // "像素数 >> 10" 就是 "字数 >> 8"（1280x720 → 230400 >> 8 = 900）。
                S_tap_hold <= S_tap_cnt >> 8;
                S_tap_cnt  <= 20'd1;
            end
            else if(S_tap_cnt != 20'hFFFFF)
                S_tap_cnt <= S_tap_cnt + 1'b1;
        end
    end

    assign O_tap_px_shift = S_tap_hold;

    // ---- 掩码统计器（M0 的掩码源固定为"边缘非零"）----------------------------
    // bit0 对应列 4k-1，也就是 96 位字的最高字段（out0），与 edge_detect_96 的
    // 输出几何一致。
    wire [3:0] S_edge_mask = {|I_edge_tdata[95:72], |I_edge_tdata[71:48],
                              |I_edge_tdata[47:24], |I_edge_tdata[23:0]};

    wire [19:0] S_mcnt;
    wire [10:0] S_xmin, S_xmax, S_ymin, S_ymax;
    wire [30:0] S_sumx;
    wire [29:0] S_sumy;
    wire        S_empty;

    mask_stats u_mask_stats (
        .I_clk  (I_clk),
        .I_rst_n(I_rst_n),
        .I_mask (S_edge_mask),
        .I_valid(I_edge_tvalid),
        .I_user (I_edge_tuser),
        .I_last (I_edge_tlast),
        .O_cnt  (S_mcnt),
        .O_xmin (S_xmin),
        .O_xmax (S_xmax),
        .O_ymin (S_ymin),
        .O_ymax (S_ymax),
        .O_sumx (S_sumx),
        .O_sumy (S_sumy),
        .O_empty(S_empty)
    );

    assign O_mask_cnt_shift = S_mcnt >> 4;
    assign O_bbox_x         = {1'b0, S_xmin[10:4], 1'b0, S_xmax[10:4]};
    assign O_bbox_y         = {1'b0, S_ymin[10:4], 1'b0, S_ymax[10:4]};

    // 说明：S_sumx / S_sumy / S_empty 在 M0 里没有消费者（会综合掉），M1 接质心与
    // 丢失判定时自然回来——接口先冻结，省得 M1 再改一次模块端口。

    // ---- CTRL_SYNC 上行：M0 原样回传收到的字（往返自检）-----------------------
    assign O_ctrl_tx_data  = I_ctrl_rx_data;
    assign O_ctrl_tx_valid = I_ctrl_rx_valid;

endmodule
