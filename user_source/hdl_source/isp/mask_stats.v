// ============================================================================
// mask_stats —— 通用二值掩码统计器（包围盒 / 像素数 / 质心累加）
//
// 输入是与 96 位像素流同拍的 4 位掩码（bit0 = 列 4k-1，bit3 = 列 4k+2，与
// edge_detect_96 的输出几何一致），掩码源由调用方 mux（边缘 / 肤色 / 融合 / 帧差），
// 本模块不关心掩码从哪来。统计在帧首（I_user）锁存成"上一完整帧"的结果——与
// design_top_wrapper 里 N/B/C 计数器的模式一致——随后清零重新开始。
//
// 质心累加用 Σ列 / Σ行 两个全宽累加器（不做除法）：M1 要用时在帧率下除一次即可。
// 注意：帧首那一组像素的列号从 0 开始（列 4k-1 在 k=0 时本来会落到 -1，这里夹到 0）。
//
// 延迟：统计本身 0 拍组合计入，输出是帧锁存的稳定值。
// 时钟域：CSI 域，单时钟，不跨域。
// 资源：约 120 FF + 90 LUT，无 ERAM / DSP。
// ============================================================================
module mask_stats #(
    parameter IMG_WIDTH = 1280
)(
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire [3:0]  I_mask,
    input  wire        I_valid,
    input  wire        I_user,     // 帧首（与 I_valid 同拍）
    input  wire        I_last,     // 行末（当前未使用，保留给 ROI 窗口）

    output reg  [19:0] O_cnt,      // 上一帧掩码像素数（1280x720 最多 921600）
    output reg  [10:0] O_xmin,
    output reg  [10:0] O_xmax,
    output reg  [10:0] O_ymin,
    output reg  [10:0] O_ymax,
    output reg  [30:0] O_sumx,
    output reg  [29:0] O_sumy,
    output reg         O_empty     // 上一帧没有任何掩码像素
);

    localparam IMG_WIDTH_GRP = (IMG_WIDTH >> 2);

    reg [10:0] x_grp;
    reg [10:0] y_pos;

    // 帧内累加器
    reg [19:0] a_cnt;
    reg [10:0] a_xmin, a_xmax, a_ymin, a_ymax;
    reg [30:0] a_sumx;
    reg [29:0] a_sumy;
    reg        a_any;

    wire [2:0]  S_n     = {2'b0, I_mask[0]} + {2'b0, I_mask[1]} +
                          {2'b0, I_mask[2]} + {2'b0, I_mask[3]};
    wire [1:0]  S_jmin  = I_mask[0] ? 2'd0 : I_mask[1] ? 2'd1 : I_mask[2] ? 2'd2 : 2'd3;
    wire [1:0]  S_jmax  = I_mask[3] ? 2'd3 : I_mask[2] ? 2'd2 : I_mask[1] ? 2'd1 : 2'd0;
    wire [2:0]  S_jsum  = (I_mask[1] ? 3'd1 : 3'd0) + (I_mask[2] ? 3'd2 : 3'd0) +
                          (I_mask[3] ? 3'd3 : 3'd0);

    // 帧首**只认 I_user**、不闸 I_valid：上层流的 tuser 可能落在 valid 的空隙里
    // （2026-09-15 上板踩到，详见 recog_top.v 里 tap 计数器那段注释）。
    wire        S_new   = I_user;
    wire [10:0] S_cx    = S_new ? 11'd0 : x_grp;         // 当拍组号
    wire [10:0] S_cy    = S_new ? 11'd0 : y_pos;
    wire        S_xlast = (S_cx == IMG_WIDTH_GRP - 1);

    // 列号 4k-1 .. 4k+2；k=0 时最左那一列会算成 -1，这里夹到 0。
    wire [10:0] S_col_base = (S_cx == 11'd0) ? 11'd0 : ((S_cx << 2) - 11'd1);
    wire [10:0] S_col_min  = S_col_base + {9'b0, S_jmin};
    wire [10:0] S_col_max  = S_col_base + {9'b0, S_jmax};

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            x_grp  <= 11'd0;
            y_pos  <= 11'd0;
            a_cnt  <= 20'd0;
            a_xmin <= 11'h7FF;
            a_xmax <= 11'd0;
            a_ymin <= 11'h7FF;
            a_ymax <= 11'd0;
            a_sumx <= 31'd0;
            a_sumy <= 29'd0;
            a_any  <= 1'b0;
            O_cnt  <= 20'd0;
            O_xmin <= 11'd0;
            O_xmax <= 11'd0;
            O_ymin <= 11'd0;
            O_ymax <= 11'd0;
            O_sumx <= 31'd0;
            O_sumy <= 29'd0;
            O_empty <= 1'b1;
        end
        else begin
            // 帧首：把上一帧的累加结果锁存到输出，再清零继续统计本帧。
            // 放在 I_valid 之外——帧首那一拍可能没有有效像素。
            if(S_new) begin
                O_cnt   <= a_cnt;
                O_xmin  <= (a_cnt == 20'd0) ? 11'd0 : a_xmin;
                O_xmax  <= (a_cnt == 20'd0) ? 11'd0 : a_xmax;
                O_ymin  <= (a_cnt == 20'd0) ? 11'd0 : a_ymin;
                O_ymax  <= (a_cnt == 20'd0) ? 11'd0 : a_ymax;
                O_sumx  <= a_sumx;
                O_sumy  <= a_sumy;
                O_empty <= ~a_any;
                a_cnt   <= 20'd0;
                a_xmin  <= 11'h7FF;
                a_xmax  <= 11'd0;
                a_ymin  <= 11'h7FF;
                a_ymax  <= 11'd0;
                a_sumx  <= 31'd0;
                a_sumy  <= 29'd0;
                a_any   <= 1'b0;
                x_grp   <= 11'd0;
                y_pos   <= 11'd0;
            end

            if(I_valid) begin
                x_grp <= S_xlast ? 11'd0 : (S_cx + 11'd1);
                y_pos <= S_xlast ? (S_cy + 11'd1) : S_cy;

                if(S_n != 3'd0) begin
                    a_cnt <= (S_new ? 20'd0 : a_cnt) + {17'b0, S_n};

                    if(S_new || (S_col_min < a_xmin)) a_xmin <= S_col_min;
                    if(S_new || (S_col_max > a_xmax)) a_xmax <= S_col_max;
                    if(S_new || (S_cy      < a_ymin)) a_ymin <= S_cy;
                    if(S_new || (S_cy      > a_ymax)) a_ymax <= S_cy;

                    a_sumx <= (S_new ? 31'd0 : a_sumx) +
                              (S_n * S_col_base) + {28'b0, S_jsum};
                    a_sumy <= (S_new ? 30'd0 : a_sumy) + (S_n * S_cy);
                    a_any  <= 1'b1;
                end
            end
        end
    end

endmodule
