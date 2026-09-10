// ============================================================================
// edge_detect_96 —— 全分辨率 Sobel 边缘检测
//
// 与官方 lab_ex2_edge 版本的区别：
//   1. 不再把同拍 4 个像素平均成一个 grp_gray 再做梯度。原先梯度实际是在
//      256x600 的图上算的，结果再复制回 4 个像素；宽度小于 4 像素的竖线会被
//      4 倍组平均压到阈值以下而完全消失。本版为每个像素单独算梯度。
//   2. 输出梯度灰度（门限以上保留灰阶），而不是硬二值化。
//   3. 三点多数滤波被移除（它会抹掉细笔画产生的孤立边缘像素）。
//
// 保持不变的：96 位接口与逐拍 4 像素的节奏、逐像素 [1 2 1]/4 平滑、Sobel 核、
// O_tuser/O_tlast/O_tvalid 与数据严格对齐（本版总延迟为 2 拍）。
// 注意：输出 4 个像素对应的是列 4k-1..4k+2，因此整幅边缘图相对 RAW 左移 1 像素。
// ============================================================================
module edge_detect_96 #(
    parameter IMG_WIDTH  = 1280,
    parameter IMG_HEIGHT = 720,
    // 显示增益：显示灰度 = clamp((|gx|+|gy|) << EDGE_GAIN_SHIFT)。
    // 上板 A/B 结论：第一步（组平均 + 增益 2）与第二步（全分辨率 + 增益 0）的明暗
    // 肉眼分辨不出，说明真实笔画宽度多落在 3 像素以上、两版都已接近饱和；但第一步
    // 的笔画明显更粗（那是组平均把边缘摊成 4 像素的副作用）。因此保留全分辨率几何，
    // 把增益调回 1，让通过门限的弱边缘也提亮一档。
    parameter integer EDGE_GAIN_SHIFT = 1
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

// 官方灰度公式原样保留（R+G+B 在 8 位表达式里回绕后再除以 3，全图亮度被压缩在
// 0..85）。这一步没有改数值行为，只改了后面怎么用它。
wire [7:0] gray0 = (pix0[23:16] + pix0[15:8] + pix0[7:0]) / 8'd3;
wire [7:0] gray1 = (pix1[23:16] + pix1[15:8] + pix1[7:0]) / 8'd3;
wire [7:0] gray2 = (pix2[23:16] + pix2[15:8] + pix2[7:0]) / 8'd3;
wire [7:0] gray3 = (pix3[23:16] + pix3[15:8] + pix3[7:0]) / 8'd3;

localparam IMG_WIDTH_GRP = (IMG_WIDTH >> 2);

// 三块行缓存按行轮转：某一行的数据只写其中一块，同时从另外两块读第 y-1、y-2 行。
// 每个周期每块要么读要么写，绝不读写同址；读地址已寄存 —— 这是 block RAM 的标准
// 模板。这一点是必须的：全分辨率下 3x256x48 位如果落成触发器，会直接把器件 FF
// 资源耗尽（实测布局器报 PHY-9002）。
// 每个条目保存同一行内 6 个平滑灰度，对应列 [4k-2 .. 4k+3]：低字节是最左列
// 4k-2，高字节是最右列 4k+3。存 6 列而不是 4 列，是为了读一次地址就拿到算 4 个
// 像素 Sobel 所需的完整左右邻域。
(* ram_style = "block" *) reg [47:0] line_mem0 [0:IMG_WIDTH_GRP-1];
(* ram_style = "block" *) reg [47:0] line_mem1 [0:IMG_WIDTH_GRP-1];
(* ram_style = "block" *) reg [47:0] line_mem2 [0:IMG_WIDTH_GRP-1];

reg [10:0] x_grp;
reg [10:0] y_pos;
reg [1:0]  row_phase;   // 0/1/2 轮转：本行写入哪一块

// 逐像素水平平滑 s[n] = (g[n] + 2*g[n-1] + g[n-2]) / 4 的历史寄存器，
// 滤波器形状与官方实现一致，只是从"组平均域"搬到"逐像素域"。
reg [7:0] gray_h1;
reg [7:0] gray_h2;
reg [7:0] sm_h1;
reg [7:0] sm_h2;
reg [7:0] sm0, sm1, sm2, sm3;
reg [47:0] win_cur;

// ---- 流水第一级输出：与行缓存读数据对齐 ----
reg [47:0] cur_r;   // 当前行 y  , 列 4k-2..4k+3
reg [47:0] mid_r;   // 第 y-1 行
reg [47:0] top_r;   // 第 y-2 行
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
        gray_h1 = 8'd0;
        gray_h2 = 8'd0;
        sm_h1 = 8'd0;
        sm_h2 = 8'd0;
        sm0 = 8'd0; sm1 = 8'd0; sm2 = 8'd0; sm3 = 8'd0;
        win_cur = 48'd0;
        cur_r <= 48'd0;
        mid_r <= 48'd0;
        top_r <= 48'd0;
        x_r   <= 11'd0;
        y_r   <= 11'd0;
        valid_d1 <= 1'b0;
        user_d1  <= 1'b0;
        last_d1  <= 1'b0;
    end
    else begin
        // 行缓存读（地址寄存）。消隐期 x_grp 不变，读出的数据不会被使用。
        case(row_phase)
            2'd0: begin mid_r <= line_mem2[x_grp]; top_r <= line_mem1[x_grp]; end
            2'd1: begin mid_r <= line_mem0[x_grp]; top_r <= line_mem2[x_grp]; end
            default: begin mid_r <= line_mem1[x_grp]; top_r <= line_mem0[x_grp]; end
        endcase

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

            // 逐像素 [1 2 1]/4 平滑。这里必须显式扩展到 10 位再做加法，
            // 否则 8 位表达式会回绕（与官方灰度公式同一类问题）。
            sm0 = ({2'b00, gray0} + ({2'b00, gray_h1} << 1) + {2'b00, gray_h2}) >> 2;
            sm1 = ({2'b00, gray1} + ({2'b00, gray0}   << 1) + {2'b00, gray_h1}) >> 2;
            sm2 = ({2'b00, gray2} + ({2'b00, gray1}   << 1) + {2'b00, gray0})   >> 2;
            sm3 = ({2'b00, gray3} + ({2'b00, gray2}   << 1) + {2'b00, gray1})   >> 2;
            gray_h2 = gray2;
            gray_h1 = gray3;

            // 当前行在这个组上的 6 列窗口（列 4k-2 .. 4k+3）
            win_cur = {sm3, sm2, sm1, sm0, sm_h1, sm_h2};
            sm_h2 = sm2;
            sm_h1 = sm3;

            // 写入本行的行缓存（与上面读的另外两块不同块，不会读写同址）
            case(row_phase)
                2'd0: line_mem0[x_grp] <= win_cur;
                2'd1: line_mem1[x_grp] <= win_cur;
                default: line_mem2[x_grp] <= win_cur;
            endcase

            cur_r <= win_cur;
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
