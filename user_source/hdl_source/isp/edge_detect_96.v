// ============================================================================
// edge_detect_96 —— 全分辨率 Sobel 边缘检测（M0 重构后只剩梯度级）
//
// 2026-09-14 模块重构：3x3 行缓存窗口生成器拆到 edge_win_3x3_96.v，本模块只保留
// Sobel 梯度与输出级，消费窗口而不是自己维护行缓存；形态学/掩码去噪以后复用那个
// 窗口模块。本模块的端口、延迟、输出格式都保持与拆分前逐拍一致，isp_top 的例化
// 不需要改动。
//
// 与官方 lab_ex2_edge 版本的区别（沿用拆分前的结论，细节见 README 第 4 节）：
//   1. 不再把同拍 4 个像素平均成一个 grp_gray 再做梯度。官方实际是在 1/4 宽度的
//      图上算梯度，宽度小于 4 像素的竖线会被 4 倍组平均压到阈值以下而完全消失；
//      本版为每个像素单独算 Sobel（4 路并行）。
//   2. 输出梯度灰度（门限以上保留灰阶），而不是硬二值化：I_thresh 只作噪声门限。
//   3. 三点多数滤波被移除（它会抹掉细笔画产生的孤立边缘像素）。
//   4. 灰度公式用官方 720P 例程的 R/4 + G/2 + B/4（在 edge_win_3x3_96 里）。
//
// 显示灰度 = clamp((|gx|+|gy|) << EDGE_GAIN_SHIFT)；干净阶跃边缘的 |gx|+|gy| = 4Δ。
// 门限决定"多弱才看得见"（TH=16 → Δ≥4 可见），增益决定"多强才全白"（增益 0 →
// Δ≥64 饱和，增益 1 → Δ≥32 就全白）。当前取 TH=16 + 增益 0，保留更多中间灰阶。
// 注意：换灰度公式并不放大 Δ，所以门限和增益不能按公式换算（TH48 那一版就是这么
// 踩的坑，弱边缘被整片拦掉）。
//
// 延迟：本模块 1 拍，加上窗口生成器共 2 拍（与拆分前一致）。
// 时钟域：ISP（CSI）像素域，单时钟，不跨域，不需要额外 SDC 约束。
// 资源：无 ERAM、无 DSP（三块行缓存在 edge_win_3x3_96 里）。
//
// 注意：输出 4 个像素对应的是列 4k-1..4k+2，因此整幅边缘图相对 RAW 左移 1 像素；
// O_tuser / O_tlast / O_tvalid 与数据严格对齐，下游 data_96bit_to_128bit 依赖这一点。
// ============================================================================
module edge_detect_96 #(
    parameter IMG_WIDTH  = 1280,
    parameter IMG_HEIGHT = 720,
    // 显示增益：显示灰度 = clamp((|gx|+|gy|) << EDGE_GAIN_SHIFT)。
    parameter integer EDGE_GAIN_SHIFT = 0
)(
    input               I_clk,
    input               I_rst_n,
    input               I_tlast,
    input               I_tuser,
    input      [95:0]   I_tdata,
    input               I_tvalid,
    input               I_tready,
    input      [10:0]   I_thresh,
    output reg          O_tlast,
    output reg          O_tuser,
    output reg [95:0]   O_tdata,
    output reg          O_tvalid,
    output              O_tready
);

assign O_tready = I_tready;

// ---- 第一级：3x3 行缓存窗口（灰度 + 逐像素平滑 + 行轮转）--------------------
wire [47:0] win_cur;   // 当前行 y  , 列 4k-2..4k+3
wire [47:0] win_mid;   // 第 y-1 行
wire [47:0] win_top;   // 第 y-2 行
wire [10:0] win_x;     // 列组号 k
wire [10:0] win_y;
wire        win_valid;
wire        win_user;
wire        win_last;

