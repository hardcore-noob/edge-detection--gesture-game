// ============================================================================
// game_gesture —— 动态手势事件解码（菜单预留，不参与切水果）
//
// 输入是 A 侧 recog_top 的 40 位帧锁存事件字（经 VIDEO_TAP toggle 整包捕获）：
//   [4:0] seq / [7:5] dir / [15:8] start_x8 / [23:16] start_y8
//   [31:24] peak_dx8 / [39:32] peak_dy8
//
// 本模块只保留事件语义：
//   * 进游戏、刀锋未锁定、游戏非运行态时清基线；
//   * 重新满足条件后先记录当前 seq，不补放旧事件；
//   * seq 变化且 dir ∈ {1,2,3} 时产生单拍 O_gesture_valid。
//
// 本轮扫掠带已删除，事件输出当前没有消费者；源码和接口保留给未来菜单。
// 40 位事件字的 dir=4 仍然是 A 侧的“方向不明确”，不会在这里产生事件。
//
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// 资源：约 40 FF + 60 LUT6，无 ERAM / DSP。
// ============================================================================
module game_gesture (
    input  wire        I_clk,
    input  wire        I_rst_n,

    input  wire        I_bypass,        // 1 = 游戏层旁路（game_mode == 0）
    input  wire [3:0]  I_game_mode,
    input  wire        I_track_locked,
    input  wire        I_game_running,
    input  wire [1:0]  I_ctx,           // 预留：0 = 游戏态，1 = 菜单

    input  wire [39:0] I_gest_word,

    output reg         O_gesture_valid,
    output reg  [1:0]  O_gesture_dir
);

    wire S_gate = I_game_mode[0] & ~I_bypass & I_track_locked &
                  I_game_running & (I_ctx == 2'd0);
    wire [2:0] S_dir = I_gest_word[7:5];
    wire [4:0] S_seq = I_gest_word[4:0];
    wire S_dir_ok = (S_dir == 3'd1) || (S_dir == 3'd2) || (S_dir == 3'd3);

    reg       S_base_valid;
    reg [4:0] S_base_seq;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_base_valid   <= 1'b0;
            S_base_seq     <= 5'd0;
            O_gesture_valid <= 1'b0;
            O_gesture_dir   <= 2'd0;
        end
        else begin
            O_gesture_valid <= 1'b0;

            if(!S_gate) begin
                // 退出门控：重新进入时先取当前序号作为基线。
                S_base_valid <= 1'b0;
            end
            else if(!S_base_valid) begin
                S_base_seq   <= S_seq;
                S_base_valid <= 1'b1;
            end
            else if(S_seq != S_base_seq) begin
                S_base_seq <= S_seq;
                if(S_dir_ok) begin
                    O_gesture_valid <= 1'b1;
                    O_gesture_dir   <= S_dir[1:0];
                end
            end
        end
    end

endmodule
