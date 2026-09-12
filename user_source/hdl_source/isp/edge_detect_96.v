// ============================================================================
// edge_detect_96 —— 全分辨率 Sobel 边缘检测
//
// 与官方 lab_ex2_edge 版本的区别：
//   1. 不再把同拍 4 个像素平均成一个 grp_gray 再做梯度。原先梯度实际是在
//      256x600 的图上算的，结果再复制回 4 个像素；宽度小于 4 像素的竖线会被
//      4 倍组平均压到阈值以下而完全消失。本版为每个像素单独算梯度。
//   2. 输出梯度灰度（门限以上保留灰阶），而不是硬二值化。
//   3. 三点多数滤波被移除（它会抹掉细笔画产生的孤立边缘像素）。
//   4. 灰度公式改用官方 720P 例程的 R/4 + G/2 + B/4（0..253，不回绕、不用除法），
//      取代旧的 (R+G+B)/3 —— 后者在 8 位表达式里先回绕，把全图亮度压到 0..85 并
//      产生约 85 为周期的锯齿，中亮部信号只剩真实值的 1/3 左右。
//
// 保持不变的：96 位接口与逐拍 4 像素的节奏、逐像素 [1 2 1]/4 平滑、Sobel 核、
// O_tuser/O_tlast/O_tvalid 与数据严格对齐（本版总延迟为 2 拍）。
// 注意：输出 4 个像素对应的是列 4k-1..4k+2，因此整幅边缘图相对 RAW 左移 1 像素。
// ============================================================================
module edge_detect_96 #(
    parameter IMG_WIDTH  = 1280,
    parameter IMG_HEIGHT = 720,
    // 显示增益：显示灰度 = clamp((|gx|+|gy|) << EDGE_GAIN_SHIFT)。
    // 干净阶跃边缘的 |gx|+|gy| = 4*Δ，Δ 是两侧的真实灰阶差。
    // 注意：换成 R/4+G/2+B/4 并不会放大 Δ —— 旧公式 (3g mod 256)/3 每段内的斜率
    // 也是 1，局部差分基本原样保留（实测 Δ=8 时 232/248 个相邻位置保留，其余是
    // 回绕产生的 ±78 假跳变）。所以增益和门限要按"想要什么显示响应"来选，不能按
    // 公式换算：门限决定可见门槛（TH=16 → Δ≥4 可见），增益决定饱和点（增益 0 →
    // Δ≥64 才全白，增益 1 → Δ≥32 就全白）。当前取增益 0，保留更多中间灰阶。
    // （旧的 A/B 结论——组平均会把边缘摊成 4 像素、笔画变粗——仍然成立。）
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

// 96 位字里的 4 个像素是同一行内相邻的 4 个像素，pix0 最左、pix3 最右。
// 依据：demosaic 的 rgb_data = {rgb_data3..rgb_data0} 里 rgb_data0 是最左像素，
// data128_96 把它映到 96 位的最高字段；下游 data_96bit_to_128bit 只按位拼接成
// MSB 先出的流，video_out 也按 MSB 先出还原屏幕像素（cnt=0 取 [127:104]）。
wire [23:0] pix0 = I_tdata[95:72];
wire [23:0] pix1 = I_tdata[71:48];
wire [23:0] pix2 = I_tdata[47:24];
wire [23:0] pix3 = I_tdata[23:0];