edge_win_3x3_96 #(
    .IMG_WIDTH (IMG_WIDTH),
    .IMG_HEIGHT(IMG_HEIGHT)
) u_edge_win_3x3_96 (
    .I_clk  (I_clk),
    .I_rst_n(I_rst_n),
    .I_tlast(I_tlast),
    .I_tuser(I_tuser),
    .I_tdata(I_tdata),
    .I_tvalid(I_tvalid),
    .O_cur  (win_cur),
    .O_mid  (win_mid),
    .O_top  (win_top),
    .O_x    (win_x),
    .O_y    (win_y),
    .O_valid(win_valid),
    .O_user (win_user),
    .O_last (win_last)
);

// ---- 第二级：Sobel 梯度 + 灰度输出 -----------------------------------------
// 窗口索引 0..5 对应列 4k-2..4k+3；输出像素 j 对应列 4k-1+j，使用索引 j/j+1/j+2
// （即它自己加左右邻域）。T = 第 y-2 行，M = 第 y-1 行，W = 当前行 y：
//   gx = (T2-T0) + 2*(M2-M0) + (W2-W0)
//   gy = (T0+2*T1+T2) - (W0+2*W1+W2)
reg signed [12:0] gx0, gx1, gx2, gx3;
reg signed [12:0] gy0, gy1, gy2, gy3;
reg [12:0] abs_x0, abs_x1, abs_x2, abs_x3;
reg [12:0] abs_y0, abs_y1, abs_y2, abs_y3;
reg [13:0] mag0, mag1, mag2, mag3;
reg [7:0]  out0, out1, out2, out3;

