module isp_top #(
    // 边缘显示增益（显示灰度 = clamp((|gx|+|gy|) << shift)）。门限本身从 M0 起是
    // **运行时**的（I_edge_th，由像素域的模式寄存器在相机帧首提交过来），不再编译期
    // 写死。增益 0 让饱和点落在 Δ≈64；TH=16 对应"Δ≥4 灰阶就可见"。
    parameter integer EDGE_GAIN_SHIFT = 0,

    // 调试叠加开关：1 = 无条件把识别结果（掩码高亮/指针）画在 RAW 画面上，板上看效果用；
    // 0 = 正式行为，由 C 的 mode_word 决定（recog_algo[15:12]==1 即"手势"时才叠加）。
    parameter integer MASK_PREVIEW = 0,

    // 调试版模式选择（默认 0 = 交付行为）：
    //   1 = 用 C 的 recog_algo[15:12] 当"运行时视图号"，任一非 0 值都出叠加；
    //       串口 `W 08 000X` 实时切换，不用重编译（视图表见下面"叠加通路"一段）
    //   0 = 交付行为：只有 recog_algo==1 才叠加，与原来完全一致
    parameter integer DIAG_MODE_SEL = 0,

    // 彩色通路的**数字增益**（暗光应急用，不改 C 的 ae_set.v）：
    //   0 = 关闭；n = R/G/B 各左移 n 位并饱和钳到 255（0..3）。
    // 只作用在"彩色流"上（识别支路的 tap + RAW 显示），**不动边缘检测那条路**，
    // 所以 EDGE 画面的行为不变。注意：开启后一切基于绝对数值的颜色判据都要按新亮度重调。
    parameter integer DIG_GAIN_SHIFT = 0
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

    // ---- 叠加通路（使能取自 C 的 mode_word 契约，见 mode_sync.v）---------------
    // 布局：recog_algo = I_mode_committed[15:12]、game_mode = [11:8]（见 mode_sync.v 文件头）。
    // recog_algo 同时当**运行时视图号**（串口 `W 08 000X`，不用重编译）：
    //   0 = 原摄像头画面（不叠加）          1 = 融合掩码 + 准星（正常交付视图）
    //   2 = 背景帧预览（画面换成背景帧）    3 = AWB 之前视图
    //   4 = 只看运动门(绿)  5 = 只看肤色门(红)  6 = ROI 边框+融合  7 = 三色诊断
    // MASK_PREVIEW=1 时无条件叠加；DIAG_MODE_SEL=1 时任一非 0 视图号都叠加；
    // 正式交付两者都为 0 → 只有 recog_algo==1 才叠加。
    // 每像素 3 bit 色码（recog_top 的 O_ovl_sel 给）：
    //   0=原像素 1=掩码高亮(红) 2=准星(黄) 3=只过肤色(纯红) 4=只过运动(纯绿)
    //   5=两者都过(纯黄) 6=ROI 窗口边框(纯蓝) 7=准星(青)
    wire [11:0] S_ovl_sel;
    wire [7:0]  S_bg_px;                       // recog_top 给的"当前块背景灰度"
    wire [3:0]  S_dbg_mode = I_mode_committed[15:12];
    wire S_ovl_en = MASK_PREVIEW |
                    ((DIAG_MODE_SEL != 0) ? (S_dbg_mode != 4'd0) : (S_dbg_mode == 4'd1));
    wire S_bgview = (DIAG_MODE_SEL != 0) && (S_dbg_mode == 4'd2);

    function [23:0] F_ovl_pix;
        input [23:0] I_pix;
        input [2:0]  I_sel;
        begin
            case (I_sel)
                3'd1: F_ovl_pix = {8'hFF, I_pix[15:9], 1'b0, I_pix[7:1], 1'b0}; // 掩码：红拉满+G/B 减半
                3'd2: F_ovl_pix = 24'hFFFF00;   // 准星（黄）
                3'd3: F_ovl_pix = 24'hFF0000;   // 诊断：只过肤色
                3'd4: F_ovl_pix = 24'h00FF00;   // 诊断：只过运动
                3'd5: F_ovl_pix = 24'hFFFF00;   // 诊断：两者都过
                3'd6: F_ovl_pix = 24'h0000FF;   // 诊断：ROI 窗口边框
                3'd7: F_ovl_pix = 24'h00FFFF;   // 诊断：准星（青）
                default: F_ovl_pix = I_pix;
            endcase
        end
    endfunction

    // 背景帧预览：直接把背景灰度当像素显示（背景 ERAM 若是空的，这里就是整屏黑）
    function [23:0] F_preview_pix;
        input [23:0] I_pix;
        input [2:0]  I_sel;
        begin
            F_preview_pix = S_bgview ? {S_bg_px, S_bg_px, S_bg_px}
                                     : F_ovl_pix(I_pix, I_sel);
        end
    endfunction
    wire [95:0] S_preview_ovl = {
        F_preview_pix(S_awb_g[95:72], S_ovl_sel[11:9]),   // 字内最左像素
        F_preview_pix(S_awb_g[71:48], S_ovl_sel[8:6]),
        F_preview_pix(S_awb_g[47:24], S_ovl_sel[5:3]),
        F_preview_pix(S_awb_g[23:0],  S_ovl_sel[2:0])
    };

    // mode 3：直接看 **AWB 之前** 的画面（demosaic 直出、不做白平衡）——
    // 用来分辨"画面偏绿"是 AWB 增益的锅，还是 demosaic/Bayer 相位的锅。
    // 这一路的时间基准必须跟着 demosaic 流走（与叠加那一路不是同一拍）。
    // ---- 数字增益（DIG_GAIN_SHIFT）：单通道饱和左移 -------------------------
    function [7:0] F_sat_shl;
        input [7:0] I_v;
        reg [15:0]  S_t;
        begin
            S_t = I_v << DIG_GAIN_SHIFT;
            F_sat_shl = S_t[15:8] ? 8'hFF : S_t[7:0];
        end
    endfunction

    function [23:0] F_dig_gain_px;
        input [23:0] I_px;
        begin
            F_dig_gain_px = { F_sat_shl(I_px[23:16]), F_sat_shl(I_px[15:8]), F_sat_shl(I_px[7:0]) };
        end
    endfunction

    // 显示用的带增益彩色流：**只给显示/叠加**，识别支路（recog_top 的 tap）仍用原始 awb_O_tdata ——
    // 这样运动/肤色阈值保持原来的标定，不用因为改了亮度重标一遍。
    wire [95:0] S_awb_g = (DIG_GAIN_SHIFT == 0) ? awb_O_tdata :
                          { F_dig_gain_px(awb_O_tdata[95:72]), F_dig_gain_px(awb_O_tdata[71:48]),
                            F_dig_gain_px(awb_O_tdata[47:24]), F_dig_gain_px(awb_O_tdata[23:0]) };

    wire S_preawbview = (DIAG_MODE_SEL != 0) && (S_dbg_mode == 4'd3);
    wire [95:0] S_preview_tdata = S_preawbview ? m_aixs_tdata_96 : S_preview_ovl;
    wire        S_pre_vld = S_preawbview ? m_aixs_tvalid : awb_O_tvalid;
    wire        S_pre_lst = S_preawbview ? m_aixs_tlast  : awb_O_tlast;
    wire        S_pre_usr = S_preawbview ? m_aixs_tuser  : awb_O_tuser;

    // 叠加时时间基准锁在 RAW 流上（掩码就是在 RAW 上算的，同拍对齐）
    assign sel_tdata  = S_ovl_en ? S_preview_tdata : (I_alg_sel ? edge_O_tdata  : S_awb_g);
    assign sel_tvalid = S_ovl_en ? S_pre_vld       : (I_alg_sel ? edge_O_tvalid : awb_O_tvalid);
    assign sel_tlast  = S_ovl_en ? S_pre_lst       : (I_alg_sel ? edge_O_tlast  : awb_O_tlast);
    assign sel_tuser  = S_ovl_en ? S_pre_usr       : (I_alg_sel ? edge_O_tuser  : awb_O_tuser);

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
        .O_status_toggle (O_status_toggle),
        .O_ovl_sel       (S_ovl_sel),
        .O_bg_px         (S_bg_px)
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
