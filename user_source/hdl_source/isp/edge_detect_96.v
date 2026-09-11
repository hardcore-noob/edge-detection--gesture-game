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
//   5. 梯度幅度的显示映射改用 √ 曲线查表（当前白点 K=512，Δ≈128 的阶跃边缘映射为
//      纯白），取代原来的线性 ×1/×2 —— 线性映射经显示器 gamma 折算后感知响应是
//      Δ^2.2，弱边缘看不见、强边缘一片纯白。表由 tools/gen_edge_lut.ps1 生成。
//
// 保持不变的：96 位接口与逐拍 4 像素的节奏、逐像素 [1 2 1]/4 平滑、Sobel 核、
// O_tuser/O_tlast/O_tvalid 与数据严格对齐（本版总延迟为 2 拍）。
// 注意：输出 4 个像素对应的是列 4k-1..4k+2，因此整幅边缘图相对 RAW 左移 1 像素。
// ============================================================================
module edge_detect_96 #(
    parameter IMG_WIDTH  = 1280,
    parameter IMG_HEIGHT = 720
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
// 显示映射：√ 曲线查表
//
// 输入 mag = |gx|+|gy|（干净阶跃边缘约等于 4*Δ，Δ 是两侧真实灰阶差），输出 8 位灰度：
//     code = clamp(round(255 * sqrt(mag / K)), 255)，当前白点 K = 512（Δ≈128 才纯白）
// K 是"多强的边缘算纯白"：K=512 → Δ≈128 纯白（当前，整幅比 K=256 暗一档）；
// K=256 → Δ≈64 纯白；K=128 更亮、但 Δ≥32 就过曝。经显示器 gamma（≈2.2）折算后
// 感知亮度 ≈ (mag/K)^1.1，所以即便 K=512，弱边缘（Δ≈8 时约 4.8% 白场亮度）也比
// 线性映射（同条件下 1%）亮得多。
// 表内容由 tools/gen_edge_lut.ps1 生成，换白点就重新生成一次。
// 索引取 mag[9:2]：mag 最大 4*253 = 1012，索引落在 0..253，量化步进 4 ≈ 1 个灰阶。
// ============================================================================
function [7:0] edge_curve;
    input [7:0] idx;
    begin
        case (idx)
            8'd0: edge_curve = 8'd0;
            8'd1: edge_curve = 8'd23;
            8'd2: edge_curve = 8'd32;
            8'd3: edge_curve = 8'd39;
            8'd4: edge_curve = 8'd45;
            8'd5: edge_curve = 8'd50;
            8'd6: edge_curve = 8'd55;
            8'd7: edge_curve = 8'd60;
            8'd8: edge_curve = 8'd64;
            8'd9: edge_curve = 8'd68;
            8'd10: edge_curve = 8'd71;
            8'd11: edge_curve = 8'd75;
            8'd12: edge_curve = 8'd78;
            8'd13: edge_curve = 8'd81;
            8'd14: edge_curve = 8'd84;
            8'd15: edge_curve = 8'd87;
            8'd16: edge_curve = 8'd90;
            8'd17: edge_curve = 8'd93;
            8'd18: edge_curve = 8'd96;
            8'd19: edge_curve = 8'd98;
            8'd20: edge_curve = 8'd101;
            8'd21: edge_curve = 8'd103;
            8'd22: edge_curve = 8'd106;
            8'd23: edge_curve = 8'd108;
            8'd24: edge_curve = 8'd110;
            8'd25: edge_curve = 8'd113;
            8'd26: edge_curve = 8'd115;
            8'd27: edge_curve = 8'd117;
            8'd28: edge_curve = 8'd119;
            8'd29: edge_curve = 8'd121;
            8'd30: edge_curve = 8'd123;
            8'd31: edge_curve = 8'd125;
            8'd32: edge_curve = 8'd128;
            8'd33: edge_curve = 8'd129;
            8'd34: edge_curve = 8'd131;
            8'd35: edge_curve = 8'd133;
            8'd36: edge_curve = 8'd135;
            8'd37: edge_curve = 8'd137;
            8'd38: edge_curve = 8'd139;
            8'd39: edge_curve = 8'd141;
            8'd40: edge_curve = 8'd143;
            8'd41: edge_curve = 8'd144;
            8'd42: edge_curve = 8'd146;
            8'd43: edge_curve = 8'd148;
            8'd44: edge_curve = 8'd150;
            8'd45: edge_curve = 8'd151;
            8'd46: edge_curve = 8'd153;
            8'd47: edge_curve = 8'd155;
            8'd48: edge_curve = 8'd156;
            8'd49: edge_curve = 8'd158;
            8'd50: edge_curve = 8'd159;
            8'd51: edge_curve = 8'd161;
            8'd52: edge_curve = 8'd163;
            8'd53: edge_curve = 8'd164;
            8'd54: edge_curve = 8'd166;
            8'd55: edge_curve = 8'd167;
            8'd56: edge_curve = 8'd169;
            8'd57: edge_curve = 8'd170;
            8'd58: edge_curve = 8'd172;
            8'd59: edge_curve = 8'd173;
            8'd60: edge_curve = 8'd175;
            8'd61: edge_curve = 8'd176;
            8'd62: edge_curve = 8'd177;
            8'd63: edge_curve = 8'd179;
            8'd64: edge_curve = 8'd180;
            8'd65: edge_curve = 8'd182;
            8'd66: edge_curve = 8'd183;
            8'd67: edge_curve = 8'd184;
            8'd68: edge_curve = 8'd186;
            8'd69: edge_curve = 8'd187;
            8'd70: edge_curve = 8'd189;
            8'd71: edge_curve = 8'd190;
            8'd72: edge_curve = 8'd191;
            8'd73: edge_curve = 8'd193;
            8'd74: edge_curve = 8'd194;
            8'd75: edge_curve = 8'd195;
            8'd76: edge_curve = 8'd196;
            8'd77: edge_curve = 8'd198;
            8'd78: edge_curve = 8'd199;
            8'd79: edge_curve = 8'd200;
            8'd80: edge_curve = 8'd202;
            8'd81: edge_curve = 8'd203;
            8'd82: edge_curve = 8'd204;
            8'd83: edge_curve = 8'd205;
            8'd84: edge_curve = 8'd207;
            8'd85: edge_curve = 8'd208;
            8'd86: edge_curve = 8'd209;
            8'd87: edge_curve = 8'd210;
            8'd88: edge_curve = 8'd211;
            8'd89: edge_curve = 8'd213;
            8'd90: edge_curve = 8'd214;
            8'd91: edge_curve = 8'd215;
            8'd92: edge_curve = 8'd216;
            8'd93: edge_curve = 8'd217;
            8'd94: edge_curve = 8'd219;
            8'd95: edge_curve = 8'd220;
            8'd96: edge_curve = 8'd221;
            8'd97: edge_curve = 8'd222;
            8'd98: edge_curve = 8'd223;
            8'd99: edge_curve = 8'd224;
            8'd100: edge_curve = 8'd225;
            8'd101: edge_curve = 8'd227;
            8'd102: edge_curve = 8'd228;
            8'd103: edge_curve = 8'd229;
            8'd104: edge_curve = 8'd230;
            8'd105: edge_curve = 8'd231;
            8'd106: edge_curve = 8'd232;
            8'd107: edge_curve = 8'd233;
            8'd108: edge_curve = 8'd234;
            8'd109: edge_curve = 8'd235;
            8'd110: edge_curve = 8'd236;
            8'd111: edge_curve = 8'd237;
            8'd112: edge_curve = 8'd239;
            8'd113: edge_curve = 8'd240;
            8'd114: edge_curve = 8'd241;
            8'd115: edge_curve = 8'd242;
            8'd116: edge_curve = 8'd243;
            8'd117: edge_curve = 8'd244;
            8'd118: edge_curve = 8'd245;
            8'd119: edge_curve = 8'd246;
            8'd120: edge_curve = 8'd247;
            8'd121: edge_curve = 8'd248;
            8'd122: edge_curve = 8'd249;
            8'd123: edge_curve = 8'd250;
            8'd124: edge_curve = 8'd251;
            8'd125: edge_curve = 8'd252;
            8'd126: edge_curve = 8'd253;
            8'd127: edge_curve = 8'd254;
            8'd128: edge_curve = 8'd255;
            8'd129: edge_curve = 8'd255;
            8'd130: edge_curve = 8'd255;
            8'd131: edge_curve = 8'd255;
            8'd132: edge_curve = 8'd255;
            8'd133: edge_curve = 8'd255;
            8'd134: edge_curve = 8'd255;
            8'd135: edge_curve = 8'd255;
            8'd136: edge_curve = 8'd255;
            8'd137: edge_curve = 8'd255;
            8'd138: edge_curve = 8'd255;
            8'd139: edge_curve = 8'd255;
            8'd140: edge_curve = 8'd255;
            8'd141: edge_curve = 8'd255;
            8'd142: edge_curve = 8'd255;
            8'd143: edge_curve = 8'd255;
            8'd144: edge_curve = 8'd255;
            8'd145: edge_curve = 8'd255;
            8'd146: edge_curve = 8'd255;
            8'd147: edge_curve = 8'd255;
            8'd148: edge_curve = 8'd255;
            8'd149: edge_curve = 8'd255;
            8'd150: edge_curve = 8'd255;
            8'd151: edge_curve = 8'd255;
            8'd152: edge_curve = 8'd255;
            8'd153: edge_curve = 8'd255;
            8'd154: edge_curve = 8'd255;
            8'd155: edge_curve = 8'd255;
            8'd156: edge_curve = 8'd255;
            8'd157: edge_curve = 8'd255;
            8'd158: edge_curve = 8'd255;
            8'd159: edge_curve = 8'd255;
            8'd160: edge_curve = 8'd255;
            8'd161: edge_curve = 8'd255;
            8'd162: edge_curve = 8'd255;
            8'd163: edge_curve = 8'd255;
            8'd164: edge_curve = 8'd255;
            8'd165: edge_curve = 8'd255;
            8'd166: edge_curve = 8'd255;
            8'd167: edge_curve = 8'd255;
            8'd168: edge_curve = 8'd255;
            8'd169: edge_curve = 8'd255;
            8'd170: edge_curve = 8'd255;
            8'd171: edge_curve = 8'd255;
            8'd172: edge_curve = 8'd255;
            8'd173: edge_curve = 8'd255;
            8'd174: edge_curve = 8'd255;
            8'd175: edge_curve = 8'd255;
            8'd176: edge_curve = 8'd255;
            8'd177: edge_curve = 8'd255;
            8'd178: edge_curve = 8'd255;
            8'd179: edge_curve = 8'd255;
            8'd180: edge_curve = 8'd255;
            8'd181: edge_curve = 8'd255;
            8'd182: edge_curve = 8'd255;
            8'd183: edge_curve = 8'd255;
            8'd184: edge_curve = 8'd255;
            8'd185: edge_curve = 8'd255;
            8'd186: edge_curve = 8'd255;
            8'd187: edge_curve = 8'd255;
            8'd188: edge_curve = 8'd255;
            8'd189: edge_curve = 8'd255;
            8'd190: edge_curve = 8'd255;
            8'd191: edge_curve = 8'd255;
            8'd192: edge_curve = 8'd255;
            8'd193: edge_curve = 8'd255;
            8'd194: edge_curve = 8'd255;
            8'd195: edge_curve = 8'd255;
            8'd196: edge_curve = 8'd255;
            8'd197: edge_curve = 8'd255;
            8'd198: edge_curve = 8'd255;
            8'd199: edge_curve = 8'd255;
            8'd200: edge_curve = 8'd255;
            8'd201: edge_curve = 8'd255;
            8'd202: edge_curve = 8'd255;
            8'd203: edge_curve = 8'd255;
            8'd204: edge_curve = 8'd255;
            8'd205: edge_curve = 8'd255;
            8'd206: edge_curve = 8'd255;
            8'd207: edge_curve = 8'd255;
            8'd208: edge_curve = 8'd255;
            8'd209: edge_curve = 8'd255;
            8'd210: edge_curve = 8'd255;
            8'd211: edge_curve = 8'd255;
            8'd212: edge_curve = 8'd255;
            8'd213: edge_curve = 8'd255;
            8'd214: edge_curve = 8'd255;
            8'd215: edge_curve = 8'd255;
            8'd216: edge_curve = 8'd255;
            8'd217: edge_curve = 8'd255;
            8'd218: edge_curve = 8'd255;
            8'd219: edge_curve = 8'd255;
            8'd220: edge_curve = 8'd255;
            8'd221: edge_curve = 8'd255;
            8'd222: edge_curve = 8'd255;
            8'd223: edge_curve = 8'd255;
            8'd224: edge_curve = 8'd255;
            8'd225: edge_curve = 8'd255;
            8'd226: edge_curve = 8'd255;
            8'd227: edge_curve = 8'd255;
            8'd228: edge_curve = 8'd255;
            8'd229: edge_curve = 8'd255;
            8'd230: edge_curve = 8'd255;
            8'd231: edge_curve = 8'd255;
            8'd232: edge_curve = 8'd255;
            8'd233: edge_curve = 8'd255;
            8'd234: edge_curve = 8'd255;
            8'd235: edge_curve = 8'd255;
            8'd236: edge_curve = 8'd255;
            8'd237: edge_curve = 8'd255;
            8'd238: edge_curve = 8'd255;
            8'd239: edge_curve = 8'd255;
            8'd240: edge_curve = 8'd255;
            8'd241: edge_curve = 8'd255;
            8'd242: edge_curve = 8'd255;
            8'd243: edge_curve = 8'd255;
            8'd244: edge_curve = 8'd255;
            8'd245: edge_curve = 8'd255;
            8'd246: edge_curve = 8'd255;
            8'd247: edge_curve = 8'd255;
            8'd248: edge_curve = 8'd255;
            8'd249: edge_curve = 8'd255;
            8'd250: edge_curve = 8'd255;
            8'd251: edge_curve = 8'd255;
            8'd252: edge_curve = 8'd255;
            8'd253: edge_curve = 8'd255;
            8'd254: edge_curve = 8'd255;
            8'd255: edge_curve = 8'd255;
            default: edge_curve = 8'd255;
        endcase
    end
endfunction

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

        // 门限以下作为噪声压掉；门限以上按 √ 曲线查表出灰度：弱边缘（细笔画）
        // 以中间灰度留下，强边缘到 Δ≈64 就纯白。
        out0 = (mag0 < I_thresh) ? 8'd0 : edge_curve(mag0[9:2]);
        out1 = (mag1 < I_thresh) ? 8'd0 : edge_curve(mag1[9:2]);
        out2 = (mag2 < I_thresh) ? 8'd0 : edge_curve(mag2[9:2]);
        out3 = (mag3 < I_thresh) ? 8'd0 : edge_curve(mag3[9:2]);

        if(valid_d1)
            // out0 是最左的输出像素（列 4k-1），放在最高字段。
            O_tdata <= {{3{out0}}, {3{out1}}, {3{out2}}, {3{out3}}};
        else
            O_tdata <= 96'd0;
    end
end

endmodule
