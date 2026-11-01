// ============================================================================
// game_catch —— 手势接果篮（像素域，vsync 节拍）
//
// 玩法：
//   * 水果/炸弹从画面顶端垂直落下；
//   * 刀锋 x 控制底部开口果篮的水平位置；
//   * 水果中心跨过果篮开口线 (CATCH_Y) 时只结算一次：
//       - 中心落在开口内：普通水果 +1，炸弹 -5；
//       - 中心落在开口外：普通水果 -1，炸弹不扣分。
//
// 对象表（6 × 48 位）：
//   0 = 左壁、1 = 底边、2 = 右壁（type=1 矩形）；
//   3~5 = 下落中的水果/炸弹（type=2 精灵）。
//   果篮占前三个槽位，所以水果进入篮内时会被边框正确遮挡。
//
// 判定：
//   跨线判定使用“本帧 y”和“下一帧 y”，最高速度也不会因为单帧跨过判定线而漏判。
//   水果/炸弹使用现有 32×32 精灵，上屏 4× 放大为 128×128。
//
// 难度：
//   I_catch_cfg[15:8] = 初始下落速度（上屏像素/帧，1..9）；
//   I_catch_cfg[7:0]  = 每多少 ×16 帧加速一次（0 = 不自动加速）；
//   速度到 9 px/帧封顶。
//
// 资源：无 ERAM、无 DSP；只新增 3 个下落对象和边缘矩形数据。
// ============================================================================
module game_catch #(
    parameter integer IMG_W       = 1280,
    parameter integer BASKET_W    = 260,
    parameter integer WALL_W      = 12,
    parameter integer CATCH_Y     = 610,
    parameter integer SPEED_CAP   = 9,
    parameter integer PART_FRAMES = 12
) (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_vsync,

    // ---- 参数 ---------------------------------------------------------------
    input  wire [7:0]  I_spawn_interval,
    input  wire [15:0] I_catch_cfg,

    // ---- 控制 ---------------------------------------------------------------
    input  wire        I_restart,
    input  wire        I_standby,
    input  wire        I_pause,

    // ---- 手势 x（失锁保持由 game_input 负责）--------------------------------
    input  wire [11:0] I_blade_x,

    // ---- 对象表 -------------------------------------------------------------
    output wire [287:0] O_obj,

    // ---- 命中爆散（复用 game_render 的 8 个印章）----------------------------
    output wire [11:0]  O_burst_x,
    output wire [11:0]  O_burst_y,
    output wire [143:0] O_part_off,
    output wire [7:0]   O_part_en,
    output wire         O_part_bomb,

    // ---- 分数 / 状态 --------------------------------------------------------
    output wire [8:0]   O_score,
    output wire [3:0]   O_state,
    output wire [15:0]  O_hit_cnt,
    output wire [15:0]  O_miss_cnt,
    output wire [11:0]  O_fruit1_x,
    output wire [11:0]  O_fruit1_y,
    output wire [15:0]  O_state_word,
    output wire [11:0]  O_basket_center,
    output wire [7:0]   O_speed
);

    localparam integer INNER_H  = (BASKET_W / 2) - WALL_W;
    localparam integer BASKET_L = BASKET_W / 2;
    localparam integer BASKET_R = IMG_W - BASKET_L - 1;

    // ---- 下落对象（3 槽）----------------------------------------------------
    reg [11:0] S_px [0:2];
    reg [11:0] S_py [0:2];
    reg [1:0]  S_pal [0:2];
    reg [1:0]  S_typ [0:2];       // 0 = 空闲，2 = 水果/炸弹
    reg        S_bomb [0:2];
    reg        S_resolved [0:2];  // 已经判定过接住/漏掉，防止重复计分

    // ---- 难度 / 生成 --------------------------------------------------------
    reg [7:0]  S_speed;
    reg [7:0]  S_spawn_cnt;
    reg [15:0] S_lfsr;
    reg [15:0] S_level_cnt;

    // ---- 分数 / 统计 --------------------------------------------------------
    reg [7:0]  S_score;
    reg        S_score_neg;
    reg [2:0]  S_score_hit_f;
    reg [2:0]  S_score_bomb_f;
    reg [2:0]  S_score_miss_f;
    reg [3:0]  S_state;
    reg [15:0] S_hit_cnt;
    reg [15:0] S_miss_cnt;

    // ---- 命中反馈 -----------------------------------------------------------
    reg [11:0] S_burst_x;
    reg [11:0] S_burst_y;
    reg        S_part_bomb;
    reg [3:0]  S_part_age;

    reg        S_vs_d;

    wire        S_run = (S_state == 4'd1) && !I_pause;
    wire [2:0]  S_active = {S_typ[2] == 2'd2,
                            S_typ[1] == 2'd2,
                            S_typ[0] == 2'd2};
    wire [2:0]  S_bomb_active = {S_bomb[2], S_bomb[1], S_bomb[0]};
    wire [1:0]  S_spawn_slot = ~S_active[0] ? 2'd0 :
                               ~S_active[1] ? 2'd1 : 2'd2;
    wire        S_has_bomb = |(S_bomb_active & S_active);

    // 刀锋 x → 果篮中心，并在屏幕内钳位。
    wire [11:0] S_basket_center =
        (I_blade_x < BASKET_L) ? BASKET_L :
        (I_blade_x > BASKET_R) ? BASKET_R : I_blade_x;
    wire [11:0] S_basket_left = S_basket_center - BASKET_L;

    // ---- 每条下落对象的跨线判定 ---------------------------------------------
    wire [11:0] S_py_next [0:2];
    wire [2:0]  S_hit_fruit;
    wire [2:0]  S_hit_bomb;
    wire [2:0]  S_miss_fruit;

    genvar gi;
    generate
        for (gi = 0; gi < 3; gi = gi + 1) begin : g_catch_eval
            assign S_py_next[gi] = S_py[gi] + {4'b0, S_speed};

            wire signed [12:0] W_fruit_center =
                $signed({1'b0, S_px[gi]}) + 13'sd64;
            wire signed [12:0] W_basket_center =
                $signed({1'b0, S_basket_center});
            wire signed [12:0] W_dx = W_fruit_center - W_basket_center;
            wire W_in_opening = (W_dx >= -INNER_H) && (W_dx <= INNER_H);

            wire [12:0] W_prev_y = {1'b0, S_py[gi]} + 13'd64;
            wire [12:0] W_next_y = {1'b0, S_py_next[gi]} + 13'd64;
            wire W_cross = S_active[gi] && !S_resolved[gi] && S_run &&
                           (W_prev_y < CATCH_Y) && (W_next_y >= CATCH_Y);

            assign S_hit_fruit[gi] = W_cross &&  W_in_opening && !S_bomb[gi];
            assign S_hit_bomb[gi]  = W_cross &&  W_in_opening &&  S_bomb[gi];
            assign S_miss_fruit[gi]= W_cross && !W_in_opening && !S_bomb[gi];
        end
    endgenerate

    wire S_score_event = (|S_score_hit_f) || (|S_score_bomb_f) ||
                         (|S_score_miss_f);
    wire [8:0] S_score_next;

    game_score u_game_score (
        .I_score          ({S_score_neg, S_score}),
        .I_miss_num       ({1'b0, |S_score_miss_f}),
        .I_fruit_hit_mask (S_score_hit_f),
        .I_bomb_hit_mask  (S_score_bomb_f),
        .O_score          (S_score_next)
    );

    // ---- 第一颗活动水果（串口观测）------------------------------------------
    wire [11:0] S_fruit1_x = S_active[0] ? S_px[0] :
                             S_active[1] ? S_px[1] :
                             S_active[2] ? S_px[2] : 12'd0;
    wire [11:0] S_fruit1_y = S_active[0] ? S_py[0] :
                             S_active[1] ? S_py[1] :
                             S_active[2] ? S_py[2] : 12'd0;

    // ---- 对象表打包 ---------------------------------------------------------
    function [47:0] F_sprite_obj;
        input [11:0] I_x;
        input [11:0] I_y;
        input [3:0]  I_pal;
        begin
            F_sprite_obj = {2'd2, I_x, I_y, 5'd31, 5'd31, 8'h00, I_pal};
        end
    endfunction

    localparam [47:0] IDLE_OBJ = {2'd2, 12'd2000, 12'd0,
                                  5'd0, 5'd0, 8'h00, 4'h0};

    genvar go;
    generate
        for (go = 0; go < 3; go = go + 1) begin : g_obj
            assign O_obj[go*48 +: 48] = S_active[go]
                ? F_sprite_obj(S_px[go], S_py[go],
                               {S_bomb[go], 1'b0, S_pal[go]})
                : IDLE_OBJ;
        end
    endgenerate
    assign O_obj[3*48 +: 48] = IDLE_OBJ;
    assign O_obj[4*48 +: 48] = IDLE_OBJ;
    assign O_obj[5*48 +: 48] = IDLE_OBJ;

    // ---- 爆散：固定八方向，12 帧后关闭 --------------------------------------
    function [8:0] F_part_dx;
        input [2:0] I_i;
        begin
            case(I_i)
                3'd0: F_part_dx = -9'sd16;
                3'd1: F_part_dx =  9'sd0;
                3'd2: F_part_dx =  9'sd16;
                3'd3: F_part_dx = -9'sd20;
                3'd4: F_part_dx =  9'sd20;
                3'd5: F_part_dx = -9'sd16;
                3'd6: F_part_dx =  9'sd0;
                default: F_part_dx = 9'sd16;
            endcase
        end
    endfunction

    function [8:0] F_part_dy;
        input [2:0] I_i;
        begin
            case(I_i)
                3'd0: F_part_dy = -9'sd16;
                3'd1: F_part_dy = -9'sd20;
                3'd2: F_part_dy = -9'sd16;
                3'd3: F_part_dy =  9'sd0;
                3'd4: F_part_dy =  9'sd0;
                3'd5: F_part_dy =  9'sd16;
                3'd6: F_part_dy =  9'sd20;
                default: F_part_dy = 9'sd16;
            endcase
        end
    endfunction

    genvar gp;
    generate
        for (gp = 0; gp < 8; gp = gp + 1) begin : g_part
            assign O_part_off[gp*18 +: 9]      = F_part_dx(gp[2:0]);
            assign O_part_off[gp*18 + 9 +: 9]  = F_part_dy(gp[2:0]);
        end
    endgenerate

    assign O_burst_x   = S_burst_x;
    assign O_burst_y   = S_burst_y;
    assign O_part_en   = (S_part_age < PART_FRAMES) ? 8'hFF : 8'h00;
    assign O_part_bomb = S_part_bomb;
    assign O_score     = {S_score_neg, S_score};
    assign O_state     = S_state;
    assign O_hit_cnt   = S_hit_cnt;
    assign O_miss_cnt  = S_miss_cnt;
    assign O_fruit1_x  = S_fruit1_x;
    assign O_fruit1_y  = S_fruit1_y;
    assign O_state_word= {S_state, 3'b000, S_score_neg, S_score};
    assign O_basket_center = S_basket_center;
    assign O_speed     = S_speed;

    // ---- 主状态更新 ---------------------------------------------------------
    integer oi;
    reg [7:0] W_start_speed;
    reg [15:0] W_level_stride;

    always @* begin
        W_start_speed = (I_catch_cfg[15:8] == 8'd0) ? 8'd1 :
                        (I_catch_cfg[15:8] > SPEED_CAP) ? SPEED_CAP :
                        I_catch_cfg[15:8];
        W_level_stride = {8'b0, I_catch_cfg[7:0]} << 4;
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_vs_d       <= 1'b0;
            S_state      <= 4'd1;
            S_score      <= 8'd0;
            S_score_neg  <= 1'b0;
            S_score_hit_f  <= 3'd0;
            S_score_bomb_f <= 3'd0;
            S_score_miss_f <= 3'd0;
            S_hit_cnt    <= 16'd0;
            S_miss_cnt   <= 16'd0;
            S_speed      <= 8'd3;
            S_spawn_cnt  <= 8'd0;
            S_level_cnt  <= 16'd0;
            S_lfsr       <= 16'hACE1;
            S_burst_x    <= 12'd640;
            S_burst_y    <= CATCH_Y;
            S_part_bomb  <= 1'b0;
            S_part_age   <= 4'd15;
            for(oi = 0; oi < 3; oi = oi + 1) begin
                S_px[oi]       <= 12'd0;
                S_py[oi]       <= 12'd0;
                S_pal[oi]      <= 2'd0;
                S_typ[oi]      <= 2'd0;
                S_bomb[oi]     <= 1'b0;
                S_resolved[oi] <= 1'b0;
            end
        end
        else begin
            S_vs_d <= I_vsync;

            if(I_restart) begin
                S_state      <= 4'd1;
                S_score      <= 8'd0;
                S_score_neg  <= 1'b0;
                S_score_hit_f  <= 3'd0;
                S_score_bomb_f <= 3'd0;
                S_score_miss_f <= 3'd0;
                S_hit_cnt    <= 16'd0;
                S_miss_cnt   <= 16'd0;
                S_speed      <= W_start_speed;
                S_spawn_cnt  <= 8'd0;
                S_level_cnt  <= 16'd0;
                S_part_age   <= 4'd15;
                S_part_bomb  <= 1'b0;
                for(oi = 0; oi < 3; oi = oi + 1) begin
                    S_typ[oi]      <= 2'd0;
                    S_bomb[oi]     <= 1'b0;
                    S_resolved[oi] <= 1'b0;
                end
            end
            else if(I_standby) begin
                S_state      <= 4'd0;
                S_part_age   <= 4'd15;
                for(oi = 0; oi < 3; oi = oi + 1) begin
                    S_typ[oi]      <= 2'd0;
                    S_bomb[oi]     <= 1'b0;
                    S_resolved[oi] <= 1'b0;
                end
            end

            if(S_run && (I_vsync & ~S_vs_d)) begin
                // 伪随机数只服务于水果种类、横向位置和炸弹事件。
                S_lfsr <= {S_lfsr[14:0], S_lfsr[15] ^ S_lfsr[13] ^
                           S_lfsr[12] ^ S_lfsr[10]};

                // 本帧先更新位置，再用“旧位置 → 新位置”的跨线事件结算。
                for(oi = 0; oi < 3; oi = oi + 1) begin
                    if(S_active[oi])
                        S_py[oi] <= S_py_next[oi];
                end

                if(S_score_event) begin
                    S_score     <= S_score_next[7:0];
                    S_score_neg <= S_score_next[8];
                end

                if(|S_score_hit_f) begin
                    S_hit_cnt <= S_hit_cnt +
                                 {14'b0, S_score_hit_f[0]} +
                                 {14'b0, S_score_hit_f[1]} +
                                 {14'b0, S_score_hit_f[2]};
                end
                if(|S_score_miss_f) begin
                    S_miss_cnt <= S_miss_cnt +
                                  {14'b0, S_score_miss_f[0]} +
                                  {14'b0, S_score_miss_f[1]} +
                                  {14'b0, S_score_miss_f[2]};
                end

                // 判定仍在本帧发生；分数另寄存一帧，切断刀锋坐标到 BCD
                // 换算再回写分数寄存器的长组合路径。
                S_score_hit_f  <= S_hit_fruit;
                S_score_bomb_f <= S_hit_bomb;
                S_score_miss_f <= S_miss_fruit;

                for(oi = 0; oi < 3; oi = oi + 1) begin
                    if(S_hit_fruit[oi] || S_hit_bomb[oi]) begin
                        S_typ[oi]      <= 2'd0;
                        S_bomb[oi]     <= 1'b0;
                        S_resolved[oi] <= 1'b0;
                    end
                    else if(S_miss_fruit[oi] ||
                            (S_active[oi] && !S_resolved[oi] &&
                             S_bomb[oi] &&
                             (S_py[oi] + {4'b0, S_speed} + 12'd64 >= CATCH_Y))) begin
                        // 普通水果跨线漏掉；炸弹漏掉只标记，不扣分。
                        S_resolved[oi] <= 1'b1;
                    end

                    // 漏掉后继续掉出屏幕再回收。
                    if(S_active[oi] && (S_py_next[oi] > 12'd720)) begin
                        S_typ[oi]      <= 2'd0;
                        S_bomb[oi]     <= 1'b0;
                        S_resolved[oi] <= 1'b0;
                    end
                end

                // 命中反馈：炸弹优先确定颜色，位置取本帧最早命中的对象。
                if(|S_hit_fruit || |S_hit_bomb) begin
                    S_part_age  <= 4'd0;
                    S_part_bomb <= |S_hit_bomb;
                    if(S_hit_bomb[0]) begin
                        S_burst_x <= S_px[0] + 12'd64;
                        S_burst_y <= S_py[0] + 12'd64;
                    end
                    else if(S_hit_bomb[1]) begin
                        S_burst_x <= S_px[1] + 12'd64;
                        S_burst_y <= S_py[1] + 12'd64;
                    end
                    else if(S_hit_bomb[2]) begin
                        S_burst_x <= S_px[2] + 12'd64;
                        S_burst_y <= S_py[2] + 12'd64;
                    end
                    else if(S_hit_fruit[0]) begin
                        S_burst_x <= S_px[0] + 12'd64;
                        S_burst_y <= S_py[0] + 12'd64;
                    end
                    else if(S_hit_fruit[1]) begin
                        S_burst_x <= S_px[1] + 12'd64;
                        S_burst_y <= S_py[1] + 12'd64;
                    end
                    else begin
                        S_burst_x <= S_px[2] + 12'd64;
                        S_burst_y <= S_py[2] + 12'd64;
                    end
                end
                else if(S_part_age < 4'd15)
                    S_part_age <= S_part_age + 4'd1;

                // 难度：每 W_level_stride 帧加速 1 px/帧，封顶 SPEED_CAP。
                if((W_level_stride != 16'd0) &&
                   (S_level_cnt + 16'd1 >= W_level_stride)) begin
                    S_level_cnt <= 16'd0;
                    if(S_speed < SPEED_CAP)
                        S_speed <= S_speed + 8'd1;
                end
                else if(W_level_stride != 16'd0)
                    S_level_cnt <= S_level_cnt + 16'd1;

                // 生成：选第一个空槽；同屏最多一颗炸弹。
                if((S_active != 3'b111) &&
                   (S_spawn_cnt >= I_spawn_interval)) begin
                    S_spawn_cnt <= 8'd0;
                    S_typ[S_spawn_slot]      <= 2'd2;
                    S_pal[S_spawn_slot]      <= S_lfsr[1:0];
                    S_bomb[S_spawn_slot]     <= (S_lfsr[2:0] == 3'd0) &&
                                                !S_has_bomb;
                    S_resolved[S_spawn_slot] <= 1'b0;
                    S_px[S_spawn_slot]       <= 12'd64 + {4'b0, S_lfsr[11:2]};
                    S_py[S_spawn_slot]       <= 12'd0;
                end
                else if(S_spawn_cnt != 8'hFF)
                    S_spawn_cnt <= S_spawn_cnt + 8'd1;
            end
        end
    end

endmodule
