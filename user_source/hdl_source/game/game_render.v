// ============================================================================
// game_render —— 逐像素判属与图层 mux（像素域，**对外 0 拍**）
//
// 判属顺序（上 → 下，先命中者赢）：
//   分数数字 > 生命块 > 刀光拖尾 > 粒子 > 对象表（水果 / 半片 / 方块）
// 对象表内部按槽位号优先（0 最高），"一个像素只归一个对象"（规划 §4.4 第 4 条）。
//
// **前视一拍（本模块的灵魂，别照抄 hdmi_mixer 的 x_1d 套路）**：
//   本拍用 `I_x_nxt/I_y_nxt`（下一个 de 像素的坐标）算判属，结果寄存一拍；
//   下一拍正是那个像素到达的时候，于是：
//     * 对外仍然是 0 拍——`O_pixel_out = O_hit ? O_color : I_pixel_in` 与输入同拍；
//     * 精灵 ERAM 的地址也在本拍给出，数据下一拍到，与 `O_hit/O_color` 同拍对齐。
//   半片 = 同一张水果图的列窗或行窗（`color[6]` 选切割轴、`pal[3]` 选 A/B 侧），
//   所以查表通路仍然只有一条。
//
// 透明：RGB332 的 `8'h00` = 透明。精灵像素为 0 时不叠加（露出摄像头背景），
//   因为单口 ERAM 一拍只查得到一个对象，不能再去查下一个候选。
//
// 分数：自写 8×8 点阵数字 ROM，上屏 16×16（2×2 一方块），两位数字画在
//   x 540..555 / 558..573、y 170..185——避开 Logo（0..160）与右上状态字（x≥1100）。
// 生命：场地左上角内侧 3 个 16×16 方块，专用小逻辑，不占对象槽（规划 §3 第 5 步 7）。
//
// 延迟：判属 1 拍（前视抵消，对外 0 拍）；rect/数字/生命同拍组合。
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// 资源：约 400 LUT6 + 60 FF（判属寄存器），无 ERAM（精灵 ERAM 在 game_sprite_rom），无 DSP。
// ============================================================================
module game_render (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_de,           // 当前像素的 de（输出叠加门控用）
    input  wire [11:0] I_x_nxt,        // 下一个 de 像素的坐标（前视一拍）
    input  wire [11:0] I_y_nxt,
    input  wire [3:0]  I_display_mode, // bit0：0 = RAW 皮肤 / 1 = EDGE 皮肤（配色二选一）

    // ---- 对象表：6 槽 × 48 位（见规划 §5.3）--------------------------------
    // 每槽：{type[1:0], x[11:0], y[11:0], w[4:0], h[4:0], color[7:0], pal[3:0]}
    input  wire [287:0] I_obj,

    // ---- 刀光拖尾：刀尖 + 16 个印章（相对刀尖的左上角偏移，9 位有符号）----
    input  wire [11:0]  I_tip_x,
    input  wire [11:0]  I_tip_y,
    input  wire [287:0] I_trail_off,    // 16 × {dy[8:0], dx[8:0]}
    input  wire [15:0]  I_trail_en,

    // ---- 粒子：爆点 + 8 个 6×6 印章（同样存相对偏移）-----------------------
    input  wire [11:0]  I_burst_x,
    input  wire [11:0]  I_burst_y,
    input  wire [143:0] I_part_off,     // 8 × {dy[8:0], dx[8:0]}
    input  wire [7:0]   I_part_en,

    // ---- 分数 / 生命 -------------------------------------------------------
    input  wire [7:0]   I_score,        // BCD：{十位[3:0], 个位[3:0]}
    input  wire [3:0]   I_lives,
    input  wire [3:0]   I_state,
    input  wire         I_marker_en,    // 0xA3：1 像素对齐标记（L1 自检）

    // ---- 精灵 ROM 接口（地址本拍给、数据下一拍到）--------------------------
    output wire [11:0]  O_spr_addr,
    input  wire [7:0]   I_spr_px,

    // ---- 叠加结果（与下一拍的 I_pixel_in 同拍）-----------------------------
    output wire         O_hit,
    output wire [23:0]  O_color
);

    // ---- 配色（按 I_display_mode 二选一，不新增寄存器）---------------------
    localparam [23:0] COLOR_TRAIL_RAW  = 24'h00FF66;
    localparam [23:0] COLOR_TRAIL_EDGE = 24'h00FF00;
    localparam [23:0] COLOR_PART_RAW   = 24'hFFF200;
    localparam [23:0] COLOR_PART_EDGE  = 24'hFFC800;
    localparam [23:0] COLOR_SCORE_RAW  = 24'h00E6FF;
    localparam [23:0] COLOR_SCORE_EDGE = 24'hFFFFFF;

    wire [23:0] S_col_trail = I_display_mode[0] ? COLOR_TRAIL_EDGE : COLOR_TRAIL_RAW;
    wire [23:0] S_col_part  = I_display_mode[0] ? COLOR_PART_EDGE  : COLOR_PART_RAW;
    wire [23:0] S_col_text  = I_display_mode[0] ? COLOR_SCORE_EDGE : COLOR_SCORE_RAW;

    // RGB332 → RGB888（位复制，不做乘法）
    function [23:0] F_rgb332;
        input [7:0] I_px;
        reg [2:0] r;
        reg [2:0] g;
        reg [1:0] b;
        begin
            r = I_px[7:5];
            g = I_px[4:2];
            b = I_px[1:0];
            F_rgb332 = {r, r, r[2:1], g, g, g[2:1], b, b, b, b};
        end
    endfunction

    // ---- 对象表解码 + 命中（6 槽）------------------------------------------
    wire [5:0]   S_obj_hit;
    wire [71:0]  S_obj_addr_flat;    // 6 × 12
    wire [5:0]   S_obj_is_spr;
    wire [143:0] S_obj_rect_flat;    // 6 × 24

    genvar gi;
    generate
        for (gi = 0; gi < 6; gi = gi + 1) begin : g_obj
            wire [1:0]  W_type = I_obj[gi*48 + 46 +: 2];
            wire [11:0] W_x    = I_obj[gi*48 + 34 +: 12];
            wire [11:0] W_y    = I_obj[gi*48 + 22 +: 12];
            wire [4:0]  W_w    = I_obj[gi*48 + 17 +: 5];
            wire [4:0]  W_h    = I_obj[gi*48 + 12 +: 5];
            wire [7:0]  W_c    = I_obj[gi*48 +  4 +: 8];
            wire [3:0]  W_pal  = I_obj[gi*48 +  0 +: 4];

            // pal[2] 是负 x 标志。负数在 W_x 里是 12 位补码，拼上符号位后
            // 再做 13 位有符号差，才能让水果在左侧只被裁掉溢出的部分。
            wire signed [12:0] W_obj_x = {W_pal[2], W_x};
            wire signed [12:0] W_scr_x = {1'b0, I_x_nxt};
            wire signed [12:0] W_dx_s = W_scr_x - W_obj_x;
            wire [11:0] W_dx = W_dx_s[12] ? 12'hFFF : W_dx_s[11:0];
            wire [11:0] W_dy = I_y_nxt - W_y;

            wire        W_is_spr   = (W_type == 2'd2) | (W_type == 2'd3);
            // 精灵/半片：上屏坐标 >>2 换到源像素空间再比（4× 放大，见规划 §4.4 第 2 条）；
            // 方块/屏幕矩形：直接按上屏像素比。
            wire [11:0] W_dxs = W_dx >> 2;
            wire [11:0] W_dys = W_dy >> 2;
            wire        W_win = W_is_spr
                              ? ((W_dxs <= {7'b0, W_w}) && (W_dys <= {7'b0, W_h}))
                              : ((W_dx  <= {7'b0, W_w}) && (W_dy  <= {7'b0, W_h}));

            // 半片字段：pal[3]=A/B 侧，pal[2]=负 x，pal[1:0]=水果种类；
            // color[6]=切割轴（0=左右、1=上下），color[5:4]=左右半片的行偏移。
            wire W_is_piece = (W_type == 2'd3);
            wire W_axis     = W_is_piece && W_c[6];
            wire W_side     = W_pal[3];
            wire [1:0] W_rowsft = (W_is_piece && !W_axis) ? W_c[5:4] : 2'b00;
            // 左右切割：B 取源列 16..31；上下切割：B 取源行 16..31。
            wire [5:0] W_dx_src_ext =
                {1'b0, W_dxs[4:0]} +
                ((W_is_piece && !W_axis && W_side) ? 6'd16 : 6'd0);
            wire [5:0] W_dy_src_ext =
                {1'b0, W_dys[4:0]} +
                ((W_is_piece && W_axis && W_side) ? 6'd16 : 6'd0) +
                {4'b0, W_rowsft};
            wire [4:0] W_dx_src = W_dx_src_ext[4:0];
            wire [4:0] W_dy_src = W_dy_src_ext[4:0];

            assign S_obj_hit[gi] = W_win;
            assign S_obj_is_spr[gi] = W_is_spr;
            assign S_obj_addr_flat[gi*12 +: 12] = {2'b0, W_pal[1:0], W_dy_src, W_dx_src};
            assign S_obj_rect_flat[gi*24 +: 24] = F_rgb332(W_c);
        end
    endgenerate

    // 优先级：槽号小的赢（one-hot）
    wire S_sel0 = S_obj_hit[0];
    wire S_sel1 = S_obj_hit[1] & ~|S_obj_hit[0];
    wire S_sel2 = S_obj_hit[2] & ~|S_obj_hit[1:0];
    wire S_sel3 = S_obj_hit[3] & ~|S_obj_hit[2:0];
    wire S_sel4 = S_obj_hit[4] & ~|S_obj_hit[3:0];
    wire S_sel5 = S_obj_hit[5] & ~|S_obj_hit[4:0];

    wire [11:0] S_spr_addr =
          ({12{S_sel0}} & S_obj_addr_flat[ 0*12 +: 12])
        | ({12{S_sel1}} & S_obj_addr_flat[ 1*12 +: 12])
        | ({12{S_sel2}} & S_obj_addr_flat[ 2*12 +: 12])
        | ({12{S_sel3}} & S_obj_addr_flat[ 3*12 +: 12])
        | ({12{S_sel4}} & S_obj_addr_flat[ 4*12 +: 12])
        | ({12{S_sel5}} & S_obj_addr_flat[ 5*12 +: 12]);

    wire S_obj_spr_win = (S_sel0 & S_obj_is_spr[0]) | (S_sel1 & S_obj_is_spr[1])
                       | (S_sel2 & S_obj_is_spr[2]) | (S_sel3 & S_obj_is_spr[3])
                       | (S_sel4 & S_obj_is_spr[4]) | (S_sel5 & S_obj_is_spr[5]);

    wire [23:0] S_obj_rect_col =
          (S_sel0 ? S_obj_rect_flat[ 0*24 +: 24] : 24'd0)
        | (S_sel1 ? S_obj_rect_flat[ 1*24 +: 24] : 24'd0)
        | (S_sel2 ? S_obj_rect_flat[ 2*24 +: 24] : 24'd0)
        | (S_sel3 ? S_obj_rect_flat[ 3*24 +: 24] : 24'd0)
        | (S_sel4 ? S_obj_rect_flat[ 4*24 +: 24] : 24'd0)
        | (S_sel5 ? S_obj_rect_flat[ 5*24 +: 24] : 24'd0);

    wire S_hit_obj = |S_obj_hit;

    // ---- 刀光拖尾：16 个印章（相对刀尖的左上角偏移）------------------------
    // (Δ − off) 用 12 位无符号比较：真差值在 ±1535 内，别名是 4096 px 外，
    // 不可能落进 12/16 的窗口，所以既不用门控也不会出鬼影印章（规划 §4.4 第 2 条）。
    wire [11:0] S_dx_tip = I_x_nxt - I_tip_x;
    wire [11:0] S_dy_tip = I_y_nxt - I_tip_y;

    wire [15:0] S_trail_hit;
    genvar gt;
    generate
        for (gt = 0; gt < 16; gt = gt + 1) begin : g_trail
            wire signed [8:0] W_ox = I_trail_off[gt*18 +: 9];
            wire signed [8:0] W_oy = I_trail_off[gt*18 + 9 +: 9];
            wire [11:0] W_ex = S_dx_tip - {{3{W_ox[8]}}, W_ox};
            wire [11:0] W_ey = S_dy_tip - {{3{W_oy[8]}}, W_oy};
            // 第 15 个是刀尖章（16×16），其余 12×12
            wire [11:0] W_sz = (gt == 15) ? 12'd16 : 12'd12;
            assign S_trail_hit[gt] = I_trail_en[gt] & (W_ex < W_sz) & (W_ey < W_sz);
        end
    endgenerate

    wire S_hit_trail = |S_trail_hit;

    // ---- 粒子：8 个 6×6 印章 -------------------------------------------------
    wire [11:0] S_dx_bst = I_x_nxt - I_burst_x;
    wire [11:0] S_dy_bst = I_y_nxt - I_burst_y;

    wire [7:0] S_part_hit;
    genvar gp;
    generate
        for (gp = 0; gp < 8; gp = gp + 1) begin : g_part
            wire signed [8:0] W_ox = I_part_off[gp*18 +: 9];
            wire signed [8:0] W_oy = I_part_off[gp*18 + 9 +: 9];
            wire [11:0] W_ex = S_dx_bst - {{3{W_ox[8]}}, W_ox};
            wire [11:0] W_ey = S_dy_bst - {{3{W_oy[8]}}, W_oy};
            assign S_part_hit[gp] = I_part_en[gp] & (W_ex < 12'd6) & (W_ey < 12'd6);
        end
    endgenerate

    wire S_hit_part = |S_part_hit;

    // ---- 分数：8×8 数字点阵 ROM，上屏 16×16 --------------------------------
    localparam [11:0] SCORE_TENS_X = 12'd540;
    localparam [11:0] SCORE_ONES_X = 12'd558;
    localparam [11:0] SCORE_Y0     = 12'd170;

    function [7:0] F_digit_row;
        input [3:0] I_d;
        input [2:0] I_r;
        begin
            case({I_d, I_r})
                // 0
                7'h00: F_digit_row = 8'h3C; 7'h01: F_digit_row = 8'h66;
                7'h02: F_digit_row = 8'h6E; 7'h03: F_digit_row = 8'h76;
                7'h04: F_digit_row = 8'h66; 7'h05: F_digit_row = 8'h66;
                7'h06: F_digit_row = 8'h3C; 7'h07: F_digit_row = 8'h00;
                // 1
                7'h08: F_digit_row = 8'h18; 7'h09: F_digit_row = 8'h38;
                7'h0A: F_digit_row = 8'h18; 7'h0B: F_digit_row = 8'h18;
                7'h0C: F_digit_row = 8'h18; 7'h0D: F_digit_row = 8'h18;
                7'h0E: F_digit_row = 8'h7E; 7'h0F: F_digit_row = 8'h00;
                // 2
                7'h10: F_digit_row = 8'h3C; 7'h11: F_digit_row = 8'h66;
                7'h12: F_digit_row = 8'h06; 7'h13: F_digit_row = 8'h0C;
                7'h14: F_digit_row = 8'h18; 7'h15: F_digit_row = 8'h30;
                7'h16: F_digit_row = 8'h7E; 7'h17: F_digit_row = 8'h00;
                // 3
                7'h18: F_digit_row = 8'h3C; 7'h19: F_digit_row = 8'h66;
                7'h1A: F_digit_row = 8'h06; 7'h1B: F_digit_row = 8'h1C;
                7'h1C: F_digit_row = 8'h06; 7'h1D: F_digit_row = 8'h66;
                7'h1E: F_digit_row = 8'h3C; 7'h1F: F_digit_row = 8'h00;
                // 4
                7'h20: F_digit_row = 8'h0C; 7'h21: F_digit_row = 8'h1C;
                7'h22: F_digit_row = 8'h3C; 7'h23: F_digit_row = 8'h6C;
                7'h24: F_digit_row = 8'h7E; 7'h25: F_digit_row = 8'h0C;
                7'h26: F_digit_row = 8'h0C; 7'h27: F_digit_row = 8'h00;
                // 5
                7'h28: F_digit_row = 8'h7E; 7'h29: F_digit_row = 8'h60;
                7'h2A: F_digit_row = 8'h7C; 7'h2B: F_digit_row = 8'h06;
                7'h2C: F_digit_row = 8'h06; 7'h2D: F_digit_row = 8'h66;
                7'h2E: F_digit_row = 8'h3C; 7'h2F: F_digit_row = 8'h00;
                // 6
                7'h30: F_digit_row = 8'h1C; 7'h31: F_digit_row = 8'h30;
                7'h32: F_digit_row = 8'h60; 7'h33: F_digit_row = 8'h7C;
                7'h34: F_digit_row = 8'h66; 7'h35: F_digit_row = 8'h66;
                7'h36: F_digit_row = 8'h3C; 7'h37: F_digit_row = 8'h00;
                // 7
                7'h38: F_digit_row = 8'h7E; 7'h39: F_digit_row = 8'h06;
                7'h3A: F_digit_row = 8'h0C; 7'h3B: F_digit_row = 8'h18;
                7'h3C: F_digit_row = 8'h30; 7'h3D: F_digit_row = 8'h30;
                7'h3E: F_digit_row = 8'h30; 7'h3F: F_digit_row = 8'h00;
                // 8
                7'h40: F_digit_row = 8'h3C; 7'h41: F_digit_row = 8'h66;
                7'h42: F_digit_row = 8'h66; 7'h43: F_digit_row = 8'h3C;
                7'h44: F_digit_row = 8'h66; 7'h45: F_digit_row = 8'h66;
                7'h46: F_digit_row = 8'h3C; 7'h47: F_digit_row = 8'h00;
                // 9
                7'h48: F_digit_row = 8'h3C; 7'h49: F_digit_row = 8'h66;
                7'h4A: F_digit_row = 8'h66; 7'h4B: F_digit_row = 8'h3E;
                7'h4C: F_digit_row = 8'h06; 7'h4D: F_digit_row = 8'h0C;
                7'h4E: F_digit_row = 8'h38; 7'h4F: F_digit_row = 8'h00;
                default: F_digit_row = 8'h00;
            endcase
        end
    endfunction

    wire S_in_score_y = (I_y_nxt >= SCORE_Y0) && (I_y_nxt < (SCORE_Y0 + 12'd16));
    wire S_in_tens    = (I_x_nxt >= SCORE_TENS_X) && (I_x_nxt < (SCORE_TENS_X + 12'd16));
    wire S_in_ones    = (I_x_nxt >= SCORE_ONES_X) && (I_x_nxt < (SCORE_ONES_X + 12'd16));

    wire [11:0] S_lx_12 = S_in_ones ? (I_x_nxt - SCORE_ONES_X) : (I_x_nxt - SCORE_TENS_X);
    wire [11:0] S_ly_12 = I_y_nxt - SCORE_Y0;
    wire [3:0]  S_digit  = S_in_ones ? I_score[3:0] : I_score[7:4];
    wire [7:0]  S_font_row = F_digit_row(S_digit, S_ly_12[3:1]);
    wire        S_font_px  = S_font_row[3'd7 - S_lx_12[3:1]];
    wire        S_hit_score = S_in_score_y && (S_in_tens || S_in_ones) && S_font_px;

    // ---- 生命：场地左上角内侧 3 个 16×16 方块 ------------------------------
    wire S_life_y = (I_y_nxt >= 12'd216) && (I_y_nxt < 12'd232);
    wire S_life0  = (I_x_nxt >= 12'd80)  && (I_x_nxt < 12'd96);
    wire S_life1  = (I_x_nxt >= 12'd104) && (I_x_nxt < 12'd120);
    wire S_life2  = (I_x_nxt >= 12'd128) && (I_x_nxt < 12'd144);
    wire S_hit_life = S_life_y & ((S_life0 & (I_lives > 4'd0)) |
                                  (S_life1 & (I_lives > 4'd1)) |
                                  (S_life2 & (I_lives > 4'd2)));

    // ---- 1 像素对齐标记（L1 自检，规划 §3 第 1 步 / §8.1）------------------
    // 5 个白点：(0,0)、(1279,719) 在 Logo 之外，肉眼直接看；
    // (7,127)、(106,127)、(152,34) 正好落在 Logo 墨迹的极值点上——**对齐 = 完全被墨迹
    // 盖住看不见；差 1 像素时会在墨迹边缘冒出一个白点**，所以这是"负空间"判据。
    wire S_hit_mark = I_marker_en &
                      (((I_x_nxt == 12'd0)    && (I_y_nxt == 12'd0))    |
                       ((I_x_nxt == 12'd1279) && (I_y_nxt == 12'd719))  |
                       ((I_x_nxt == 12'd7)    && (I_y_nxt == 12'd127))  |
                       ((I_x_nxt == 12'd106)  && (I_y_nxt == 12'd127))  |
                       ((I_x_nxt == 12'd152)  && (I_y_nxt == 12'd34)));

    // ---- 图层优先级与输出寄存 ----------------------------------------------
    wire S_hit_flat = S_hit_mark | S_hit_score | S_hit_life | S_hit_trail | S_hit_part;
    wire S_win_spr  = S_hit_obj & S_obj_spr_win & ~S_hit_flat;
    wire S_win_flat = S_hit_flat | (S_hit_obj & ~S_obj_spr_win);

    wire [23:0] S_flat_col = S_hit_mark  ? 24'hFFFFFF  :
                             S_hit_score ? S_col_text  :
                             S_hit_life  ? S_col_text  :
                             S_hit_trail ? S_col_trail :
                             S_hit_part  ? S_col_part  : S_obj_rect_col;

    reg        S_win_flat_d;
    reg        S_win_spr_d;
    reg [23:0] S_flat_col_d;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_win_flat_d <= 1'b0;
            S_win_spr_d  <= 1'b0;
            S_flat_col_d <= 24'd0;
        end
        else begin
            S_win_flat_d <= S_win_flat;
            S_win_spr_d  <= S_win_spr;
            S_flat_col_d <= S_flat_col;
        end
    end

    assign O_spr_addr = S_spr_addr;

    wire [23:0] S_spr_rgb = F_rgb332(I_spr_px);

    // 精灵透明像素（8'h00）不叠加；其余情况按寄存的判属结果叠加。
    assign O_hit   = S_win_spr_d ? (I_spr_px != 8'h00) : S_win_flat_d;
    assign O_color = S_win_spr_d ? S_spr_rgb : S_flat_col_d;

endmodule