// 灰度：官方 720P 例程的低成本亮度近似 R/4 + G/2 + B/4（R、G、B 依次在
// pix[23:16]、pix[15:8]、pix[7:0]）。最大 63+127+63 = 253，既不回绕也不用除法。
// 旧的 (R+G+B)/3 在 8 位表达式里先回绕再除，全图亮度被压到 0..85：例如
// R=G=B=128 只剩 42、R=G=B=255 只剩 84，且每 85 级锯齿一次。
wire [7:0] gray0 = {2'b0,pix0[23:18]} + {1'b0,pix0[15:9]} + {2'b0,pix0[7:2]};
wire [7:0] gray1 = {2'b0,pix1[23:18]} + {1'b0,pix1[15:9]} + {2'b0,pix1[7:2]};
wire [7:0] gray2 = {2'b0,pix2[23:18]} + {1'b0,pix2[15:9]} + {2'b0,pix2[7:2]};
wire [7:0] gray3 = {2'b0,pix3[23:18]} + {1'b0,pix3[15:9]} + {2'b0,pix3[7:2]};

localparam IMG_WIDTH_GRP = (IMG_WIDTH >> 2);

// 三块行缓存按行轮转：某一行的数据只写其中一块，同时从另外两块读第 y-1、y-2 行。
// 每个周期每块要么读要么写，绝不读写同址；读地址已寄存 —— 这是 block RAM 的标准
// 模板。这一点是必须的：全分辨率下 3x256x48 位如果落成触发器，会直接把器件 FF
// 资源耗尽（实测布局器报 PHY-9002）。
// 每个条目保存同一行内 6 个平滑灰度，对应列 [4k-2 .. 4k+3]：低字节是最左列
// 4k-2，高字节是最右列 4k+3。存 6 列而不是 4 列，是为了读一次地址就拿到算 4 个
// 像素 Sobel 所需的完整左右邻域。
// 2026-09-12：三块行缓存改成显式例化 PH1P ERAM（见下方的 eram_spram 实例）——
// `(* ram_style = "block" *)` 这个属性 TD 不认，之前它们落成 1152 个 LUTRAM
// （面积表 u_edge_detect_96 的 dram lut = 1152、eram = 0）。读时序不变：
// 地址 x_grp 在当拍给出、数据下一拍有效，与原数组写法逐拍等价。

reg [10:0] x_grp;
reg [10:0] y_pos;
reg [1:0]  row_phase;   // 0/1/2 轮转：本行写入哪一块
reg [1:0]  row_phase_d1; // 上一拍的轮转相位，用来选"这一拍有效的 ERAM 读出数据"

// 逐像素水平平滑 s[n] = (g[n] + 2*g[n-1] + g[n-2]) / 4 的历史寄存器，
// 滤波器形状与官方实现一致，只是从"组平均域"搬到"逐像素域"。
reg [7:0] gray_h1;
reg [7:0] gray_h2;
reg [7:0] sm_h1;
reg [7:0] sm_h2;

// 当拍平滑结果与 6 列窗口：原来是 always 块里的变量（sm0..sm3、win_cur），现在
// 引成显式线网 —— ERAM 的写数据必须能在 always 块外看到（否则综合器把它当寄存器，
// 写数据会比写地址晚一拍，行缓存整体错 4 个像素）。
wire [7:0]  S_sm0 = ({2'b00, gray0} + ({2'b00, gray_h1} << 1) + {2'b00, gray_h2}) >> 2;
wire [7:0]  S_sm1 = ({2'b00, gray1} + ({2'b00, gray0}   << 1) + {2'b00, gray_h1}) >> 2;
wire [7:0]  S_sm2 = ({2'b00, gray2} + ({2'b00, gray1}   << 1) + {2'b00, gray0})   >> 2;
wire [7:0]  S_sm3 = ({2'b00, gray3} + ({2'b00, gray2}   << 1) + {2'b00, gray1})   >> 2;
wire [47:0] S_win_cur = {S_sm3, S_sm2, S_sm1, S_sm0, sm_h1, sm_h2};

// ---- 行缓存：3 块 PH1P ERAM（每块 320 x 48 位，1 拍读延迟）------------------
// 每拍每块要么读要么写（行轮转保证），所以单口（MODE="SP"）就够；
// 写的那一块读出来没有意义，读侧选择用上一拍的相位（见 mid_r/top_r）。
wire [47:0] S_mem0_q, S_mem1_q, S_mem2_q;
// 写使能带上 I_rst_n：原实现的写操作在 always 块的"非复位"分支里，复位期间不写。
wire        S_we0 = I_rst_n && I_tvalid && (row_phase == 2'd0);
wire        S_we1 = I_rst_n && I_tvalid && (row_phase == 2'd1);
wire        S_we2 = I_rst_n && I_tvalid && (row_phase == 2'd2);

eram_spram #(.DATA_WIDTH(48), .ADDR_WIDTH(9)) u_line_mem0 (
    .I_clk(I_clk), .I_we(S_we0), .I_addr(x_grp[8:0]), .I_wdata(S_win_cur), .O_rdata(S_mem0_q));
eram_spram #(.DATA_WIDTH(48), .ADDR_WIDTH(9)) u_line_mem1 (
    .I_clk(I_clk), .I_we(S_we1), .I_addr(x_grp[8:0]), .I_wdata(S_win_cur), .O_rdata(S_mem1_q));
eram_spram #(.DATA_WIDTH(48), .ADDR_WIDTH(9)) u_line_mem2 (
    .I_clk(I_clk), .I_we(S_we2), .I_addr(x_grp[8:0]), .I_wdata(S_win_cur), .O_rdata(S_mem2_q));

// 读出的三块里取"第 y-1 行"和"第 y-2 行"：地址在上一拍给出，所以相位也要用上一拍的。
wire [47:0] mid_r = (row_phase_d1 == 2'd0) ? S_mem2_q :
                    (row_phase_d1 == 2'd1) ? S_mem0_q : S_mem1_q;
wire [47:0] top_r = (row_phase_d1 == 2'd0) ? S_mem1_q :
                    (row_phase_d1 == 2'd1) ? S_mem2_q : S_mem0_q;

// ---- 流水第一级输出：与行缓存读数据对齐 ----
reg [47:0] cur_r;   // 当前行 y  , 列 4k-2..4k+3
reg [10:0] x_r;
reg [10:0] y_r;
reg        valid_d1;
reg        user_d1;
reg        last_d1;

// ---- 流水第二级：Sobel + 输出 ----
reg signed [12:0] gx0, gx1, gx2, gx3;
reg signed [12:0] gy0, gy1, gy2, gy3;
reg [12:0] abs_x0, abs_x1, abs_x2, abs_x3;
reg [12:0] abs_y0, abs_y1, abs_y2, abs_y3;
reg [13:0] mag0, mag1, mag2, mag3;
reg [7:0]  out0, out1, out2, out3;

always @(posedge I_clk or negedge I_rst_n) begin
    if(!I_rst_n) begin
        x_grp <= 11'd0;
        y_pos <= 11'd0;
        row_phase <= 2'd0;
        row_phase_d1 <= 2'd0;
        gray_h1 = 8'd0;
        gray_h2 = 8'd0;
        sm_h1 = 8'd0;
        sm_h2 = 8'd0;
        cur_r <= 48'd0;
        x_r   <= 11'd0;
        y_r   <= 11'd0;
        valid_d1 <= 1'b0;
        user_d1  <= 1'b0;
        last_d1  <= 1'b0;
    end
    else begin
        // 与 ERAM 读出数据对齐：这一拍有效的 doa 对应上一拍给出的地址，
        // 所以读侧选择（mid_r/top_r）要用上一拍的轮转相位。
        // 消隐期 x_grp 不变，读出的数据不会被使用。
        row_phase_d1 <= row_phase;

        valid_d1 <= I_tvalid;
        user_d1  <= I_tuser;
        last_d1  <= I_tlast;

        if(I_tvalid) begin
            if(I_tuser) begin
                x_grp <= 11'd0;
                y_pos <= 11'd0;
                row_phase <= 2'd0;
                gray_h1 = 8'd0;
                gray_h2 = 8'd0;
                sm_h1 = 8'd0;
                sm_h2 = 8'd0;
            end

            // 逐像素 [1 2 1]/4 平滑的当拍结果在 S_sm0..S_sm3（文件上部的显式线网，
            // 那里做了 10 位扩展避免 8 位回绕）。这里只更新历史寄存器。
            gray_h2 = gray2;
            gray_h1 = gray3;
            sm_h2 = S_sm2;
            sm_h1 = S_sm3;

            // 写行缓存由 S_we0/1/2 驱动（见上面的 eram_spram 实例），写数据与写地址
            // 都取自当拍：地址 x_grp、数据 S_win_cur（6 列窗口）。
            cur_r <= S_win_cur;
            x_r   <= x_grp;
            y_r   <= y_pos;

            if(x_grp == IMG_WIDTH_GRP - 1) begin
                x_grp <= 11'd0;
                if(y_pos == IMG_HEIGHT - 1)
                    y_pos <= 11'd0;
                else
                    y_pos <= y_pos + 1'b1;

                row_phase <= (row_phase == 2'd2) ? 2'd0 : (row_phase + 2'd1);

                gray_h1 = 8'd0;
                gray_h2 = 8'd0;
                sm_h1 = 8'd0;
                sm_h2 = 8'd0;
            end
            else begin
                x_grp <= x_grp + 1'b1;
            end
        end
    end
end

// ============================================================================
// 第二级：Sobel 梯度 + 灰度输出
//
// 窗口索引 0..5 对应列 4k-2..4k+3；输出像素 j 对应列 4k-1+j，使用索引 j/j+1/j+2
// （即它自己加左右邻域）。T = 第 y-2 行，M = 第 y-1 行，W = 当前行 y：
//   gx = (T2-T0) + 2*(M2-M0) + (W2-W0)
//   gy = (T0+2*T1+T2) - (W0+2*W1+W2)
// ============================================================================
always @(posedge I_clk or negedge I_rst_n) begin
    if(!I_rst_n) begin
        O_tdata  <= 96'd0;
        O_tvalid <= 1'b0;
        O_tuser  <= 1'b0;
        O_tlast  <= 1'b0;
    end
    else begin
        O_tvalid <= valid_d1;
        O_tuser  <= user_d1;
        O_tlast  <= last_d1;

        if((x_r >= 11'd2) && (y_r >= 11'd2)) begin
            // j=0 -> 列 4k-1，窗口索引 0,1,2
            gx0 = ($signed({1'b0,top_r[23:16]}) - $signed({1'b0,top_r[7:0]}))
                + (($signed({1'b0,mid_r[23:16]}) - $signed({1'b0,mid_r[7:0]})) <<< 1)
                + ($signed({1'b0,cur_r[23:16]}) - $signed({1'b0,cur_r[7:0]}));
            gy0 = ($signed({1'b0,top_r[7:0]}) + ($signed({1'b0,top_r[15:8]}) <<< 1)
                   + $signed({1'b0,top_r[23:16]}))
                - ($signed({1'b0,cur_r[7:0]}) + ($signed({1'b0,cur_r[15:8]}) <<< 1)
                   + $signed({1'b0,cur_r[23:16]}));

            // j=1 -> 列 4k，窗口索引 1,2,3
            gx1 = ($signed({1'b0,top_r[31:24]}) - $signed({1'b0,top_r[15:8]}))
                + (($signed({1'b0,mid_r[31:24]}) - $signed({1'b0,mid_r[15:8]})) <<< 1)
                + ($signed({1'b0,cur_r[31:24]}) - $signed({1'b0,cur_r[15:8]}));
            gy1 = ($signed({1'b0,top_r[15:8]}) + ($signed({1'b0,top_r[23:16]}) <<< 1)
                   + $signed({1'b0,top_r[31:24]}))
                - ($signed({1'b0,cur_r[15:8]}) + ($signed({1'b0,cur_r[23:16]}) <<< 1)
                   + $signed({1'b0,cur_r[31:24]}));

            // j=2 -> 列 4k+1，窗口索引 2,3,4
            gx2 = ($signed({1'b0,top_r[39:32]}) - $signed({1'b0,top_r[23:16]}))
                + (($signed({1'b0,mid_r[39:32]}) - $signed({1'b0,mid_r[23:16]})) <<< 1)
                + ($signed({1'b0,cur_r[39:32]}) - $signed({1'b0,cur_r[23:16]}));
            gy2 = ($signed({1'b0,top_r[23:16]}) + ($signed({1'b0,top_r[31:24]}) <<< 1)
                   + $signed({1'b0,top_r[39:32]}))
                - ($signed({1'b0,cur_r[23:16]}) + ($signed({1'b0,cur_r[31:24]}) <<< 1)
                   + $signed({1'b0,cur_r[39:32]}));

            // j=3 -> 列 4k+2，窗口索引 3,4,5
            gx3 = ($signed({1'b0,top_r[47:40]}) - $signed({1'b0,top_r[31:24]}))
                + (($signed({1'b0,mid_r[47:40]}) - $signed({1'b0,mid_r[31:24]})) <<< 1)
                + ($signed({1'b0,cur_r[47:40]}) - $signed({1'b0,cur_r[31:24]}));
            gy3 = ($signed({1'b0,top_r[31:24]}) + ($signed({1'b0,top_r[39:32]}) <<< 1)
                   + $signed({1'b0,top_r[47:40]}))
                - ($signed({1'b0,cur_r[31:24]}) + ($signed({1'b0,cur_r[39:32]}) <<< 1)
                   + $signed({1'b0,cur_r[47:40]}));

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

        if(valid_d1)
            // out0 是最左的输出像素（列 4k-1），放在最高字段。
            O_tdata <= {{3{out0}}, {3{out1}}, {3{out2}}, {3{out3}}};
        else
            O_tdata <= 96'd0;
    end
end

endmodule
