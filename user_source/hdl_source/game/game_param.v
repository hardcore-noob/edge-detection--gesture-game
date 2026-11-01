// ============================================================================
// game_param —— B 段参数寄存器文件（0x80~0xBF）与读回
//
// 位置：`game/game_top.v` 内实例化。地址表见 README §12.2.1 与
// `B-游戏引擎实现规划.md` §6（0x80~0xBF 归 B，编译期冻结）。
//
// 写口约定（与 C 的 param_ctrl 转发口对接，端口名见 §9 需求 2）：
//   I_we / I_addr[5:0] / I_wdata[15:0]，单拍脉冲；I_addr = 系统地址的低 6 位
//   （0x80 → 0x00、0x85 → 0x05、0x8E → 0x0E、0x90 → 0x10、0xA0 → 0x20）。
//   在 C 开通转发之前，这个口悬空（TD 会把未驱动输入当 0），模块行为 = 全部默认值。
//
// 只读观测（0x90~0x94）由 game_fruit / game_input 驱动（I_state_word 等），
// 不是本模块自己算的——本模块只做"选通 + 回读"。
//
// 单位约定（写进模块头，改之前先看）：
//   fruit_grav[15:0] : 重力，单位 **1/256 上屏像素 / 帧²**（默认 0x40 = 0.25 px/帧²）
//   fruit_v0[15:0]   : {垂直发射速度[7:0], 水平散布[7:0]}；垂直速度单位 1/2 上屏像素/帧
//                      （默认 0x0600 → 6×2 = 12 px/帧 向上），水平散布按 ±N px/帧 随机取
//   catch_spawn      : 接果篮生成间隔（帧，默认 72）
//   catch_cfg[15:8]  : 接果篮初始下落速度（1..9 px/帧）
//   catch_cfg[7:0]   : 每 N×16 帧加速一次（0 = 不加速，默认 0x32 = 800 帧）
//   trail_cfg[15:0]  : {历史点数[7:0], 静止寿命帧[7:0]}（默认 {8,10}）
//   particle_cfg     : {粒子数[7:0], 寿命帧[7:0]}（默认 {8,20}）
//
// 延迟：写完下一拍生效；读回是组合（同 param_ctrl 的语义）。
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// 资源：约 200 FF + 150 LUT6，无 ERAM / DSP。
// ============================================================================
module game_param #(
    parameter integer CLK_HZ = 75000000
) (
    input  wire        I_clk,
    input  wire        I_rst_n,

    // ---- B 段写口（来自 C 的 param_ctrl 转发）------------------------------
    input  wire        I_we,
    input  wire [5:0]  I_addr,      // 系统地址的低 6 位
    input  wire [15:0] I_wdata,

    // ---- 读回（C 在顶层按地址段选择）-------------------------------------
    input  wire [7:0]  I_rd_addr,
    output reg  [15:0] O_rd_data,

    // ---- 只读观测（由 game_fruit / game_input 驱动）------------------------
    input  wire [15:0] I_state_word,   // {state[3:0], 3'b0, score_neg, score_bcd[7:0]}
    input  wire [15:0] I_blade_pos,    // {x>>3[7:0], y>>3[7:0]}
    input  wire [15:0] I_fruit_pos,    // 1 号水果 {x>>3[7:0], y>>3[7:0]}
    input  wire [15:0] I_hit_cnt,
    input  wire [15:0] I_miss_cnt,

    // ---- 参数输出 ---------------------------------------------------------
    output reg  [3:0]  O_game_sel,     // 0x80 兼容字段；当前游戏路由以 game_mode 为准
    output reg         O_restart,      // 0x81 bit0：单拍脉冲
    output reg         O_standby,      // 0x81 bit1/bit2：单拍脉冲（回待机）
    output reg         O_pause,        // 0x81 bit3：电平
    output reg  [3:0]  O_input_src,
    output reg  [15:0] O_input_cfg,
    output reg  [15:0] O_input_gain,
    output reg  [15:0] O_input_offset,
    output reg  [7:0]  O_fruit_spawn,
    output reg  [15:0] O_fruit_grav,
    output reg  [15:0] O_fruit_v0,
    output reg  [7:0]  O_catch_spawn,
    output reg  [15:0] O_catch_cfg,
    output reg  [15:0] O_trail_cfg,
    output reg  [15:0] O_particle_cfg,
    output reg  [11:0] O_field_y0,
    output reg  [11:0] O_field_y1,
    output reg  [11:0] O_dbg_blade_x,
    output reg  [11:0] O_dbg_blade_y,
    output reg         O_dbg_blade_en,
    output reg         O_dbg_marker_en      // 0xA3：画 1 像素对齐标记（L1 坐标自检）
);

    // ---- 0x81 game_ctrl：bit0/1/2 是"脉冲型命令"，bit3 是电平 --------------
    // bit0 重开本局、bit1 强制回待机、bit2 强制关层（= 回待机，不改 0x01），
    // 三个都收成一个"回待机/重开"的请求脉冲给 game_fruit。
    reg S_cmd_restart;
    reg S_cmd_standby;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            O_game_sel      <= 4'd1;        // 默认切水果
            O_restart       <= 1'b0;
            O_standby       <= 1'b0;
            O_pause         <= 1'b0;
            O_input_src     <= 4'd1;        // 默认手势源；W 85 0000 可回假源
            O_input_cfg     <= 16'h0000;    // 假源档位 0（自动乱舞）
            O_input_gain    <= 16'h0100;
            O_input_offset  <= 16'h0000;
            O_fruit_spawn   <= 8'd48;
            O_fruit_grav    <= 16'h0040;
            O_fruit_v0      <= 16'h0900;    // 垂直初速 9×2 = 18 px/帧 → 水果上侧顶点约 y=193
            O_catch_spawn   <= 8'd72;
            O_catch_cfg     <= 16'h0332;    // 3 px/帧起步，每 800 帧 +1
            O_trail_cfg     <= 16'h080A;
            O_particle_cfg  <= 16'h0814;
            O_field_y0      <= 12'd200;
            O_field_y1      <= 12'd704;
            O_dbg_blade_x   <= 12'd640;
            O_dbg_blade_y   <= 12'd400;
            O_dbg_blade_en  <= 1'b0;
            O_dbg_marker_en <= 1'b0;
            S_cmd_restart   <= 1'b0;
            S_cmd_standby   <= 1'b0;
        end
        else begin
            // 单拍脉冲：默认清零，写 1 的那一拍置起
            O_restart <= 1'b0;
            O_standby <= 1'b0;

            if(I_we) begin
                case(I_addr[5:0])
                    6'h00: O_game_sel     <= I_wdata[3:0];
                    6'h01: begin
                        if(I_wdata[3]) O_pause <= 1'b1;
                        else           O_pause <= 1'b0;
                        if(I_wdata[0]) S_cmd_restart <= 1'b1;
                        if(I_wdata[1] | I_wdata[2]) S_cmd_standby <= 1'b1;
                    end
                    6'h05: O_input_src    <= I_wdata[3:0];
                    6'h06: O_input_cfg    <= I_wdata;
                    6'h07: O_input_gain   <= I_wdata;
                    6'h08: O_input_offset <= I_wdata;
                    6'h09: O_fruit_spawn  <= I_wdata[7:0];
                    6'h0A: O_fruit_grav   <= I_wdata;
                    6'h0B: O_fruit_v0     <= I_wdata;
                    6'h15: O_catch_spawn  <= I_wdata[7:0];
                    6'h16: O_catch_cfg    <= I_wdata;
                    6'h0C: O_trail_cfg    <= I_wdata;
                    6'h0D: O_particle_cfg <= I_wdata;
                    6'h0E: O_field_y0     <= I_wdata[11:0];
                    6'h0F: O_field_y1     <= I_wdata[11:0];
                    6'h20: O_dbg_blade_x  <= I_wdata[11:0];
                    6'h21: O_dbg_blade_y  <= I_wdata[11:0];
                    6'h22: O_dbg_blade_en <= I_wdata[0];
                    6'h23: O_dbg_marker_en<= I_wdata[0];
                    default: ;
                endcase
            end

            // 命令脉冲只维持一拍（下一拍清零，避免"写一次重开一直重开"）
            if(S_cmd_restart) begin
                O_restart     <= 1'b1;
                S_cmd_restart <= 1'b0;
            end
            if(S_cmd_standby) begin
                O_standby     <= 1'b1;
                S_cmd_standby <= 1'b0;
            end
        end
    end

    // ---- 读回（0x80~0xA2；其余地址返回 0xFFFF，与 param_ctrl 的 default 一致）----
    always @(*) begin
        case(I_rd_addr)
            8'h80:   O_rd_data = {12'b0, O_game_sel};
            8'h81:   O_rd_data = {12'b0, O_pause, 2'b0, O_standby, O_restart};
            8'h85:   O_rd_data = {12'b0, O_input_src};
            8'h86:   O_rd_data = O_input_cfg;
            8'h87:   O_rd_data = O_input_gain;
            8'h88:   O_rd_data = O_input_offset;
            8'h89:   O_rd_data = {8'b0, O_fruit_spawn};
            8'h8A:   O_rd_data = O_fruit_grav;
            8'h8B:   O_rd_data = O_fruit_v0;
            8'h95:   O_rd_data = {8'b0, O_catch_spawn};
            8'h96:   O_rd_data = O_catch_cfg;
            8'h8C:   O_rd_data = O_trail_cfg;
            8'h8D:   O_rd_data = O_particle_cfg;
            8'h8E:   O_rd_data = {4'b0, O_field_y0};
            8'h8F:   O_rd_data = {4'b0, O_field_y1};
            8'h90:   O_rd_data = I_state_word;
            8'h91:   O_rd_data = I_blade_pos;
            8'h92:   O_rd_data = I_fruit_pos;
            8'h93:   O_rd_data = I_hit_cnt;
            8'h94:   O_rd_data = I_miss_cnt;
            8'hA0:   O_rd_data = {4'b0, O_dbg_blade_x};
            8'hA1:   O_rd_data = {4'b0, O_dbg_blade_y};
            8'hA2:   O_rd_data = {15'b0, O_dbg_blade_en};
            8'hA3:   O_rd_data = {15'b0, O_dbg_marker_en};
            default: O_rd_data = 16'hFFFF;
        endcase
    end

endmodule
