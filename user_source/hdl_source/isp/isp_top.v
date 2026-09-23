module isp_top #(
    // 边缘显示增益（显示灰度 = clamp((|gx|+|gy|) << shift)）。门限本身从 M0 起是
    // **运行时**的（I_edge_th，由像素域的模式寄存器在相机帧首提交过来），不再编译期
    // 写死。增益 0 让饱和点落在 Δ≈64；TH=16 对应"Δ≥4 灰阶就可见"。
    parameter integer EDGE_GAIN_SHIFT = 0
)(
    input           axi4s_video_aclk,
    input           I_rst_n,
    input           I_alg_sel,
    input  [10:0]   I_edge_th,
    input  [25:0]   I_mode_committed,   // mode_sync 的提交字（CSI 域）：透传给 recog_top（M1 用它选算法）
    input           I_tlast,
    input           I_tuser,
    input  [39:0]   I_tdata,
    input           I_tvalid,
    input  [9:0]    I_tdest,
    input           O_tready,
    output [127:0]  O_tdata,
    output          O_tlast,
    output          O_tuser,
    output          O_tvalid,
    output          I_tready,
    output          O_edge_dbg_valid,
    output          O_edge_dbg_nonzero,

    // VIDEO_TAP（M0 新增）：识别支路取点就在本模块内部、RAW/EDGE MUX 之前，
    // 这样 EDGE 模式下彩色流依然存在（肤色的 Plan B 要用），而且不用把 96 位流
    // 拉到顶层（feedthrough 已经很紧）。对外只引出小宽度的观测与 CTRL_SYNC 端点。
    input  [25:0]   I_ctrl_rx_data,
    input           I_ctrl_rx_valid,
    output [25:0]   O_ctrl_tx_data,
    output          O_ctrl_tx_valid,
    output [11:0]   O_tap_px_shift,
    output [15:0]   O_mask_cnt_shift,
    output [13:0]   O_bbox_x,
    output [11:0]   O_bbox_y,
    output          O_status_toggle
);

    // Algorithm selection: 0 = RAW (AWB output), 1 = EDGE (edge_detect_96 output).
    // I_alg_sel 已在顶层做跨时钟域同步（稳定电平），直接驱动 MUX。
    // 切换瞬间当前写入帧可能撕裂，下一帧即恢复正常。

    wire         m_aixs_tvalid;  //synthesis keep
    wire [127:0] m_aixs_tdata;  //synthesis keep
    wire         m_aixs_tuser;  //synthesis keep
    wire         m_aixs_tlast;  //synthesis keep
    wire         m_aixs_tready;  //synthesis keep

    wire [ 95:0] m_aixs_tdata_96;  //synthesis keep

    wire         awb_O_tlast;  //synthesis keep
    wire         awb_O_tuser;  //synthesis keep
    wire [ 95:0] awb_O_tdata;  //synthesis keep
    wire         awb_O_tvalid;  //synthesis keep

    wire         awb_O_tuser_128;  //synthesis keep
    wire         awb_O_tvalid_128;  //synthesis keep
    wire [127:0] awb_O_tdata_128;  //synthesis keep
    wire         awb_O_tlast_128;  //synthesis keep

    wire         edge_O_tlast;  //synthesis keep
    wire         edge_O_tuser;  //synthesis keep
    wire [ 95:0] edge_O_tdata;  //synthesis keep
    wire         edge_O_tvalid;  //synthesis keep

    // Stream selected by S_alg_sel and sent to data_96bit_to_128bit
    wire         sel_tlast;
    wire         sel_tuser;
    wire [ 95:0] sel_tdata;
    wire         sel_tvalid;

    assign sel_tdata  = I_alg_sel ? edge_O_tdata  : awb_O_tdata;
    assign sel_tvalid = I_alg_sel ? edge_O_tvalid : awb_O_tvalid;
    assign sel_tlast  = I_alg_sel ? edge_O_tlast  : awb_O_tlast;
    assign sel_tuser  = I_alg_sel ? edge_O_tuser  : awb_O_tuser;

    // 下游 data_96bit_to_128bit 无反压，awb/edge 的输入 ready 直接接 1；
    // 它们的输出 ready（模块内部为直通）悬空不接，避免组合环路。
    assign O_tdata  = awb_O_tdata_128;
    assign O_tlast  = awb_O_tlast_128;
    assign O_tuser  = awb_O_tuser_128;
    assign O_tvalid = awb_O_tvalid_128;
    assign O_edge_dbg_valid = edge_O_tvalid;
    assign O_edge_dbg_nonzero = |edge_O_tdata;

    //assign m_aixs_tready = O_tready;
    //assign O_tdata  = m_aixs_tdata;
    //assign O_tlast  = m_aixs_tlast;
    //assign O_tuser  = m_aixs_tuser;
    //assign O_tvalid = m_aixs_tvalid;

    demosaic #(
        .IMG_HEIGHT          (720),  // 图像高度
        .IMG_WIDTH           (1280),   // 图像宽度
        .data_complete_delay (50  ),
        .BAYER_MODE          ("BGGR")
    )
    u_demosaic
    (
        .I_clk              (axi4s_video_aclk),
        .I_rst_n            (I_rst_n),
        .axi4s_video_tdata  (I_tdata),
        .axi4s_video_tdest  (I_tdest),
        .axi4s_video_tlast  (I_tlast),
        .axi4s_video_tvalid (I_tvalid),
        .axi4s_video_tuser  (I_tuser),
        .axi4s_video_tready (I_tready),
        .O_tlast            (m_aixs_tlast),
        .O_tuser            (m_aixs_tuser),
        .O_tdata            (m_aixs_tdata),
        .O_tvalid           (m_aixs_tvalid),
        .O_tready           (m_aixs_tready)
    );

    data128_96 u_data128_96 (
        .I_tdata(m_aixs_tdata),
        .O_tdata(m_aixs_tdata_96)
    );

    awb #(
        .IMG_HEIGHT(720),
        .IMG_WIDTH (1280)
    ) u_awb (
        .I_clk   (axi4s_video_aclk),
        .I_rst_n (I_rst_n),
        .I_tlast (m_aixs_tlast),
        .I_tuser (m_aixs_tuser),
        .I_tdata (m_aixs_tdata_96),
        .I_tvalid(m_aixs_tvalid),
        .I_tready(),
        .O_tlast (awb_O_tlast),
        .O_tuser (awb_O_tuser),
        .O_tdata (awb_O_tdata),
        .O_tvalid(awb_O_tvalid),
        .O_tready(1'b1)
    );

    edge_detect_96 #(
        .IMG_WIDTH (1280),
        .IMG_HEIGHT(720),
        .EDGE_GAIN_SHIFT(EDGE_GAIN_SHIFT)
    ) u_edge_detect_96 (
        .I_clk   (axi4s_video_aclk),
        .I_rst_n (I_rst_n),
        .I_tlast (awb_O_tlast),
        .I_tuser (awb_O_tuser),
        .I_tdata (awb_O_tdata),
        .I_tvalid(awb_O_tvalid),
        .I_tready(1'b1),
        .I_thresh(I_edge_th),
        .O_tlast (edge_O_tlast),
        .O_tuser (edge_O_tuser),
        .O_tdata (edge_O_tdata),
        .O_tvalid(edge_O_tvalid),
        .O_tready()
    );

    // ---- 识别支路（M0：tap 监视 + 掩码统计 + CTRL_SYNC 端点）------------------
    // 取点：AWB 输出的彩色 RAW 流与边缘流，都在上面的 MUX 之前。
    recog_top u_recog_top (
        .I_clk           (axi4s_video_aclk),
        .I_rst_n         (I_rst_n),
        .I_raw_tdata     (awb_O_tdata),
        .I_raw_tuser     (awb_O_tuser),
        .I_raw_tlast     (awb_O_tlast),
        .I_raw_tvalid    (awb_O_tvalid),
        .I_edge_tdata    (edge_O_tdata),
        .I_edge_tuser    (edge_O_tuser),
        .I_edge_tlast    (edge_O_tlast),
        .I_edge_tvalid   (edge_O_tvalid),
        .I_mode_word     (I_mode_committed),
        .I_ctrl_rx_data  (I_ctrl_rx_data),
        .I_ctrl_rx_valid (I_ctrl_rx_valid),
        .O_ctrl_tx_data  (O_ctrl_tx_data),
        .O_ctrl_tx_valid (O_ctrl_tx_valid),
        .O_tap_px_shift  (O_tap_px_shift),
        .O_mask_cnt_shift(O_mask_cnt_shift),
        .O_bbox_x        (O_bbox_x),
        .O_bbox_y        (O_bbox_y),
        .O_status_toggle (O_status_toggle)
    );

    data_96bit_to_128bit u_data_96bit_to_128bit(
        .I_clk              ( axi4s_video_aclk  ),
        .I_rst_n            ( I_rst_n           ),

        .I_96b_frame_start  ( sel_tuser         ),
        .I_96b_valid        ( sel_tvalid        ),
        .I_96b_data         ( sel_tdata         ),
        .I_96b_tlast        ( sel_tlast         ),

        .O_128b_frame_start ( awb_O_tuser_128   ),
        .O_128b_valid       ( awb_O_tvalid_128  ),
        .O_128b_data        ( awb_O_tdata_128   ),
        .O_128b_tlast       ( awb_O_tlast_128   )
    );

    //data96_128 u_data96_128 (
    //    .I_tdata(awb_O_tdata),
    //    .O_tdata(awb_O_tdata_128)
    //);

endmodule
