// ============================================================================
// game_fruit —— 切水果本体（像素域，vsync 节拍）
//
// 职责：水果/炸弹抛体物理 + 伪随机生成 + 切中判定 + 分数 + 拖尾与粒子数据。
//   渲染不在这里（在 game_render）；本模块只产出"对象表 + 印章相对偏移"这些数据。
//
// 对象槽（规划 §5.3，6 槽 × 48 位）：
//   0~2 = 水果槽（被切中后**原地变成半片 A**）；3~5 = 备用槽（借给半片 B）。
//   空闲槽报 `x = 2000`（>1279，屏幕外）+ `w = h = 0` → 任何像素都判不中，
//   所以不需要额外的"有效位"字段，48 位一个不多一个不少。
//
// 定标（与 game_param.v 文件头一致，改之前先看那边）：
//   * 位置 `pos[15:0]` = 上屏像素 12.4 定点（整数部分 = pos[15:4]）；
//   * 速度 16 位有符号，单位 1/16 上屏像素 / 帧；
//   * 重力每帧加 `I_grav >> 4`（默认 0x40 → 0.25 px/帧²）；
//   * 初速：垂直 = -(I_v0[15:8] << 5)（默认 0x09 → 18 px/帧 向上），水平 ±(LFSR[2:0] << 4)。
//
// 判定：默认 `BLADE_CUT_EN=1`，每帧用最近 8 个刀锋点插值出 16 个采样点，
//   对 3 个活动水果槽做 128×128 碰撞箱（外扩 10 px）AABB 判定。
//   不使用 DSP 乘法，也不等待手势事件结算。
//
// 节拍：vsync 上升沿 → PHYS(1) → TRAIL(16) → JUDGE(≤48) → ACT(1) → END(1)；
//   所有状态在一个 vsync 内收敛。
//
// 延迟：输出都是帧锁存值，供同域的像素通路组合使用；不跨域、不需要 SDC 约束。
// 时钟域：像素域 75 MHz 单时钟。
// 资源：默认配置约 800 FF、约 500 LUT6、0 DSP、0 ERAM。
// ============================================================================
module game_fruit #(
    parameter integer BLADE_CUT_EN = 1, // 1 = 每帧刀锋轨迹连续判定
    parameter integer CUT_MODE = 0      // 本轮只实现 0 = 8 历史点 + 16 采样 + AABB
) (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_vsync,

    // ---- 参数（game_param 输出）------------------------------------------
    input  wire [7:0]  I_spawn_interval,
    input  wire [15:0] I_grav,
    input  wire [15:0] I_v0,
    input  wire [15:0] I_trail_cfg,     // {点数[7:0], 静止寿命帧[7:0]}
    input  wire [15:0] I_part_cfg,      // {粒子数[7:0], 寿命帧[7:0]}
    input  wire [11:0] I_field_y1,      // 场地下边界（漏切判定线）
    input  wire        I_restart,
    input  wire        I_standby,
    input  wire        I_pause,

    // ---- 刀尖（game_input 输出）------------------------------------------
    input  wire [11:0] I_blade_x,
    input  wire [11:0] I_blade_y,
    input  wire        I_blade_valid,
    input  wire        I_track_locked,
    input  wire        I_cut_src_ok,    // 只允许手势源计分

    // ---- 对象表（6 × 48）--------------------------------------------------
    output wire [287:0] O_obj,

    // ---- 刀光拖尾（刀尖 + 16 个印章的相对左上角偏移）----------------------
    output wire [11:0]  O_tip_x,
    output wire [11:0]  O_tip_y,
    output wire [287:0] O_trail_off,
    output wire [15:0]  O_trail_en,

    // ---- 粒子（爆点 + 8 个印章的相对左上角偏移）---------------------------
    output wire [11:0]  O_burst_x,
    output wire [11:0]  O_burst_y,
    output wire [143:0] O_part_off,
    output wire [7:0]   O_part_en,
    output wire         O_part_bomb,     // 当前爆散是否为炸弹爆炸

    // ---- 分数 / 状态 --------------------------------------------------------
    output wire [8:0]   O_score,        // {负号, BCD十位[3:0], BCD个位[3:0]}
    output wire [3:0]   O_state,        // 0 = 待机、1 = 运行（无生命/结束态）
    output wire [15:0]  O_hit_cnt,
    output wire [15:0]  O_miss_cnt,
    output wire [11:0]  O_fruit1_x,
    output wire [11:0]  O_fruit1_y,
    output wire [15:0]  O_state_word,   // {state[3:0], 3'b0, score_neg, score_bcd[7:0]}
    output wire [15:0]  O_blade_pos     // {x>>3[7:0], y>>3[7:0]}
);

    localparam [2:0] PH_IDLE = 3'd0, PH_PHYS = 3'd1, PH_TRAIL = 3'd2,
                     PH_JUDGE = 3'd3, PH_ACT = 3'd4, PH_END = 3'd5;

    // ---- 对象槽 ------------------------------------------------------------
    reg [15:0] S_px [0:5];
    reg [15:0] S_py [0:5];
    reg [15:0] S_vx [0:5];
    reg [15:0] S_vy [0:5];
    reg [1:0]  S_pal [0:5];
    reg [1:0]  S_typ [0:5];      // 0 = 空闲、2 = 水果、3 = 半片
    reg        S_bomb [0:5];     // 仅 type=2 时有效：1 = 炸弹
    reg        S_half [0:5];     // 半片 A/B 侧（pal[3]）
    reg        S_axis [0:5];     // 0 = 左右半片，1 = 上下半片（color[6]）
    reg [1:0]  S_rowoff [0:5];   // 半片"自旋"：源行偏移，每 4 帧 +1（规划 §3 第 5 步 2）
    reg        S_missed[0:5];    // 已经记过一次漏切（防止同一个水果反复扣命）

    // ---- 刀光历史（8 点，hist[0] = 最新 = 刀尖）----------------------------
    reg [11:0] S_hist_x [0:7];
    reg [11:0] S_hist_y [0:7];

    // ---- 印章偏移（相对刀尖的左上角，9 位有符号、±255）--------------------
    reg [8:0]  S_tox [0:15];
    reg [8:0]  S_toy [0:15];
    reg [15:0] S_trail_en;

    // ---- 粒子 --------------------------------------------------------------
    reg [8:0]  S_pox [0:7];
    reg [8:0]  S_poy [0:7];
    reg [7:0]  S_part_en;
    reg [7:0]  S_part_age;
    reg        S_part_bomb;
    reg [11:0] S_burst_x, S_burst_y;

    // ---- 标量状态 ----------------------------------------------------------
    reg [7:0]  S_state, S_score;
    reg        S_score_neg;
    reg [1:0]  S_miss_score;
    reg [15:0] S_hit_cnt, S_miss_cnt;
    reg [15:0] S_lfsr;
    reg [7:0]  S_spawn_cnt, S_still_cnt;
    reg [1:0]  S_spin_tick;

    reg [2:0]  S_ph;
    reg [4:0]  S_tr_i;
    reg        S_tr_sub;         // 拖尾两拍：0 = 锁采样点，1 = 算偏移并写
    reg [11:0] S_smpr_x, S_smpr_y;   // 锁存后的采样点（把长组合路径切成两级）
    reg [11:0] S_hwr;                // 锁存后的印章半宽
    reg [11:0] S_tipr_x, S_tipr_y;   // 锁存后的刀尖
    reg [3:0]  S_j_s;
    reg [1:0]  S_j_f;
    reg [2:0]  S_hit_f;
    reg        S_cut_en_d;
    reg        S_hist_valid;
    reg [2:0]  S_cut_dir;            // 1=左 2=右 3=下 4=上；静止保持上次
    reg        S_frame_pend, S_vs_d;

    integer oi;

    // ---- 组合：B 段默认值（I_grav >> 4 = 每帧速度增量，单位 1/16 px/帧）----
    wire [15:0] S_dv = {4'b0, I_grav[15:4]};
    wire S_cut_enable = I_blade_valid && I_track_locked && I_cut_src_ok;
    wire S_split_h = (S_cut_dir == 3'd1) || (S_cut_dir == 3'd2);

    // 半片继承速度必须按有符号数右移。S_vx/S_vy 用 16 位补码保存负速度，
    // 直接对 unsigned 向量使用 >>> 会退化成逻辑右移并把负速度变成极大正值。
    function [15:0] F_half_vel;
        input [15:0] I_vel;
        begin
            F_half_vel = $signed(I_vel) >>> 1;
        end
    endfunction

    // ---- 组合：刀光采样点（16 个：0 = 尾巴、1..14 = 每段 1/4 与 3/4 插值、15 = 刀尖）----
    // 插值只用移位（d >>> 2），不做除法；返回顺序从 hist[7] 到 hist[0]，
    // 供碰撞扫掠和“最近刀尖命中段”方向判定共用。
    function [11:0] F_smp;
        input [3:0] I_idx;
        input       I_is_y;
        reg [3:0]   k;
        reg signed [12:0] d;
        reg [11:0]  p0, p1;
        begin
            if(I_idx == 4'd0)       p0 = 12'd0;   // 占位，下面统一取值
            // 取相邻两点：hist[k] 与 hist[k+1]
            k = (I_idx == 4'd0) ? 4'd0 : ((I_idx == 4'd15) ? 4'd0 : ((I_idx - 4'd1) >> 1));
            if(I_idx == 4'd0) begin
                p0 = I_is_y ? S_hist_y[7] : S_hist_x[7];
            end
            else if(I_idx == 4'd15) begin
                p0 = I_is_y ? S_hist_y[0] : S_hist_x[0];
            end
            else begin
                p1 = I_is_y ? S_hist_y[k+1] : S_hist_x[k+1];
                p0 = I_is_y ? S_hist_y[k]   : S_hist_x[k];
                d  = $signed({1'b0, p0}) - $signed({1'b0, p1});
                if(I_idx[0] == 1'b0) p0 = p1 + d - (d >>> 2);         // 3/4 处
                else                 p0 = p1 + (d >>> 2);             // 1/4 处
            end
            F_smp = p0;
        end
    endfunction

    wire [3:0]  S_calc_idx = (S_ph == PH_JUDGE) ? S_j_s : S_tr_i[3:0];
    wire [11:0] S_smp_x    = F_smp(S_calc_idx, 1'b0);
    wire [11:0] S_smp_y    = F_smp(S_calc_idx, 1'b1);
    wire [11:0] S_tip_x    = S_hist_x[0];
    wire [11:0] S_tip_y    = S_hist_y[0];

    // 方向取当前命中采样段；k=0 时没有前一采样点，退回最近两帧向量。
    wire [11:0] S_smp_prev_x = F_smp(S_j_s - 4'd1, 1'b0);
    wire [11:0] S_smp_prev_y = F_smp(S_j_s - 4'd1, 1'b1);
    wire signed [12:0] S_cut_dx = (S_j_s == 4'd0)
                                  ? ($signed({1'b0, S_hist_x[0]}) -
                                     $signed({1'b0, S_hist_x[1]}))
                                  : ($signed({1'b0, S_smp_x}) -
                                     $signed({1'b0, S_smp_prev_x}));
    wire signed [12:0] S_cut_dy = (S_j_s == 4'd0)
                                  ? ($signed({1'b0, S_hist_y[0]}) -
                                     $signed({1'b0, S_hist_y[1]}))
                                  : ($signed({1'b0, S_smp_y}) -
                                     $signed({1'b0, S_smp_prev_y}));
    wire [12:0] S_cut_adx = S_cut_dx[12] ? (~S_cut_dx + 13'd1) : S_cut_dx;
    wire [12:0] S_cut_ady = S_cut_dy[12] ? (~S_cut_dy + 13'd1) : S_cut_dy;
    wire S_cut_dir_valid = (S_cut_adx != 13'd0) || (S_cut_ady != 13'd0);
    wire [2:0] S_cut_dir_new = (S_cut_adx >= S_cut_ady)
                               ? (S_cut_dx[12] ? 3'd1 : 3'd2)
                               : (S_cut_dy[12] ? 3'd4 : 3'd3);

    // 印章左上角偏移 = 采样点 − 半宽 − 刀尖；越界 clamp 到 ±255
    // （超快挥动时表现为"尾巴被截短"，比错位/鬼影好看——规划 §3 第 6 步）
    // 采样点/半宽/刀尖都是**锁存后**的值（PH_TRAIL 两拍结构），所以这条通路很短。
    function signed [8:0] F_off;
        input [11:0] I_smp;
        input [11:0] I_halfw;
        input [11:0] I_tip;
        reg signed [13:0] raw;
        begin
            raw = $signed({2'b0, I_smp}) - $signed({2'b0, I_halfw}) - $signed({2'b0, I_tip});
            if(raw > 14'sd255)       F_off = 9'sd255;
            else if(raw < -14'sd255) F_off = -9'sd255;
            else                     F_off = raw[8:0];
        end
    endfunction

    wire signed [8:0] S_off_x = F_off(S_smpr_x, S_hwr, S_tipr_x);
    wire signed [8:0] S_off_y = F_off(S_smpr_y, S_hwr, S_tipr_y);

    // ---- 组合：判定用（128×128 水果中心 vs 当前采样点）--------------------
    // ⚠ 这里必须用视觉中心：128×128 水果的左上角到中心是 +64；
    //   用左上角会“看着没碰到却切中/飞到屏外被切”。
    wire [12:0] S_fcx = {1'b0, S_px[S_j_f][15:4]} + 13'd64;
    wire [12:0] S_fcy = {1'b0, S_py[S_j_f][15:4]} + 13'd64;
    wire signed [13:0] S_ddx = $signed({1'b0, S_fcx}) - $signed({2'b0, S_smp_x});
    wire signed [13:0] S_ddy = $signed({1'b0, S_fcy}) - $signed({2'b0, S_smp_y});
    // AABB 粗筛：
    wire S_far = (S_ddx > 14'sd74) | (S_ddx < -14'sd74) |
                 (S_ddy > 14'sd74) | (S_ddy < -14'sd74);
    // 只有"活跃且**在屏内**的水果"参与判定：半片不再计分；水果中心还在屏幕外
    // （刚生成、正在从画面下方升起）时不许切——否则"水果还没出现就被切没了"。
    wire S_on_screen = (S_fcy <= 13'd719) && (S_fcx <= 13'd1279);
    wire S_pair_ok = (S_typ[S_j_f] == 2'd2) && S_on_screen && !S_far;

    // ---- 组合：空闲槽 / 备用槽 --------------------------------------------
    wire [2:0] S_bomb_active = {(S_typ[2] == 2'd2) && S_bomb[2],
                                (S_typ[1] == 2'd2) && S_bomb[1],
                                (S_typ[0] == 2'd2) && S_bomb[0]};
    wire [2:0] S_bomb_hit_f   = S_hit_f & S_bomb_active;
    wire [2:0] S_fruit_hit_f  = S_hit_f & ~S_bomb_active;
    wire        S_fruit_free = (S_typ[0] == 2'd0) | (S_typ[1] == 2'd0) | (S_typ[2] == 2'd0);
    wire [1:0]  S_fruit_slot = (S_typ[0] == 2'd0) ? 2'd0 : ((S_typ[1] == 2'd0) ? 2'd1 : 2'd2);
    wire        S_spare_free = (S_typ[3] == 2'd0) | (S_typ[4] == 2'd0) | (S_typ[5] == 2'd0);
    wire [2:0]  S_spare_slot = (S_typ[3] == 2'd0) ? 3'd3 : ((S_typ[4] == 2'd0) ? 3'd4 : 3'd5);
    // 炸弹最多同时出现一颗；每个生成机会约 2/16 = 12.5% 选为炸弹。
    wire        S_bomb_on_screen = |S_bomb_active;
    wire        S_spawn_bomb = (S_lfsr[3:0] < 4'd2) && !S_bomb_on_screen;

    // ---- 组合：漏切（下落到场地下边界以下，且正在下行）----------------------
    wire [15:0] S_y_lim = {I_field_y1, 4'b0};
    wire [2:0]  S_miss_mask;
    // 判据用水果/炸弹中心过"漏切判定线"，且只记一次；炸弹漏掉不扣分。
    assign S_miss_mask[0] = (S_typ[0] == 2'd2) && !S_bomb[0] && !S_missed[0] &&
                            (({1'b0, S_py[0][15:4]} + 13'd64) > {1'b0, I_field_y1}) &&
                            (S_vy[0][15] == 1'b0);
    assign S_miss_mask[1] = (S_typ[1] == 2'd2) && !S_bomb[1] && !S_missed[1] &&
                            (({1'b0, S_py[1][15:4]} + 13'd64) > {1'b0, I_field_y1}) &&
                            (S_vy[1][15] == 1'b0);
    assign S_miss_mask[2] = (S_typ[2] == 2'd2) && !S_bomb[2] && !S_missed[2] &&
                            (({1'b0, S_py[2][15:4]} + 13'd64) > {1'b0, I_field_y1}) &&
                            (S_vy[2][15] == 1'b0);
    wire [1:0]  S_miss_num = {1'b0, S_miss_mask[0]} + {1'b0, S_miss_mask[1]} + {1'b0, S_miss_mask[2]};
    wire [1:0]  S_fruit_hit_num = {1'b0, S_fruit_hit_f[0]} +
                                  {1'b0, S_fruit_hit_f[1]} +
                                  {1'b0, S_fruit_hit_f[2]};
    wire [1:0]  S_bomb_hit_num  = {1'b0, S_bomb_hit_f[0]} +
                                  {1'b0, S_bomb_hit_f[1]} +
                                  {1'b0, S_bomb_hit_f[2]};
    wire        S_score_event = (S_fruit_hit_num != 2'd0) ||
                                (S_bomb_hit_num != 2'd0) ||
                                (S_miss_score != 2'd0);
    wire [8:0]  S_score_next;

    game_score u_game_score (
        .I_score          ({S_score_neg, S_score}),
        .I_miss_num       (S_miss_score),
        .I_fruit_hit_mask (S_fruit_hit_f),
        .I_bomb_hit_mask  (S_bomb_hit_f),
        .O_score          (S_score_next)
    );

    // ---- 组合：完全离开屏幕才回收槽位 --------------------------------------
    wire [5:0] S_gone_mask;
    genvar gm;
    generate
        for (gm = 0; gm < 6; gm = gm + 1) begin : g_gone
            // x 位置是 12.4 定点，扩展成 17 位有符号数后判断完整出屏：
            // 右侧 top_left_x >= 1280；左侧 right_edge <= 0，即 top_left_x <= -128。
            wire signed [16:0] W_px = $signed({S_px[gm][15], S_px[gm]});
            wire S_x_gone = (W_px >= 17'sd20480) || (W_px <= -17'sd2048);
            // 下方同样是完整出屏：水果中心 > 783 等价于左上角 >= 720。
            assign S_gone_mask[gm] = (S_typ[gm] != 2'd0) &&
                                     ( (((S_vy[gm][15] == 1'b0)) &&
                                         (({1'b0, S_py[gm][15:4]} + 13'd64) > 13'd783))
                                       || S_x_gone );
        end
    endgenerate

    // 粒子方向表（8 个方向，固定常量，不占寄存器）
    function signed [9:0] F_pvx;
        input [2:0] I_i;
        begin
            case(I_i)
                3'd0: F_pvx =  10'sd4;  3'd1: F_pvx =  10'sd6;
                3'd2: F_pvx =  10'sd4;  3'd3: F_pvx =  10'sd0;
                3'd4: F_pvx = -10'sd4;  3'd5: F_pvx = -10'sd6;
                3'd6: F_pvx = -10'sd4;  default: F_pvx = 10'sd0;
            endcase
        end
    endfunction
    function signed [9:0] F_pvy;
        input [2:0] I_i;
        begin
            case(I_i)
                3'd0: F_pvy = -10'sd4;  3'd1: F_pvy =  10'sd0;
                3'd2: F_pvy =  10'sd4;  3'd3: F_pvy =  10'sd6;
                3'd4: F_pvy =  10'sd4;  3'd5: F_pvy =  10'sd0;
                3'd6: F_pvy = -10'sd4;  default: F_pvy = -10'sd6;
            endcase
        end
    endfunction

    // 粒子偏移 clamp（±255）
    function signed [8:0] F_pclamp;
        input signed [9:0] I_v;
        begin
            if(I_v > 10'sd255)       F_pclamp = 9'sd255;
            else if(I_v < -10'sd255) F_pclamp = -9'sd255;
            else                     F_pclamp = I_v[8:0];
        end
    endfunction

    // ---- 主状态机（消隐期干活；帧节拍也在块内产生，避免同一根寄存器多驱动）----
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_vs_d      <= 1'b0;
            S_frame_pend<= 1'b0;
            S_ph        <= PH_IDLE;
            S_tr_i      <= 5'd0;
            S_tr_sub    <= 1'b0;
            S_smpr_x    <= 12'd0;
            S_smpr_y    <= 12'd0;
            S_hwr       <= 12'd6;
            S_tipr_x    <= 12'd640;
            S_tipr_y    <= 12'd400;
            S_j_s       <= 4'd0;
            S_j_f       <= 2'd0;
            S_hit_f     <= 3'd0;
            S_cut_en_d  <= 1'b0;
            S_hist_valid<= 1'b0;
            S_cut_dir   <= 3'd2;
            for(oi = 0; oi < 6; oi = oi + 1) begin
                S_px[oi]     <= 16'd0;
                S_py[oi]     <= 16'd0;
                S_vx[oi]     <= 16'd0;
                S_vy[oi]     <= 16'd0;
                S_pal[oi]    <= 2'd0;
                S_typ[oi]    <= 2'd0;
                S_bomb[oi]   <= 1'b0;
                S_half[oi]   <= 1'b0;
                S_axis[oi]   <= 1'b0;
                S_rowoff[oi] <= 2'd0;
                S_missed[oi] <= 1'b0;
            end
            for(oi = 0; oi < 8; oi = oi + 1) begin
                S_hist_x[oi]  <= 12'd640;
                S_hist_y[oi]  <= 12'd400;
                S_pox[oi]     <= 9'sd0;
                S_poy[oi]     <= 9'sd0;
            end
            for(oi = 0; oi < 16; oi = oi + 1) begin
                S_tox[oi] <= 9'sd0;
                S_toy[oi] <= 9'sd0;
            end
            S_trail_en  <= 16'd0;
            S_part_en   <= 8'd0;
            S_part_age  <= 8'd0;
            S_part_bomb <= 1'b0;
            S_burst_x   <= 12'd640;
            S_burst_y   <= 12'd400;
            S_state     <= 8'd1;        // 上电即"运行"：game_mode 一开就能玩
            S_score     <= 8'd0;
            S_score_neg <= 1'b0;
            S_miss_score <= 2'd0;
            S_hit_cnt   <= 16'd0;
            S_miss_cnt  <= 16'd0;
            S_lfsr      <= 16'hACE1;
            S_spawn_cnt <= 8'd0;
            S_still_cnt <= 8'd0;
            S_spin_tick <= 2'd0;
        end
        else begin
            // 帧节拍：vsync 上升沿挂标志，PH_IDLE 消费
            S_vs_d <= I_vsync;
            if(I_vsync & ~S_vs_d) S_frame_pend <= 1'b1;

            // ---- 命令 -----------------------------------------------------
            if(I_restart) begin
                S_state     <= 8'd1;
                S_score     <= 8'd0;
                S_score_neg <= 1'b0;
                S_miss_score <= 2'd0;
                S_hit_cnt   <= 16'd0;
                S_miss_cnt  <= 16'd0;
                for(oi = 0; oi < 6; oi = oi + 1) S_typ[oi] <= 2'd0;
                for(oi = 0; oi < 6; oi = oi + 1) S_bomb[oi] <= 1'b0;
                for(oi = 0; oi < 6; oi = oi + 1) S_missed[oi] <= 1'b0;
                S_part_en   <= 8'd0;
                S_part_bomb <= 1'b0;
                S_trail_en  <= 16'd0;
            end
            else if(I_standby) begin
                S_state     <= 8'd0;
                for(oi = 0; oi < 6; oi = oi + 1) S_typ[oi] <= 2'd0;
                for(oi = 0; oi < 6; oi = oi + 1) S_bomb[oi] <= 1'b0;
                for(oi = 0; oi < 6; oi = oi + 1) S_missed[oi] <= 1'b0;
                S_part_en   <= 8'd0;
                S_part_bomb <= 1'b0;
                S_trail_en  <= 16'd0;
            end

            // cut_enable 上升沿用当前刀锋填满历史；下降沿清空，避免旧轨迹。
            S_cut_en_d <= S_cut_enable;
            if(S_cut_enable && !S_cut_en_d) begin
                for(oi = 0; oi < 8; oi = oi + 1) begin
                    S_hist_x[oi] <= I_blade_x;
                    S_hist_y[oi] <= I_blade_y;
                end
                S_hist_valid <= 1'b1;
                S_still_cnt  <= 8'd0;
            end
            else if(!S_cut_enable && S_cut_en_d) begin
                for(oi = 0; oi < 8; oi = oi + 1) begin
                    S_hist_x[oi] <= 12'd0;
                    S_hist_y[oi] <= 12'd0;
                end
                S_hist_valid <= 1'b0;
                S_still_cnt  <= 8'd0;
            end

            case(S_ph)
            // ----------------------------------------------------------------
            PH_IDLE: if(S_frame_pend) begin
                S_frame_pend <= 1'b0;
                S_ph         <= PH_PHYS;
                S_hit_f      <= 3'd0;      // 帧首清命中；PH_JUDGE 再写
                S_miss_score <= 2'd0;

                // 伪随机
                S_lfsr <= {S_lfsr[14:0], S_lfsr[15] ^ S_lfsr[13] ^ S_lfsr[12] ^ S_lfsr[10]};

                // 半片自旋：每 4 帧换一行偏移
                if(S_spin_tick == 2'd3) begin
                    S_spin_tick <= 2'd0;
                    for(oi = 0; oi < 6; oi = oi + 1)
                        if(S_typ[oi] == 2'd3) S_rowoff[oi] <= S_rowoff[oi] + 2'd1;
                end
                else
                    S_spin_tick <= S_spin_tick + 2'd1;

                // 刀光历史移位（hist[0] = 最新 = 刀尖）
                if(S_cut_enable && S_cut_en_d) begin
                    for(oi = 0; oi < 8; oi = oi + 1) begin
                        if(oi == 0) begin
                            S_hist_x[0] <= I_blade_x;
                            S_hist_y[0] <= I_blade_y;
                        end
                        else begin
                            S_hist_x[oi] <= S_hist_x[oi-1];
                            S_hist_y[oi] <= S_hist_y[oi-1];
                        end
                    end
                end

                // 刀尖静止计数（超过寿命帧 → 灭拖尾）
                if(S_cut_enable && ((I_blade_x != S_hist_x[0]) || (I_blade_y != S_hist_y[0])))
                    S_still_cnt <= 8'd0;
                else if(S_still_cnt != 8'hFF)
                    S_still_cnt <= S_still_cnt + 8'd1;

                // 生成水果：运行态 + 未暂停 + 间隔到 + 有空槽
                if(S_state == 8'd1 && !I_pause && S_fruit_free &&
                   (S_spawn_cnt >= I_spawn_interval)) begin
                    S_spawn_cnt <= 8'd0;
                    S_typ[S_fruit_slot]  <= 2'd2;
                    S_pal[S_fruit_slot]  <= S_lfsr[1:0];
                    S_bomb[S_fruit_slot] <= S_spawn_bomb;
                    S_half[S_fruit_slot] <= 1'b0;
                    S_axis[S_fruit_slot] <= 1'b0;
                    S_rowoff[S_fruit_slot] <= 2'd0;
                    S_missed[S_fruit_slot] <= 1'b0;
                    // 上屏 x = 100 + LFSR[9:0]（100..1123），避开场地左右边界
                    S_px[S_fruit_slot]   <= {4'b0, (12'd100 + {2'b0, S_lfsr[9:0]})} << 4;
                    // 上屏 y = 场地下边界 + 64（从画面下方升起）
                    S_py[S_fruit_slot]   <= S_y_lim + 16'd1024;
                    // 垂直初速：向上（-(v0[15:8] << 5)）
                    S_vy[S_fruit_slot]   <= 16'd0 - {8'b0, I_v0[15:8], 5'b0};
                    // 水平初速：±1~4 px/帧（上板反馈"看着像斜线"：原来到 ±7 px/帧，
                    // 上升 48 帧就横移 336 px，抛物线被拉成斜线了）
                    S_vx[S_fruit_slot]   <= S_lfsr[3] ? (16'd0 - (16'd16 + {10'b0, S_lfsr[1:0], 4'b0}))
                                                      : (16'd16 + {10'b0, S_lfsr[1:0], 4'b0});
                end
                else if(S_spawn_cnt != 8'hFF)
                    S_spawn_cnt <= S_spawn_cnt + 8'd1;
            end
            // ----------------------------------------------------------------
            PH_PHYS: begin
                // 抛体：vel += g；pos += vel（半片同法，被切时速度已经减半）
                for(oi = 0; oi < 6; oi = oi + 1) begin
                    if((S_typ[oi] != 2'd0) && !I_pause) begin
                        S_vy[oi] <= S_vy[oi] + S_dv;
                        S_px[oi] <= S_px[oi] + S_vx[oi];
                        S_py[oi] <= S_py[oi] + S_vy[oi] + S_dv;
                    end
                end

                // 漏切：水果中心落到场地下边界以下且在下行 → 本帧扣 1 分（每颗只记一次），
                // **但不在这里删槽位**——让它继续往下掉，等整颗离开屏幕再消失。
                // （上板反馈：原来一过 704 就把槽清掉，水果还剩 16 px 在屏内就凭空没了）
                if(S_miss_num != 2'd0) begin
                    S_miss_cnt <= S_miss_cnt + {14'b0, S_miss_num};
                    S_miss_score <= S_miss_num;
                    for(oi = 0; oi < 3; oi = oi + 1)
                        if(S_miss_mask[oi]) S_missed[oi] <= 1'b1;
                end

                // 完全离开屏幕 → 回收槽位
                for(oi = 0; oi < 6; oi = oi + 1)
                    if(S_gone_mask[oi]) begin
                        S_typ[oi]    <= 2'd0;
                        S_bomb[oi]   <= 1'b0;
                        S_missed[oi] <= 1'b0;
                    end

                // 粒子：年龄到 → 灭；没灭就按固定方向飞散
                if(S_part_age < I_part_cfg[7:0]) begin
                    S_part_age <= S_part_age + 8'd1;
                    S_part_en  <= 8'hFF;
                    for(oi = 0; oi < 8; oi = oi + 1) begin
                        S_pox[oi] <= F_pclamp($signed({S_pox[oi][8], S_pox[oi]}) +
                                              F_pvx(oi[2:0]));
                        S_poy[oi] <= F_pclamp($signed({S_poy[oi][8], S_poy[oi]}) +
                                              F_pvy(oi[2:0]));
                    end
                end
                else
                    S_part_en <= 8'h00;

                S_ph   <= PH_TRAIL;
                S_tr_i <= 5'd0;
                S_tr_sub <= 1'b0;
            end
            // ----------------------------------------------------------------
            PH_TRAIL: begin
                // 两个拍：先把"采样点/半宽/刀尖"锁进寄存器，再算偏移写进数组。
                // 这样 S_j_s/S_tr_i 到 S_tox 的路径被切开（2026-09-26 实测最紧路径
                // 就是这条 13 级组合，slack 只有 0.477 ns）。
                if(!S_tr_sub) begin
                    S_smpr_x <= S_smp_x;
                    S_smpr_y <= S_smp_y;
                    S_hwr    <= (S_tr_i == 5'd15) ? 12'd8 : 12'd6;
                    S_tipr_x <= S_tip_x;
                    S_tipr_y <= S_tip_y;
                    S_tr_sub <= 1'b1;
                end
                else begin
                    S_tox[S_tr_i[3:0]] <= S_off_x;
                    S_toy[S_tr_i[3:0]] <= S_off_y;
                    S_tr_sub <= 1'b0;

                    if(S_tr_i == 5'd15) begin
                        // 拖尾开关：刀尖动过、且静止没超过寿命帧
                        S_trail_en <= (S_still_cnt < I_trail_cfg[7:0]) ? 16'hFFFF : 16'h0000;
                        S_j_s      <= 4'd0;
                        S_j_f      <= 2'd0;
                        if((BLADE_CUT_EN != 0) && (CUT_MODE == 0) &&
                           S_cut_enable && S_hist_valid)
                            S_ph <= PH_JUDGE;
                        else
                            S_ph <= PH_ACT;
                    end
                    else
                        S_tr_i <= S_tr_i + 5'd1;
                end
            end
            // ----------------------------------------------------------------
            PH_JUDGE: begin
                // 16 个采样点 × 3 个活动水果槽，每拍判一个组合。
                // S_pair_ok 已经包含“在屏内 + 落在 74 px 外扩 AABB 内”。
                if(S_pair_ok) begin
                    S_hit_f[S_j_f] <= 1'b1;
                    // 采样按 0(最旧) → 15(刀尖) 遍历；后面的命中段更新方向，
                    // 因而最终采用最靠近当前刀尖的命中段。
                    if(S_cut_dir_valid) S_cut_dir <= S_cut_dir_new;
                end

                if(S_j_f == 2'd2) begin
                    S_j_f <= 2'd0;
                    if(S_j_s == 4'd15) S_ph <= PH_ACT;
                    else               S_j_s <= S_j_s + 4'd1;
                end
                else begin
                    S_j_f <= S_j_f + 2'd1;
                end
            end
            // ----------------------------------------------------------------
            PH_ACT: begin
                // 本帧分数一次性合并：水果 +1、炸弹 -5、漏掉水果 -1。
                if(S_score_event) begin
                    S_score     <= S_score_next[7:0];
                    S_score_neg <= S_score_next[8];
                end

                // 命中特效：普通水果使用黄色小粒子；炸弹使用橙红色大粒子。
                if(|S_hit_f) begin
                    S_part_age<= 8'd0;
                    S_part_en <= 8'hFF;
                    S_part_bomb <= (S_bomb_hit_num != 2'd0);
                    for(oi = 0; oi < 8; oi = oi + 1) begin
                        // 爆点表示对象中心；印章坐标是左上角，所以先回退半个印章。
                        S_pox[oi] <= (S_bomb_hit_num != 2'd0) ? -9'sd6 : -9'sd3;
                        S_poy[oi] <= (S_bomb_hit_num != 2'd0) ? -9'sd6 : -9'sd3;
                    end
                    // 同帧同时命中炸弹与水果时，爆点优先取炸弹。
                    if(S_bomb_hit_f[0]) begin
                        S_burst_x <= S_px[0][15:4] + 12'd64;
                        S_burst_y <= S_py[0][15:4] + 12'd64;
                    end
                    else if(S_bomb_hit_f[1]) begin
                        S_burst_x <= S_px[1][15:4] + 12'd64;
                        S_burst_y <= S_py[1][15:4] + 12'd64;
                    end
                    else if(S_bomb_hit_f[2]) begin
                        S_burst_x <= S_px[2][15:4] + 12'd64;
                        S_burst_y <= S_py[2][15:4] + 12'd64;
                    end
                    else if(S_fruit_hit_f[0]) begin
                        S_burst_x <= S_px[0][15:4] + 12'd64;
                        S_burst_y <= S_py[0][15:4] + 12'd64;
                    end
                    else if(S_fruit_hit_f[1]) begin
                        S_burst_x <= S_px[1][15:4] + 12'd64;
                        S_burst_y <= S_py[1][15:4] + 12'd64;
                    end
                    else begin
                        S_burst_x <= S_px[2][15:4] + 12'd64;
                        S_burst_y <= S_py[2][15:4] + 12'd64;
                    end
                end

                // 水果：保留原计分粒子/半片；炸弹只消失并触发爆炸，不产生半片。
                if(S_fruit_hit_num != 2'd0) begin
                    S_hit_cnt <= S_hit_cnt + {14'b0, S_fruit_hit_num};
                    for(oi = 0; oi < 3; oi = oi + 1) begin
                        if(S_fruit_hit_f[oi]) begin
                            S_typ[oi]    <= 2'd3;               // 原地变半片 A
                            S_bomb[oi]   <= 1'b0;
                            S_half[oi]   <= 1'b0;
                            S_axis[oi]   <= S_split_h;
                            S_rowoff[oi] <= 2'd0;
                            if(S_split_h) begin
                                // 水平挥切：A 是上半片，保留原位置并向斜上飞。
                                S_vx[oi] <= F_half_vel(S_vx[oi]);
                                S_vy[oi] <= F_half_vel(S_vy[oi]) - 16'd32;
                            end
                            else begin
                                // 竖直挥切：A 是左半片，窗口起点保持不动。
                                S_vx[oi] <= 16'd0 - F_half_vel(S_vx[oi]) - 16'd32;
                                S_vy[oi] <= F_half_vel(S_vy[oi]) - 16'd32;
                            end
                        end
                    end

                    // 半片 B：借第一个空备用槽（槽满时第二片不出，判定与计分不受影响）
                    if(S_spare_free) begin
                        if(S_fruit_hit_f[0]) begin
                            S_typ[S_spare_slot]   <= 2'd3;
                            S_bomb[S_spare_slot]  <= 1'b0;
                            S_half[S_spare_slot]  <= 1'b1;
                            S_axis[S_spare_slot]  <= S_split_h;
                            S_rowoff[S_spare_slot]<= 2'd0;
                            S_pal[S_spare_slot]   <= S_pal[0];
                            if(S_split_h) begin
                                // 水平挥切：B 是下半片，向下移动 64 px 并向斜下飞。
                                S_px[S_spare_slot] <= S_px[0];
                                S_py[S_spare_slot] <= S_py[0] + 16'd1024;
                                S_vx[S_spare_slot] <= F_half_vel(S_vx[0]);
                                S_vy[S_spare_slot] <= F_half_vel(S_vy[0]) + 16'd32;
                            end
                            else begin
                                // 竖直挥切：B 是右半片，向右移动 64 px。
                                S_px[S_spare_slot] <= S_px[0] + 16'd1024;
                                S_py[S_spare_slot] <= S_py[0];
                                S_vx[S_spare_slot] <= F_half_vel(S_vx[0]) + 16'd32;
                                S_vy[S_spare_slot] <= F_half_vel(S_vy[0]) - 16'd32;
                            end
                        end
                        else if(S_fruit_hit_f[1]) begin
                            S_typ[S_spare_slot]   <= 2'd3;
                            S_bomb[S_spare_slot]  <= 1'b0;
                            S_half[S_spare_slot]  <= 1'b1;
                            S_axis[S_spare_slot]  <= S_split_h;
                            S_rowoff[S_spare_slot]<= 2'd0;
                            S_pal[S_spare_slot]   <= S_pal[1];
                            if(S_split_h) begin
                                S_px[S_spare_slot] <= S_px[1];
                                S_py[S_spare_slot] <= S_py[1] + 16'd1024;
                                S_vx[S_spare_slot] <= F_half_vel(S_vx[1]);
                                S_vy[S_spare_slot] <= F_half_vel(S_vy[1]) + 16'd32;
                            end
                            else begin
                                S_px[S_spare_slot] <= S_px[1] + 16'd1024;
                                S_py[S_spare_slot] <= S_py[1];
                                S_vx[S_spare_slot] <= F_half_vel(S_vx[1]) + 16'd32;
                                S_vy[S_spare_slot] <= F_half_vel(S_vy[1]) - 16'd32;
                            end
                        end
                        else begin
                            S_typ[S_spare_slot]   <= 2'd3;
                            S_bomb[S_spare_slot]  <= 1'b0;
                            S_half[S_spare_slot]  <= 1'b1;
                            S_axis[S_spare_slot]  <= S_split_h;
                            S_rowoff[S_spare_slot]<= 2'd0;
                            S_pal[S_spare_slot]   <= S_pal[2];
                            if(S_split_h) begin
                                S_px[S_spare_slot] <= S_px[2];
                                S_py[S_spare_slot] <= S_py[2] + 16'd1024;
                                S_vx[S_spare_slot] <= F_half_vel(S_vx[2]);
                                S_vy[S_spare_slot] <= F_half_vel(S_vy[2]) + 16'd32;
                            end
                            else begin
                                S_px[S_spare_slot] <= S_px[2] + 16'd1024;
                                S_py[S_spare_slot] <= S_py[2];
                                S_vx[S_spare_slot] <= F_half_vel(S_vx[2]) + 16'd32;
                                S_vy[S_spare_slot] <= F_half_vel(S_vy[2]) - 16'd32;
                            end
                        end
                    end
                end
                for(oi = 0; oi < 3; oi = oi + 1)
                    if(S_bomb_hit_f[oi]) begin
                        S_typ[oi]    <= 2'd0;
                        S_bomb[oi]   <= 1'b0;
                        S_missed[oi] <= 1'b0;
                    end

                S_ph <= PH_END;
            end
            // ----------------------------------------------------------------
            PH_END: S_ph <= PH_IDLE;
            default: S_ph <= PH_IDLE;
            endcase
        end
    end

    // ---- 对象表输出（6 槽 × 48 位）----------------------------------------
    genvar go;
    generate
        for (go = 0; go < 6; go = go + 1) begin : g_obj
            wire        W_idle = (S_typ[go] == 2'd0);
            wire        W_is_h = (S_typ[go] == 2'd3);
            wire [1:0]  W_t = W_idle ? 2'd2 : S_typ[go];
            wire [11:0] W_x = W_idle ? 12'd2000 : S_px[go][15:4];
            wire [11:0] W_y = W_idle ? 12'd0    : S_py[go][15:4];
            wire        W_axis = W_is_h && S_axis[go];
            // 左右半片各 64×128；上下半片各 128×64。
            wire [4:0]  W_w = W_idle ? 5'd0 : ((W_is_h && !W_axis) ? 5'd15 : 5'd31);
            wire [4:0]  W_h = W_idle ? 5'd0 : ((W_is_h &&  W_axis) ? 5'd15 : 5'd31);
            // color[6] = 切割轴，color[5:4] = 左右半片的行偏移。
            wire [7:0]  W_c = {1'b0, W_axis,
                               ((W_is_h && !W_axis) ? S_rowoff[go] : 2'd0), 4'b0};
            // pal[3] = 半片 A/B 侧（普通对象则为炸弹标志），pal[2] = 负 x，
            // pal[1:0] = 水果种类。
            wire        W_x_neg = !W_idle && S_px[go][15];
            wire [3:0]  W_p = {W_is_h ? S_half[go] : S_bomb[go],
                               W_x_neg, S_pal[go]};

            assign O_obj[go*48 +: 48] = {W_t, W_x, W_y, W_w, W_h, W_c, W_p};
        end
    endgenerate

    // ---- 拖尾 / 粒子 / 观测输出 -------------------------------------------
    genvar ga;
    generate
        for (ga = 0; ga < 16; ga = ga + 1) begin : g_trail_off
            assign O_trail_off[ga*18 +: 18] = {S_toy[ga], S_tox[ga]};
        end
        for (ga = 0; ga < 8; ga = ga + 1) begin : g_part_off
            assign O_part_off[ga*18 +: 18] = {S_poy[ga], S_pox[ga]};
        end
    endgenerate

    assign O_tip_x   = S_tip_x;
    assign O_tip_y   = S_tip_y;
    assign O_trail_en= S_trail_en;
    assign O_burst_x = S_burst_x;
    assign O_burst_y = S_burst_y;
    assign O_part_en = S_part_en;

    assign O_part_bomb= S_part_bomb;
    assign O_score    = {S_score_neg, S_score};
    assign O_state    = S_state[3:0];
    assign O_hit_cnt  = S_hit_cnt;
    assign O_miss_cnt = S_miss_cnt;
    assign O_fruit1_x = S_px[0][15:4];
    assign O_fruit1_y = S_py[0][15:4];
    assign O_state_word = {S_state[3:0], 3'b000, S_score_neg, S_score};
    assign O_blade_pos  = {S_tip_x[10:3], S_tip_y[10:3]};

endmodule
