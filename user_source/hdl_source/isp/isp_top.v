module isp_top #(
    // 边缘显示门限（噪声门限）与显示增益。做成参数，后续可直接接运行时可写寄存器。
    // 灰阶公式换成 R/4+G/2+B/4（0..253）后，同一场景的梯度幅度比旧公式大 2~3 倍：
    // 门限同步放大到 48（保持原来约 Δ≥4 灰阶的噪声门），增益降回 0（保留 ×2 会让
    // Δ≥32 的普通边缘直接饱和成纯白，理由见 edge_detect_96.v 的参数注释）。
    parameter [10:0]  EDGE_TH         = 11'd48,
    parameter integer EDGE_GAIN_SHIFT = 0
)(
    input           axi4s_video_aclk,
    input           I_rst_n,
    input           I_alg_sel,
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
    output          O_edge_dbg_nonzero
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
        .I_thresh(EDGE_TH),
        .O_tlast (edge_O_tlast),
        .O_tuser (edge_O_tuser),
        .O_tdata (edge_O_tdata),
        .O_tvalid(edge_O_tvalid),
        .O_tready()
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
