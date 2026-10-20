// ============================================================================
// game_gesture —— 动态手势事件 → 一次斩击请求 + 扫掠带可视化
//
// 输入是 A 侧 recog_top 的 40 位帧锁存事件字（经 VIDEO_TAP toggle 整包捕获）：
//   [4:0] seq / [7:5] dir / [15:8] start_x8 / [23:16] start_y8
//   [31:24] peak_dx8(8px 单位) / [39:32] peak_dy8(4px 单位)
//
// 关键行为：
//   * 进游戏、刀锋未锁定、游戏非运行态时清基线；重新满足条件后先记录当前
//     seq，不补放旧事件。
//   * seq 变化且 dir ∈ {1,2,3} 时产生单拍 O_slash_valid。
//   * 扫掠带 = 起点到峰值的主轴范围，副轴两端各外扩 I_half_w。
//   * 方向色：左红、右绿、下蓝；I_flash_frames 帧内保持可见。
//
// 延迟：事件在像素域寄存一拍后输出；扫掠带是逐帧稳定数据，不影响 game_render
// 的 0 拍边界。
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// 资源：约 120 FF + 250 LUT6，无 ERAM / DSP。
// ============================================================================
module game_gesture (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_vsync,

    input  wire        I_bypass,        // 1 = 游戏层旁路（game_mode == 0）
    input  wire [3:0]  I_game_mode,
    input  wire        I_track_locked,
    input  wire        I_game_running,  // game_fruit state == 1
    input  wire [1:0]  I_ctx,           // 预留：0 = 游戏态，1 = 菜单（本轮未用）

    input  wire [39:0] I_gest_word,
    input  wire [7:0]  I_half_w,
    input  wire [7:0]  I_flash_frames,

    output reg         O_slash_valid,
    output reg  [1:0]  O_slash_dir,
    output reg  [11:0] O_band_x0,
    output reg  [11:0] O_band_x1,
    output reg  [11:0] O_band_y0,
    output reg  [11:0] O_band_y1,
    output reg         O_band_vis,
    output reg  [23:0] O_band_color
);

    localparam [23:0] C_LEFT  = 24'hFF4040;   // 左挥：红
    localparam [23:0] C_RIGHT = 24'h40FF40;   // 右挥：绿
    localparam [23:0] C_DOWN  = 24'h4080FF;   // 下劈：蓝

    wire        S_gate = I_game_mode[0] & ~I_bypass & I_track_locked &
                         I_game_running & (I_ctx == 2'd0);
    wire [2:0]  S_dir  = I_gest_word[7:5];
    wire [4:0]  S_seq  = I_gest_word[4:0];

    // ---- 事件字解码与钳位 -------------------------------------------------
    wire [7:0]  S_sx8 = I_gest_word[15:8];
    wire [7:0]  S_sy8 = I_gest_word[23:16];
    wire signed [7:0] S_pdx8 = I_gest_word[31:24];
    wire signed [7:0] S_pdy8 = I_gest_word[39:32];

    wire [11:0] S_start_x_raw = {S_sx8, 3'b000};
    wire [11:0] S_start_y_raw = {S_sy8, 2'b00};
    wire [11:0] S_start_x = (S_start_x_raw > 12'd1279) ? 12'd1279 : S_start_x_raw;
    wire [11:0] S_start_y = (S_start_y_raw > 12'd719)  ? 12'd719  : S_start_y_raw;

    wire signed [12:0] S_pdx = {{5{S_pdx8[7]}}, S_pdx8};
    wire signed [12:0] S_pdy = {{5{S_pdy8[7]}}, S_pdy8};
    wire signed [12:0] S_peak_x_s = $signed({1'b0, S_start_x}) + (S_pdx <<< 3);
    wire signed [12:0] S_peak_y_s = $signed({1'b0, S_start_y}) + (S_pdy <<< 2);

    wire [11:0] S_peak_x = S_peak_x_s[12] ? 12'd0 :
                           (S_peak_x_s > 13'sd1279) ? 12'd1279 : S_peak_x_s[11:0];
    wire [11:0] S_peak_y = S_peak_y_s[12] ? 12'd0 :
                           (S_peak_y_s > 13'sd719)  ? 12'd719  : S_peak_y_s[11:0];

    wire [11:0] S_min_x = (S_start_x < S_peak_x) ? S_start_x : S_peak_x;
    wire [11:0] S_max_x = (S_start_x < S_peak_x) ? S_peak_x : S_start_x;
    wire [11:0] S_min_y = (S_start_y < S_peak_y) ? S_start_y : S_peak_y;
    wire [11:0] S_max_y = (S_start_y < S_peak_y) ? S_peak_y : S_start_y;

    wire [12:0] S_half = {5'b0, I_half_w};
    wire [12:0] S_x0_lr = {1'b0, S_min_x};
    wire [12:0] S_x1_lr = {1'b0, S_max_x};
    wire [12:0] S_y0_lr = ({1'b0, S_min_y} > S_half) ? ({1'b0, S_min_y} - S_half) : 13'd0;
    wire [12:0] S_y1_lr = ({1'b0, S_max_y} + S_half > 13'd719) ? 13'd719 :
                          ({1'b0, S_max_y} + S_half);

    wire [12:0] S_y0_dn = {1'b0, S_min_y};
    wire [12:0] S_y1_dn = {1'b0, S_max_y};
    wire [12:0] S_x0_dn = ({1'b0, S_min_x} > S_half) ? ({1'b0, S_min_x} - S_half) : 13'd0;
    wire [12:0] S_x1_dn = ({1'b0, S_max_x} + S_half > 13'd1279) ? 13'd1279 :
                          ({1'b0, S_max_x} + S_half);

    wire S_is_down = (S_dir == 3'd3);
    wire [12:0] S_x0_sel = S_is_down ? S_x0_dn : S_x0_lr;
    wire [12:0] S_x1_sel = S_is_down ? S_x1_dn : S_x1_lr;
    wire [12:0] S_y0_sel = S_is_down ? S_y0_dn : S_y0_lr;
    wire [12:0] S_y1_sel = S_is_down ? S_y1_dn : S_y1_lr;

    wire [23:0] S_col_sel = (S_dir == 3'd1) ? C_LEFT :
                            (S_dir == 3'd2) ? C_RIGHT : C_DOWN;

    // ---- 基线 / 事件检测 ---------------------------------------------------
    reg        S_base_valid;
    reg [4:0]  S_base_seq;
    reg [7:0]  S_timer;
    reg        S_vs_d;

    wire S_vs_rise = I_vsync & ~S_vs_d;
    wire S_dir_ok  = (S_dir == 3'd1) || (S_dir == 3'd2) || (S_dir == 3'd3);
    wire S_evt_accept = S_gate && S_base_valid && (S_seq != S_base_seq) && S_dir_ok;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_base_valid  <= 1'b0;
            S_base_seq    <= 5'd0;
            S_timer       <= 8'd0;
            S_vs_d        <= 1'b0;
            O_slash_valid <= 1'b0;
            O_slash_dir   <= 2'd0;
            O_band_x0     <= 12'd0;
            O_band_x1     <= 12'd0;
            O_band_y0     <= 12'd0;
            O_band_y1     <= 12'd0;
            O_band_vis    <= 1'b0;
            O_band_color  <= 24'd0;
        end
        else begin
            S_vs_d        <= I_vsync;
            O_slash_valid <= 1'b0;

            if(!S_gate) begin
                // 退出门控：清基线、清带子。重新进游戏/重锁后再取当前 seq。
                S_base_valid <= 1'b0;
                S_timer      <= 8'd0;
            end
            else if(!S_base_valid) begin
                // 第一帧只建立基线，不补放旧事件。
                S_base_seq   <= S_seq;
                S_base_valid <= 1'b1;
            end
            else if(S_seq != S_base_seq) begin
                S_base_seq <= S_seq;
                if(S_dir_ok) begin
                    O_slash_valid <= 1'b1;
                    O_slash_dir   <= S_dir[1:0];
                    O_band_x0     <= S_x0_sel[11:0];
                    O_band_x1     <= S_x1_sel[11:0];
                    O_band_y0     <= S_y0_sel[11:0];
                    O_band_y1     <= S_y1_sel[11:0];
                    O_band_color  <= S_col_sel;
                    S_timer       <= I_flash_frames;
                end
            end

            // 提示带按显示帧递减；新事件在同一拍装载时优先。
            if(S_vs_rise && (S_timer != 8'd0) && !S_evt_accept)
                S_timer <= S_timer - 8'd1;

            O_band_vis <= (S_timer != 8'd0);
        end
    end

endmodule
