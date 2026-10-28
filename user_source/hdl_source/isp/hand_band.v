// ============================================================================
// hand_band —— 行级手部候选带（无 frame buffer / 无除法）
//
// 目的：把"整幅肤色掩码的包围盒"换成"手所在的连续行带"，解决场景里出现脸/手臂
// 后，质心、指尖和手势 y_min 被整幅掩码带偏的问题。
//
// 输入是 recog_top 的 S_m_pick_v（开运算 + 多数投票后、ROI 门控前），4 像素/拍。
// 逐行统计整行肤色像素数 count、行内 x_min/x_max、跨度 span。
// 行有效：count >= ROW_MIN_SKIN、span >= ROW_MIN_SPAN、count*4 >= span。
// 连续有效行（允许 ROW_GAP_TOL 行 gap）并成带，面积 = 行内 count 之和。
//
// 选带：
//   * 未锁定：用 I_seed_x/y（运动播种质心）选最近带；
//   * 已锁定：用上一帧手框中心选最近带；
//   * 半径 SEARCH_R，找不到先保持上一框 HOLD_FRAMES 帧，再判无效。
// 手框跟新：小幅变化 1/2 平滑，任一边跳变 > SNAP_DELTA 直接跟随。
//
// 延迟：帧末 I_tuser 锁存；与 mask_stats 同口径（1~2 帧观测延迟）。
// 时钟域：CSI 域单时钟，不跨域，不需要 SDC。
// 资源：约 200 FF + 300 LUT6，0 ERAM / 0 DSP。
// ============================================================================
module hand_band #(
    parameter integer IMG_W = 1280,
    parameter integer IMG_H = 720,
    parameter [10:0]  ROW_MIN_SKIN = 11'd24,
    parameter [10:0]  ROW_MIN_SPAN = 11'd40,
    parameter [3:0]   ROW_GAP_TOL  = 4'd2,
    parameter [19:0]  MIN_AREA     = 20'd2000,
    parameter [10:0]  MIN_W        = 11'd60,
    parameter [9:0]   MIN_H        = 10'd60,
    parameter [10:0]  SEARCH_R     = 11'd256,
    parameter [10:0]  MOTION_WIN   = 11'd200,   // 仅统计种子附近的运动证据，不裁切手部掩码
    parameter [10:0]  SNAP_DELTA   = 11'd48,
    parameter [3:0]   HOLD_FRAMES  = 4'd2
)(
    input  wire        I_clk,
    input  wire        I_rst_n,

    // 与像素流同拍的掩码（bit0 = 列 4k）
    input  wire [3:0]  I_mask,
    input  wire [3:0]  I_motion,     // 同拍运动掩码（用于 P0-04a 运动证据）
    input  wire [10:0] I_x_grp,      // 0..IMG_W/4-1
    input  wire [9:0]  I_y_pos,      // 0..IMG_H-1
    input  wire        I_tvalid,
    input  wire        I_tuser,      // 帧首

    // 选带种子：未锁定用运动质心，锁定后用上一手框中心
    input  wire        I_locked,
    input  wire        I_seed_valid,
    input  wire [10:0] I_seed_x,
    input  wire [9:0]  I_seed_y,

    // 帧锁存结果（给 ROI / M2 / 手势 / DBG 用）
    output wire        O_valid,
    output wire [10:0] O_x_min,
    output wire [10:0] O_x_max,
    output wire [9:0]  O_y_min,
    output wire [9:0]  O_y_max,
    output wire [19:0] O_area,
    output wire [10:0] O_cx,
    output wire [9:0]  O_cy,
    output wire [19:0] O_mot_win,
    output wire [19:0] O_mot_all
);

    localparam [10:0] X_LAST = (IMG_W >> 2) - 1;

    // ---- 上一帧手框 / 选带种子 ----------------------------------------------
    reg        h_valid;
    reg [10:0] h_xmin, h_xmax;
    reg [9:0]  h_ymin, h_ymax;
    reg [19:0] h_area;
    reg [3:0]  hold_cnt;

    wire [11:0] H_cx_sum = {1'b0, h_xmin} + {1'b0, h_xmax};
    wire [10:0] H_cx     = H_cx_sum[11:1];
    wire [10:0] H_cy_sum = {1'b0, h_ymin} + {1'b0, h_ymax};
    wire [9:0]  H_cy     = H_cy_sum[10:1];

    wire        S_seed_ok = I_locked ? h_valid : I_seed_valid;
    wire [10:0] S_seed_x  = I_locked ? H_cx   : I_seed_x;
    wire [9:0]  S_seed_y  = I_locked ? H_cy   : I_seed_y;

    // ---- 种子中心运动证据窗 ------------------------------------------------
    // 肤色行统计必须读取整行，否则靠近窗口边缘的手指会被直接截断。
    // MOTION_WIN 只用于 P0-04a/b 的运动证据，不影响手框或显示掩码。
    wire [10:0] S_win_lo = (S_seed_x > MOTION_WIN) ? (S_seed_x - MOTION_WIN) : 11'd0;
    wire [11:0] S_win_hi12 = {1'b0, S_seed_x} + {1'b0, MOTION_WIN};
    wire [10:0] S_win_hi = (S_win_hi12 > 12'd1279) ? 11'd1279 : S_win_hi12[10:0];
    wire [10:0] S_col0w = {I_x_grp, 2'b00};
    wire [10:0] S_col1w = S_col0w + 11'd1;
    wire [10:0] S_col2w = S_col0w + 11'd2;
    wire [10:0] S_col3w = S_col0w + 11'd3;
    wire [3:0] S_mask_win = I_mask;
    wire [3:0] S_motion_win = {
        I_motion[3] && (S_col3w >= S_win_lo) && (S_col3w <= S_win_hi),
        I_motion[2] && (S_col2w >= S_win_lo) && (S_col2w <= S_win_hi),
        I_motion[1] && (S_col1w >= S_win_lo) && (S_col1w <= S_win_hi),
        I_motion[0] && (S_col0w >= S_win_lo) && (S_col0w <= S_win_hi)
    };
    wire [2:0] W_mot_win = {2'b0, S_motion_win[0]} + {2'b0, S_motion_win[1]} +
                           {2'b0, S_motion_win[2]} + {2'b0, S_motion_win[3]};
    wire [2:0] W_mot_all = {2'b0, I_motion[0]} + {2'b0, I_motion[1]} +
                           {2'b0, I_motion[2]} + {2'b0, I_motion[3]};

    reg [19:0] a_mot_win, a_mot_all;
    reg [19:0] h_mot_win, h_mot_all;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            a_mot_win <= 20'd0; a_mot_all <= 20'd0;
            h_mot_win <= 20'd0; h_mot_all <= 20'd0;
        end
        else if(I_tuser) begin
            h_mot_win <= a_mot_win;
            h_mot_all <= a_mot_all;
            a_mot_win <= 20'd0;
            a_mot_all <= 20'd0;
        end
        else if(I_tvalid) begin
            a_mot_win <= a_mot_win + {17'b0, W_mot_win};
            a_mot_all <= a_mot_all + {17'b0, W_mot_all};
        end
    end
    assign O_mot_win = h_mot_win;
    assign O_mot_all = h_mot_all;

    // ---- 当前拍的像素统计 --------------------------------------------------
    wire [2:0]  W_n    = {2'b0, S_mask_win[0]} + {2'b0, S_mask_win[1]} +
                         {2'b0, S_mask_win[2]} + {2'b0, S_mask_win[3]};
    wire [1:0]  W_jmin = S_mask_win[0] ? 2'd0 : S_mask_win[1] ? 2'd1 :
                         S_mask_win[2] ? 2'd2 : 2'd3;
    wire [1:0]  W_jmax = S_mask_win[3] ? 2'd3 : S_mask_win[2] ? 2'd2 :
                         S_mask_win[1] ? 2'd1 : 2'd0;
    wire        W_have = |S_mask_win;
    wire [12:0] W_xbase = {I_x_grp, 2'b00};
    wire [12:0] W_xfirst = W_xbase + {11'b0, W_jmin};
    wire [12:0] W_xlast  = W_xbase + {11'b0, W_jmax};

    // ---- 当前行的累加器 ----------------------------------------------------
    reg [10:0] r_cnt;
    reg [10:0] r_xmin, r_xmax;
    reg        r_any;
    // 行摘要寄存器：把"当前像素 → 行有效 → 带/候选更新"的长组合路径截成两拍。
    // 2026-10-21 第一次 Build 2 PnR 的 -850 ps 最差路径正是 r_awb_g → best_dist.cea。
    reg        q_pending;
    reg        q_any;
    reg [10:0] q_cnt, q_xmin, q_xmax;
    reg [9:0]  q_y;

    // 行有效性在 q_* 寄存之后再判：AWB 那条长路径只到"计数/极值寄存器"为止。
    wire [11:0] Q_span12 = ({1'b0, q_xmax} - {1'b0, q_xmin}) + 12'd1;
    wire [10:0] Q_span   = q_any ? Q_span12[10:0] : 11'd0;
    wire Q_row_valid = q_any &&
                       (q_cnt >= ROW_MIN_SKIN) &&
                       (Q_span >= ROW_MIN_SPAN) &&
                       ({q_cnt, 2'b00} >= {2'b00, Q_span});
    wire [10:0] W_cnt_f  = r_cnt + {8'b0, W_n};
    wire [10:0] W_xmin_f = !W_have ? r_xmin :
                           (!r_any ? W_xfirst[10:0] :
                            ((r_xmin < W_xfirst[10:0]) ? r_xmin : W_xfirst[10:0]));
    wire [10:0] W_xmax_f = !W_have ? r_xmax :
                           (!r_any ? W_xlast[10:0] :
                            ((r_xmax > W_xlast[10:0]) ? r_xmax : W_xlast[10:0]));
    wire        W_row_any = r_any | W_have;
    wire [11:0] W_span12  = ({1'b0, W_xmax_f} - {1'b0, W_xmin_f}) + 12'd1;
    wire [10:0] W_span_f  = W_row_any ? W_span12[10:0] : 11'd0;

    wire W_row_valid = W_row_any &&
                       (W_cnt_f >= ROW_MIN_SKIN) &&
                       (W_span_f >= ROW_MIN_SPAN) &&
                       ({W_cnt_f, 2'b00} >= {2'b00, W_span_f});

    // ---- 当前带 ------------------------------------------------------------
    reg        b_active;
    reg [19:0] b_area;
    reg [10:0] b_xmin, b_xmax;
    reg [9:0]  b_ymin, b_ymax;
    reg [3:0]  b_gap;

    wire [10:0] B_w = (b_xmax >= b_xmin) ? (b_xmax - b_xmin + 11'd1) : 11'd0;
    wire [9:0]  B_h = (b_ymax >= b_ymin) ? (b_ymax - b_ymin + 10'd1) : 10'd0;
    wire [12:0] B_w13 = {2'b00, B_w};
    wire [12:0] B_h13 = {3'b000, B_h};
    wire [12:0] B_w4  = {B_w, 2'b00};
    wire [12:0] B_h5  = {1'b0, B_h, 2'b00} + {3'b000, B_h};
    wire B_shape_ok = b_active &&
                      (b_area >= MIN_AREA) &&
                      (B_w >= MIN_W) &&
                      (B_h >= MIN_H) &&
                      (B_h13 <= B_w4) &&
                      (B_w13 <= B_h5);

    wire [11:0] B_cx_sum = {1'b0, b_xmin} + {1'b0, b_xmax};
    wire [10:0] B_cx     = B_cx_sum[11:1];
    wire [10:0] B_cy_sum = {1'b0, b_ymin} + {1'b0, b_ymax};
    wire [9:0]  B_cy     = B_cy_sum[10:1];

    function [11:0] F_abs11;
        input [10:0] I_a, I_b;
        begin
            F_abs11 = (I_a >= I_b) ? ({1'b0, I_a} - {1'b0, I_b})
                                   : ({1'b0, I_b} - {1'b0, I_a});
        end
    endfunction

    wire [11:0] B_dx = F_abs11(B_cx, S_seed_x);
    wire [11:0] B_dy = F_abs11({1'b0, B_cy}, {1'b0, S_seed_y});
    wire [11:0] B_dist = B_dx + B_dy;
    wire S_in_range = S_seed_ok && (B_dist <= {1'b0, SEARCH_R});

    // 本帧已关闭的最优带（按到种子的距离）
    reg        best_valid;
    reg [19:0] best_area;
    reg [10:0] best_xmin, best_xmax;
    reg [9:0]  best_ymin, best_ymax;
    reg [11:0] best_dist;

    wire S_open_pick = B_shape_ok && S_in_range &&
                       (!best_valid || (B_dist <= best_dist));
    wire S_pick_valid = S_open_pick || best_valid;
    wire [10:0] S_pick_xmin = S_open_pick ? b_xmin : best_xmin;
    wire [10:0] S_pick_xmax = S_open_pick ? b_xmax : best_xmax;
    wire [9:0]  S_pick_ymin = S_open_pick ? b_ymin : best_ymin;
    wire [9:0]  S_pick_ymax = S_open_pick ? b_ymax : best_ymax;
    wire [19:0] S_pick_area = S_open_pick ? b_area : best_area;

    // ---- 手框跳变判断 ------------------------------------------------------
    wire [11:0] J_dx1 = F_abs11(S_pick_xmin, h_xmin);
    wire [11:0] J_dx2 = F_abs11(S_pick_xmax, h_xmax);
    wire [11:0] J_dy1 = F_abs11({1'b0, S_pick_ymin}, {1'b0, h_ymin});
    wire [11:0] J_dy2 = F_abs11({1'b0, S_pick_ymax}, {1'b0, h_ymax});
    wire        S_jump = h_valid &&
                         ((J_dx1 > {1'b0, SNAP_DELTA}) ||
                          (J_dx2 > {1'b0, SNAP_DELTA}) ||
                          (J_dy1 > {1'b0, SNAP_DELTA}) ||
                          (J_dy2 > {1'b0, SNAP_DELTA}));

    // ---- 主状态机 ----------------------------------------------------------
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            r_cnt <= 11'd0; r_xmin <= 11'd0; r_xmax <= 11'd0; r_any <= 1'b0;
            q_pending <= 1'b0; q_any <= 1'b0;
            q_cnt <= 11'd0; q_xmin <= 11'd0; q_xmax <= 11'd0; q_y <= 10'd0;
            b_active <= 1'b0; b_area <= 20'd0;
            b_xmin <= 11'd0; b_xmax <= 11'd0;
            b_ymin <= 10'd0; b_ymax <= 10'd0; b_gap <= 4'd0;
            best_valid <= 1'b0; best_area <= 20'd0;
            best_xmin <= 11'd0; best_xmax <= 11'd0;
            best_ymin <= 10'd0; best_ymax <= 10'd0;
            best_dist <= 12'hFFF;
            h_valid <= 1'b0; h_area <= 20'd0;
            h_xmin <= 11'd0; h_xmax <= 11'd0;
            h_ymin <= 10'd0; h_ymax <= 10'd0;
            hold_cnt <= 4'd0;
        end
        else begin
            // (0) 先把上一行锁存的摘要并进带/候选。q_* 已经寄存，路径不再穿到 AWB。
            if(q_pending) begin
                q_pending <= 1'b0;
                if(Q_row_valid) begin
                    if(!b_active) begin
                        b_active <= 1'b1;
                        b_area   <= {9'b0, q_cnt};
                        b_xmin   <= q_xmin;
                        b_xmax   <= q_xmax;
                        b_ymin   <= q_y;
                        b_ymax   <= q_y;
                        b_gap    <= 4'd0;
                    end
                    else begin
                        b_area <= b_area + {9'b0, q_cnt};
                        b_xmin <= (q_xmin < b_xmin) ? q_xmin : b_xmin;
                        b_xmax <= (q_xmax > b_xmax) ? q_xmax : b_xmax;
                        b_ymax <= q_y;
                        b_gap  <= 4'd0;
                    end
                end
                else if(b_active) begin
                    if(b_gap >= ROW_GAP_TOL) begin
                        b_active <= 1'b0;
                        if(B_shape_ok && S_in_range &&
                           (!best_valid || (B_dist < best_dist))) begin
                            best_valid <= 1'b1;
                            best_area  <= b_area;
                            best_xmin  <= b_xmin;
                            best_xmax  <= b_xmax;
                            best_ymin  <= b_ymin;
                            best_ymax  <= b_ymax;
                            best_dist  <= B_dist;
                        end
                    end
                    else begin
                        b_gap <= b_gap + 4'd1;
                    end
                end
            end

            if(I_tuser) begin
            // 帧末：把仍开着的带并入选择，再更新手框
            if(S_pick_valid) begin
                if(h_valid && !S_jump) begin
                    h_xmin <= ({1'b0, h_xmin} + {1'b0, S_pick_xmin}) >> 1;
                    h_xmax <= ({1'b0, h_xmax} + {1'b0, S_pick_xmax}) >> 1;
                    h_ymin <= ({1'b0, h_ymin} + {1'b0, S_pick_ymin}) >> 1;
                    h_ymax <= ({1'b0, h_ymax} + {1'b0, S_pick_ymax}) >> 1;
                end
                else begin
                    h_xmin <= S_pick_xmin;
                    h_xmax <= S_pick_xmax;
                    h_ymin <= S_pick_ymin;
                    h_ymax <= S_pick_ymax;
                end
                h_area  <= S_pick_area;
                h_valid <= 1'b1;
                hold_cnt <= 4'd0;
            end
            else if(h_valid) begin
                if(hold_cnt >= HOLD_FRAMES)
                    h_valid <= 1'b0;
                else
                    hold_cnt <= hold_cnt + 4'd1;
            end

            // 新帧：清行/带/候选
            r_cnt <= 11'd0; r_xmin <= 11'd0; r_xmax <= 11'd0; r_any <= 1'b0;
            q_pending <= 1'b0; q_any <= 1'b0;
            b_active <= 1'b0; b_area <= 20'd0;
            b_xmin <= 11'd0; b_xmax <= 11'd0;
            b_ymin <= 10'd0; b_ymax <= 10'd0; b_gap <= 4'd0;
            best_valid <= 1'b0; best_area <= 20'd0;
            best_xmin <= 11'd0; best_xmax <= 11'd0;
            best_ymin <= 10'd0; best_ymax <= 10'd0;
            best_dist <= 12'hFFF;

            // tuser 可能落在 valid=1 的那一拍：把它当作新帧第 0 组
            if(I_tvalid) begin
                r_cnt  <= {8'b0, W_n};
                r_any  <= W_have;
                r_xmin <= W_have ? W_xfirst[10:0] : 11'd0;
                r_xmax <= W_have ? W_xlast[10:0]  : 11'd0;
            end
            end
            else if(I_tvalid) begin
            r_cnt  <= W_cnt_f;
            r_any  <= W_row_any;
            r_xmin <= W_xmin_f;
            r_xmax <= W_xmax_f;

            if(I_x_grp == X_LAST) begin
                // 行结束：只锁存摘要，下一拍再并入带/候选
                q_any     <= W_row_any;
                q_cnt     <= W_cnt_f;
                q_xmin    <= W_xmin_f;
                q_xmax    <= W_xmax_f;
                q_y       <= I_y_pos;
                q_pending <= 1'b1;
                r_cnt <= 11'd0; r_any <= 1'b0;
                r_xmin <= 11'd0; r_xmax <= 11'd0;
            end
            end
        end
    end

    assign O_valid  = h_valid;
    assign O_x_min  = h_xmin;
    assign O_x_max  = h_xmax;
    assign O_y_min  = h_ymin;
    assign O_y_max  = h_ymax;
    assign O_area   = h_area;
    assign O_cx     = H_cx;
    assign O_cy     = H_cy;

endmodule