always @(posedge I_clk or negedge I_rst_n) begin
    if(!I_rst_n) begin
        O_tdata  <= 96'd0;
        O_tvalid <= 1'b0;
        O_tuser  <= 1'b0;
        O_tlast  <= 1'b0;
    end
    else begin
        O_tvalid <= win_valid;
        O_tuser  <= win_user;
        O_tlast  <= win_last;

        if((win_x >= 11'd2) && (win_y >= 11'd2)) begin
            // j=0 -> 列 4k-1，窗口索引 0,1,2
            gx0 = ($signed({1'b0,win_top[23:16]}) - $signed({1'b0,win_top[7:0]}))
                + (($signed({1'b0,win_mid[23:16]}) - $signed({1'b0,win_mid[7:0]})) <<< 1)
                + ($signed({1'b0,win_cur[23:16]}) - $signed({1'b0,win_cur[7:0]}));
            gy0 = ($signed({1'b0,win_top[7:0]}) + ($signed({1'b0,win_top[15:8]}) <<< 1)
                   + $signed({1'b0,win_top[23:16]}))
                - ($signed({1'b0,win_cur[7:0]}) + ($signed({1'b0,win_cur[15:8]}) <<< 1)
                   + $signed({1'b0,win_cur[23:16]}));

            // j=1 -> 列 4k，窗口索引 1,2,3
            gx1 = ($signed({1'b0,win_top[31:24]}) - $signed({1'b0,win_top[15:8]}))
                + (($signed({1'b0,win_mid[31:24]}) - $signed({1'b0,win_mid[15:8]})) <<< 1)
                + ($signed({1'b0,win_cur[31:24]}) - $signed({1'b0,win_cur[15:8]}));
            gy1 = ($signed({1'b0,win_top[15:8]}) + ($signed({1'b0,win_top[23:16]}) <<< 1)
                   + $signed({1'b0,win_top[31:24]}))
                - ($signed({1'b0,win_cur[15:8]}) + ($signed({1'b0,win_cur[23:16]}) <<< 1)
                   + $signed({1'b0,win_cur[31:24]}));

            // j=2 -> 列 4k+1，窗口索引 2,3,4
            gx2 = ($signed({1'b0,win_top[39:32]}) - $signed({1'b0,win_top[23:16]}))
                + (($signed({1'b0,win_mid[39:32]}) - $signed({1'b0,win_mid[23:16]})) <<< 1)
                + ($signed({1'b0,win_cur[39:32]}) - $signed({1'b0,win_cur[23:16]}));
            gy2 = ($signed({1'b0,win_top[23:16]}) + ($signed({1'b0,win_top[31:24]}) <<< 1)
                   + $signed({1'b0,win_top[39:32]}))
                - ($signed({1'b0,win_cur[23:16]}) + ($signed({1'b0,win_cur[31:24]}) <<< 1)
                   + $signed({1'b0,win_cur[39:32]}));

            // j=3 -> 列 4k+2，窗口索引 3,4,5
            gx3 = ($signed({1'b0,win_top[47:40]}) - $signed({1'b0,win_top[31:24]}))
                + (($signed({1'b0,win_mid[47:40]}) - $signed({1'b0,win_mid[31:24]})) <<< 1)
                + ($signed({1'b0,win_cur[47:40]}) - $signed({1'b0,win_cur[31:24]}));
            gy3 = ($signed({1'b0,win_top[31:24]}) + ($signed({1'b0,win_top[39:32]}) <<< 1)
                   + $signed({1'b0,win_top[47:40]}))
                - ($signed({1'b0,win_cur[31:24]}) + ($signed({1'b0,win_cur[39:32]}) <<< 1)
                   + $signed({1'b0,win_cur[47:40]}));

            abs_x0 = gx0[12] ? (~gx0 + 1'b1) : gx0;
            abs_y0 = gy0[12] ? (~gy0 + 1'b1) : gy0;
            mag0   = abs_x0 + abs_y0;
            abs_x1 = gx1[12] ? (~gx1 + 1'b1) : gx1;
            abs_y1 = gy1[12] ? (~gy1 + 1'b1) : gy1;
            mag1   = abs_x1 + abs_y1;
            abs_x2 = gx2[12] ? (~gx2 + 1'b1) : gx2;
            abs_y2 = gy2[12] ? (~gy2 + 1'b1) : gy2;
            mag2   = abs_x2 + abs_y2;
            abs_x3 = gx3[12] ? (~gx3 + 1'b1) : gx3;
            abs_y3 = gy3[12] ? (~gy3 + 1'b1) : gy3;
            mag3   = abs_x3 + abs_y3;
        end
        else begin
            mag0 = 14'd0;
            mag1 = 14'd0;
            mag2 = 14'd0;
            mag3 = 14'd0;
        end

        // 门限以下作为噪声压掉，门限以上保留梯度灰阶：弱边缘（细笔画）
        // 以中间灰度留下，不再被硬阈值直接抹平。
        out0 = (mag0 < I_thresh) ? 8'd0 :
               ((mag0 > (14'd255 >> EDGE_GAIN_SHIFT)) ? 8'd255 : (mag0[7:0] << EDGE_GAIN_SHIFT));
        out1 = (mag1 < I_thresh) ? 8'd0 :
               ((mag1 > (14'd255 >> EDGE_GAIN_SHIFT)) ? 8'd255 : (mag1[7:0] << EDGE_GAIN_SHIFT));
        out2 = (mag2 < I_thresh) ? 8'd0 :
               ((mag2 > (14'd255 >> EDGE_GAIN_SHIFT)) ? 8'd255 : (mag2[7:0] << EDGE_GAIN_SHIFT));
        out3 = (mag3 < I_thresh) ? 8'd0 :
               ((mag3 > (14'd255 >> EDGE_GAIN_SHIFT)) ? 8'd255 : (mag3[7:0] << EDGE_GAIN_SHIFT));

        if(win_valid)
            // out0 是最左的输出像素（列 4k-1），放在最高字段。
            O_tdata <= {{3{out0}}, {3{out1}}, {3{out2}}, {3{out3}}};
        else
            O_tdata <= 96'd0;
    end
end

endmodule
