// ============================================================================
// game_top —— RENDER_SLOT 插座（像素域，DDR 读回与 OSD 之间）
//
// 位置：`video_out.O_vdieo_data` → `game_top` → `hdmi_mixer.I_video_rd_data`。
// 边界必须 **0 拍组合**：hdmi_mixer 内部用 `S_x_2d/S_y_2d` 画 OSD，这里插一拍寄存器，
// OSD 就会相对画面错开一个像素。所以本模块的做法是"**判属前视一拍**"：
//   * 本拍用"下一个 de 像素"的坐标（`S_x_nxt/S_y_nxt`）算判属，结果寄存一拍；
//   * 下一拍正是那个像素到达的时候 → `O_pixel_out` 与 `I_pixel_in` **同拍**；
//   * 精灵 ERAM 的地址也在本拍给出，数据下一拍到，与判属结果同拍对齐（见 game_render）。
//
// 子模块（都在 `hdl_source/game/`，B 独占）：
//   game_param       B 段参数寄存器（0x80~0xBF，地址表见 README §12.2.1）
//   game_input       输入抽象层：假源 / 手势 / 手柄预留 → 刀尖坐标
//   game_fruit       切水果本体：物理 / 生成 / 判定 / 分数 / 拖尾粒子数据
//   game_catch       接果篮本体：下落对象 / 开口跨线判定 / 难度 / 分数
//   game_score       单帧有符号 BCD 分数结算
//   game_sprite_rom  水果与炸弹精灵 ERAM（5 种 × 32×32 RGB332）
//   game_render      逐像素判属（分数 > 拖尾 > 粒子 > 对象表）与图层 mux
//
// 游戏选择：I_game_mode = 0 关层，1 切水果，2 接果篮。每次编号变化都重开当前游戏。
//
// 与 C 的接线（本轮**未接也能跑**，未驱动输入被 TD 当 0 → 全部走默认值）：
//   * `I_param_*` / `O_param_rd_data`：param_ctrl 的 B 段转发（需求单 2）；
//   * `I_ctrl_x/y/valid`：A 的手势结果（需求单 1，走 VIDEO_TAP 观测包的扩展）；
//   * `I_ctrl_down_data/valid`：M4c 起由 C 用 shape_gen 的描述子驱动（需求单 3），
//     本轮为空 → 照旧每帧发 {x=0x0A5, y=0x0D3, display_mode} 的往返自检字。
//
// 旁路：`I_bypass = (game_mode == 0)`（顶层给），此时 `O_pixel_out` 逐位等于 `I_pixel_in`，
// 且 `I_de == 0` 时也逐位透传——L4 旁路回归就靠这条。
//
// 延迟：对外 0 拍（内部判属 1 拍，被"前视一拍"抵消）。
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// 资源：见各子模块头注释；两款游戏共享输入、参数、精灵 ROM、渲染和分数显示。
// ============================================================================
module game_top #(
    parameter integer TRAIL_EN  = 0,   // 1 = 画刀光拖尾
    parameter integer PART_EN   = 1,   // 1 = 画命中粒子/炸弹爆炸
    parameter integer BLADE_CUT_EN = 1, // 1 = 每帧刀锋轨迹连续判定
    parameter integer CUT_MODE = 0      // 本轮只实现 0 = 8 历史点 + 16 采样 + AABB
) (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_vsync,
    input  wire        I_de,
    input  wire [23:0] I_pixel_in,
    input  wire        I_bypass,        // 1 = 游戏层整体旁路（game_mode == 0）
    input  wire [3:0]  I_game_mode,
    input  wire [3:0]  I_display_mode,
    output wire [23:0] O_pixel_out,
    output wire [25:0] O_ctrl_tx_data,  // {x[10:0], y[10:0], state[3:0]}
    output wire        O_ctrl_tx_valid,

    // ---- B 段参数总线（C 在顶层接 param_ctrl 的转发口，见需求单 2）----------
    input  wire        I_param_we,
    input  wire [5:0]  I_param_addr,    // 系统地址低 6 位
    input  wire [15:0] I_param_wdata,
    input  wire [7:0]  I_param_rd_addr,
    output wire [15:0] O_param_rd_data,

    // ---- 手势源（C 在顶层接 A 的识别结果，见需求单 1）----------------------
    input  wire [10:0] I_ctrl_x,
    input  wire [10:0] I_ctrl_y,
    input  wire        I_ctrl_valid,

    // ---- CTRL_SYNC 下行（M4c 起由 C 驱动；本轮为空 → 发自检字，见需求单 3）--
    input  wire [25:0] I_ctrl_down_data,
    input  wire        I_ctrl_down_valid
);

    // ------------------------------------------------------------------------
    // 坐标生成（与 hdmi_mixer 的 S_x/S_y 同拍同坐标；模板见 B 线规划 §4.2）
    //   x = 本行第 k 个 de 拍（0 基）；y = 本帧第几行（0 基）
    // ------------------------------------------------------------------------
    reg [11:0] S_x, S_y;
    reg        S_de_d, S_vs_d, S_frame_pend;

    wire S_vs_rise = I_vsync & ~S_vs_d;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_x          <= 12'd0;
            S_y          <= 12'd0;
            S_de_d       <= 1'b0;
            S_vs_d       <= 1'b0;
            S_frame_pend <= 1'b0;
        end
        else begin
            S_de_d <= I_de;
            S_vs_d <= I_vsync;

            if(S_vs_rise) S_frame_pend <= 1'b1;

            if(I_de) begin
                S_x <= S_x + 12'd1;         // 第 k 个 de 拍读到的 x 就是 k
            end
            else begin
                S_x <= 12'd0;               // 行间/消隐清 0，下一个 de 拍即 x = 0
                if(S_frame_pend) begin      // 帧首优先于"行尾 +1"
                    S_y          <= 12'd0;
                    S_frame_pend <= 1'b0;
                end
                else if(S_de_d)
                    S_y <= S_y + 12'd1;
            end
        end
    end

    // **前视一拍**：下一个 de 像素的坐标（行首/消隐处给 0，必然落在所有窗口外）
    wire [11:0] S_x_nxt = I_de ? (S_x + 12'd1) : 12'd0;
    wire [11:0] S_y_nxt = I_de ? S_y : (S_de_d ? (S_y + 12'd1) : S_y);

    // ------------------------------------------------------------------------
    // B 段参数寄存器
    // ------------------------------------------------------------------------
    wire [3:0]  S_input_src;
    wire [15:0] S_input_cfg, S_input_gain, S_input_offset;
    wire [7:0]  S_fruit_spawn;
    wire [7:0]  S_catch_spawn;
    wire [15:0] S_fruit_grav, S_fruit_v0, S_trail_cfg, S_part_cfg;
    wire [15:0] S_catch_cfg;
    wire [11:0] S_field_y0, S_field_y1;
    wire [11:0] S_dbg_blade_x, S_dbg_blade_y;
    wire        S_dbg_blade_en, S_dbg_marker_en;
    wire        S_cmd_restart, S_cmd_standby, S_cmd_pause;
    wire [15:0] S_state_word, S_blade_pos, S_hit_cnt, S_miss_cnt;
    wire [3:0]  S_state;
    wire [11:0] S_fruit1_x, S_fruit1_y;
    wire [15:0] S_fruit_pos = {S_fruit1_x[10:3], S_fruit1_y[10:3]};

    // game_mode：0 = 关，1 = 切水果，2 = 接果篮。每次模式变化都重开新局，
    // 包括 1→2 的直接切换；否则旧分数和对象会带到另一款游戏。
    reg [3:0] S_game_mode_d;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) S_game_mode_d <= 4'd0;
        else         S_game_mode_d <= I_game_mode;
    end
    wire S_game_changed = (I_game_mode != S_game_mode_d);
    wire S_is_fruit = (I_game_mode == 4'd1);
    wire S_is_catch = (I_game_mode == 4'd2);

    game_param u_game_param (
        .I_clk          (I_clk            ),
        .I_rst_n        (I_rst_n          ),
        .I_we           (I_param_we       ),
        .I_addr         (I_param_addr     ),
        .I_wdata        (I_param_wdata    ),
        .I_rd_addr      (I_param_rd_addr  ),
        .O_rd_data      (O_param_rd_data  ),
        .I_state_word   (S_state_word     ),
        .I_blade_pos    (S_blade_pos      ),
        .I_fruit_pos    (S_fruit_pos      ),
        .I_hit_cnt      (S_hit_cnt        ),
        .I_miss_cnt     (S_miss_cnt       ),
        .O_game_sel     (S_game_sel       ),
        .O_restart      (S_cmd_restart    ),
        .O_standby      (S_cmd_standby    ),
        .O_pause        (S_cmd_pause      ),
        .O_input_src    (S_input_src      ),
        .O_input_cfg    (S_input_cfg      ),
        .O_input_gain   (S_input_gain     ),
        .O_input_offset (S_input_offset   ),
        .O_fruit_spawn  (S_fruit_spawn    ),
        .O_fruit_grav   (S_fruit_grav     ),
        .O_fruit_v0     (S_fruit_v0       ),
        .O_catch_spawn  (S_catch_spawn    ),
        .O_catch_cfg    (S_catch_cfg      ),
        .O_trail_cfg    (S_trail_cfg      ),
        .O_particle_cfg (S_part_cfg       ),
        .O_field_y0     (S_field_y0       ),
        .O_field_y1     (S_field_y1       ),
        .O_dbg_blade_x  (S_dbg_blade_x    ),
        .O_dbg_blade_y  (S_dbg_blade_y    ),
        .O_dbg_blade_en (S_dbg_blade_en   ),
        .O_dbg_marker_en(S_dbg_marker_en  )
    );

    // ------------------------------------------------------------------------
    // 输入抽象层
    // ------------------------------------------------------------------------
    wire [11:0] S_blade_x, S_blade_y;
    wire        S_blade_valid;
    wire [11:0] S_fake_x, S_fake_y;

    game_input u_game_input (
        .I_clk       (I_clk          ),
        .I_rst_n     (I_rst_n        ),
        .I_vsync     (I_vsync        ),
        .I_src       (S_input_src    ),
        .I_cfg       (S_input_cfg    ),
        .I_gain      (S_input_gain   ),
        .I_offset    (S_input_offset ),
        .I_field_y0  (S_field_y0     ),
        .I_field_y1  (S_field_y1     ),
        .I_dbg_x     (S_dbg_blade_x  ),
        .I_dbg_y     (S_dbg_blade_y  ),
        .I_dbg_en    (S_dbg_blade_en ),
        .I_ctrl_x    (I_ctrl_x       ),
        .I_ctrl_y    (I_ctrl_y       ),
        .I_ctrl_valid(I_ctrl_valid   ),
        .O_x         (S_blade_x      ),
        .O_y         (S_blade_y      ),
        .O_valid     (S_blade_valid  ),
        .O_fake_x    (S_fake_x       ),
        .O_fake_y    (S_fake_y       )
    );

    // ------------------------------------------------------------------------
    // 两款游戏共用的输出接口：game_top 在下面按 game_mode 做 mux。
    // ------------------------------------------------------------------------
    wire [287:0] S_fruit_obj, S_catch_obj;
    wire [287:0] S_obj = S_is_catch ? S_catch_obj : S_fruit_obj;
    wire [11:0]  S_fruit_tip_x, S_fruit_tip_y;
    wire [11:0]  S_tip_x = S_fruit_tip_x;
    wire [11:0]  S_tip_y = S_fruit_tip_y;
    wire [287:0] S_fruit_trail_off;
    wire [287:0] S_trail_off = S_fruit_trail_off;
    wire [15:0]  S_fruit_trail_en;
    wire [15:0]  S_trail_en = S_is_catch ? 16'h0000 : S_fruit_trail_en;
    wire [11:0]  S_fruit_burst_x, S_fruit_burst_y;
    wire [11:0]  S_catch_burst_x, S_catch_burst_y;
    wire [11:0]  S_burst_x = S_is_catch ? S_catch_burst_x : S_fruit_burst_x;
    wire [11:0]  S_burst_y = S_is_catch ? S_catch_burst_y : S_fruit_burst_y;
    wire [143:0] S_fruit_part_off, S_catch_part_off;
    wire [143:0] S_part_off = S_is_catch ? S_catch_part_off : S_fruit_part_off;
    wire [7:0]   S_fruit_part_en, S_catch_part_en;
    wire [7:0]   S_part_en = S_is_catch ? S_catch_part_en : S_fruit_part_en;
    wire         S_fruit_part_bomb, S_catch_part_bomb;
    wire         S_part_bomb = S_is_catch ? S_catch_part_bomb : S_fruit_part_bomb;
    wire [8:0]   S_fruit_score, S_catch_score;
    wire [8:0]   S_score = S_is_catch ? S_catch_score : S_fruit_score;
    wire [3:0]   S_fruit_state, S_catch_state;
    wire [3:0]   S_state = S_is_catch ? S_catch_state : S_fruit_state;
    wire [15:0]  S_fruit_hit_cnt, S_catch_hit_cnt;
    wire [15:0]  S_hit_cnt = S_is_catch ? S_catch_hit_cnt : S_fruit_hit_cnt;
    wire [15:0]  S_fruit_miss_cnt, S_catch_miss_cnt;
    wire [15:0]  S_miss_cnt = S_is_catch ? S_catch_miss_cnt : S_fruit_miss_cnt;
    wire [11:0]  S_fruit_game1_x, S_fruit_game1_y;
    wire [11:0]  S_catch_game1_x, S_catch_game1_y;
    wire [11:0]  S_fruit1_x = S_is_catch ? S_catch_game1_x : S_fruit_game1_x;
    wire [11:0]  S_fruit1_y = S_is_catch ? S_catch_game1_y : S_fruit_game1_y;
    wire [15:0]  S_fruit_state_word, S_catch_state_word;
    wire [15:0]  S_state_word = S_is_catch ? S_catch_state_word : S_fruit_state_word;
    assign S_blade_pos = {S_blade_x[10:3], S_blade_y[10:3]};
    wire [11:0]  S_catch_basket_center;
    wire [7:0]   S_catch_speed;

    game_fruit #(
        .BLADE_CUT_EN  (BLADE_CUT_EN  ),
        .CUT_MODE      (CUT_MODE      )
    ) u_game_fruit (
        .I_clk           (I_clk          ),
        .I_rst_n         (I_rst_n        ),
        .I_vsync         (I_vsync        ),
        .I_spawn_interval(S_fruit_spawn  ),
        .I_grav          (S_fruit_grav   ),
        .I_v0            (S_fruit_v0     ),
        .I_trail_cfg     (S_trail_cfg    ),
        .I_part_cfg      (S_part_cfg     ),
        .I_field_y1      (S_field_y1     ),
        .I_restart       (S_cmd_restart | S_game_changed),
        .I_standby       (S_cmd_standby  ),
        .I_pause         (S_cmd_pause | ~S_is_fruit),
        .I_blade_x       (S_blade_x      ),
        .I_blade_y       (S_blade_y      ),
        .I_blade_valid   (S_blade_valid  ),
        .I_track_locked  (I_ctrl_valid   ),
        .I_cut_src_ok    (S_input_src == 4'd1),
        .O_obj           (S_fruit_obj        ),
        .O_tip_x         (S_fruit_tip_x      ),
        .O_tip_y         (S_fruit_tip_y      ),
        .O_trail_off     (S_fruit_trail_off  ),
        .O_trail_en      (S_fruit_trail_en   ),
        .O_burst_x       (S_fruit_burst_x    ),
        .O_burst_y       (S_fruit_burst_y    ),
        .O_part_off      (S_fruit_part_off   ),
        .O_part_en       (S_fruit_part_en    ),
        .O_part_bomb     (S_fruit_part_bomb  ),
        .O_score         (S_fruit_score      ),
        .O_state         (S_fruit_state      ),
        .O_hit_cnt       (S_fruit_hit_cnt    ),
        .O_miss_cnt      (S_fruit_miss_cnt   ),
        .O_fruit1_x      (S_fruit_game1_x    ),
        .O_fruit1_y      (S_fruit_game1_y    ),
        .O_state_word    (S_fruit_state_word ),
        .O_blade_pos     (                   )
    );

    // ------------------------------------------------------------------------
    // 接果篮本体
    // ------------------------------------------------------------------------
    game_catch u_game_catch (
        .I_clk           (I_clk            ),
        .I_rst_n         (I_rst_n          ),
        .I_vsync         (I_vsync          ),
        .I_spawn_interval(S_catch_spawn    ),
        .I_catch_cfg     (S_catch_cfg      ),
        .I_restart       (S_cmd_restart | S_game_changed),
        .I_standby       (S_cmd_standby    ),
        .I_pause         (S_cmd_pause | ~S_is_catch),
        .I_blade_x       (S_blade_x        ),
        .O_obj           (S_catch_obj      ),
        .O_burst_x       (S_catch_burst_x  ),
        .O_burst_y       (S_catch_burst_y  ),
        .O_part_off      (S_catch_part_off ),
        .O_part_en       (S_catch_part_en  ),
        .O_part_bomb     (S_catch_part_bomb),
        .O_score         (S_catch_score    ),
        .O_state         (S_catch_state    ),
        .O_hit_cnt       (S_catch_hit_cnt  ),
        .O_miss_cnt      (S_catch_miss_cnt ),
        .O_fruit1_x      (S_catch_game1_x  ),
        .O_fruit1_y      (S_catch_game1_y  ),
        .O_state_word    (S_catch_state_word),
        .O_basket_center (S_catch_basket_center),
        .O_speed         (S_catch_speed    )
    );

    // ------------------------------------------------------------------------
    // 精灵 ROM + 逐像素判属
    // ------------------------------------------------------------------------
    wire [12:0] S_spr_addr;
    wire [7:0]  S_spr_px;

    game_sprite_rom u_game_sprite_rom (
        .I_clk   (I_clk       ),
        .I_addr  (S_spr_addr  ),
        .O_pixel (S_spr_px    )
    );

    wire        S_render_hit;
    wire [23:0] S_render_col;

    game_render u_game_render (
        .I_clk         (I_clk          ),
        .I_rst_n       (I_rst_n        ),
        .I_de          (I_de           ),
        .I_x_nxt       (S_x_nxt        ),
        .I_y_nxt       (S_y_nxt        ),
        .I_display_mode(I_display_mode ),
        .I_basket_en   (S_is_catch     ),
        .I_basket_center(S_catch_basket_center),
        .I_obj         (S_obj          ),
        .I_tip_x       (S_tip_x        ),
        .I_tip_y       (S_tip_y        ),
        .I_trail_off   (S_trail_off    ),
        .I_trail_en    (TRAIL_EN ? S_trail_en : 16'h0000),
        .I_burst_x     (S_burst_x      ),
        .I_burst_y     (S_burst_y      ),
        .I_part_off    (S_part_off     ),
        .I_part_en     (PART_EN  ? S_part_en  : 8'h00),
        .I_part_bomb   (S_part_bomb    ),
        .I_score       (S_score        ),
        .I_state       (S_state        ),
        .I_marker_en   (S_dbg_marker_en),
        .O_spr_addr    (S_spr_addr     ),
        .I_spr_px      (S_spr_px       ),
        .O_hit         (S_render_hit   ),
        .O_color       (S_render_col   )
    );

    // 0 拍叠加：非 de 或旁路时逐位透传（L4 旁路回归靠这条）
    assign O_pixel_out = (I_de & ~I_bypass & S_render_hit) ? S_render_col : I_pixel_in;

    // ------------------------------------------------------------------------
    // CTRL_SYNC 下行：M0 起每帧第一个 de 发一个往返自检字；
    // M4c 起 C 用 I_ctrl_down_valid 顶替（形状描述子）。
    // ------------------------------------------------------------------------
    reg S_frame_tx_pending;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            S_frame_tx_pending <= 1'b0;
        else if(S_vs_rise)
            S_frame_tx_pending <= 1'b1;
        else if(I_de && S_frame_tx_pending)
            S_frame_tx_pending <= 1'b0;
    end

    // 测试常数：x = 0x0A5(=165)、y = 0x0D3(=211)，state 带上当前模式；
    // 上板后用 DBG 行的 X/Y 字段核对往返（README §7 / §12.4）。
    assign O_ctrl_tx_valid = I_ctrl_down_valid | (I_de & S_frame_tx_pending);
    assign O_ctrl_tx_data  = I_ctrl_down_valid ? I_ctrl_down_data
                                               : {11'h0A5, 11'h0D3, I_display_mode};

endmodule
