// ============================================================================
// game_input —— 输入抽象层：假源 / 手势 / UART 手柄（预留）→ 归一化刀尖坐标
//
// 三个源走同一套 `O_x[11:0] / O_y[11:0] / O_valid`（上屏像素），切水果本体不认识源：
//   0 = 假源（默认）：`I_cfg[3:2]` 再分三档
//        档位 0 = 自动乱舞（两个独立三角波 → Lissajous，演示/回归用）
//        档位 1 = 固定轨迹（闭合 1:2 Lissajous，位置可复现）
//        档位 2 = UART 直给（`I_dbg_x/I_dbg_y` + `I_dbg_en`，从 PC 手动切）
//   1 = 手势：`I_ctrl_x/I_ctrl_y/I_ctrl_valid`（A 的 M1 质心 / M2 指尖；C 在顶层接过来）
//   2 = UART 手柄：X1 预留，本轮不接（按假源处理）
//
// 手势源的两条约定（B 线需求单 1，B 侧不再去抖）：
//   * `I_ctrl_valid = 0` 时**保持最后有效坐标**（清零会让刀尖跳回 (0,0)）；
//   * 每帧一次、帧首锁存（A/C 侧用 toggle + 整包捕获保证），本模块只做保持。
//
// `I_gain` 说明：0x87 的表义是 ×256 定点增益，但那是第 2 个乘法器（DSP 预算只有 1 个），
//   本轮只实现 `I_offset`（有符号加），增益按 1.0× 处理——`I_gain` 保留端口、不参与运算。
//
// 延迟：假源坐标 1 拍寄存；手势源 1 拍锁存。都是慢通道，不影响 0 拍边界。
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// 资源：约 120 FF + 180 LUT6（三角波 + 档位 mux），无 ERAM / DSP。
// ============================================================================
module game_input #(
    parameter integer IMG_W = 1280,
    parameter integer IMG_H = 720
) (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_vsync,        // 帧节拍（上升沿）

    // ---- 参数（game_param 的 0x85~0x88 / 0x8E / 0x8F / 0xA0~0xA2）----
    input  wire [3:0]  I_src,          // 0 假源 / 1 手势 / 2 手柄（预留）
    input  wire [15:0] I_cfg,          // {假源档位[3:2], 死区[1:0]}
    input  wire [15:0] I_gain,         // 保留（本版按 1.0× 处理）
    input  wire [15:0] I_offset,       // {x偏置[15:8], y偏置[7:0]}，有符号
    input  wire [11:0] I_field_y0,     // 场地上/下边界（假源活动范围）
    input  wire [11:0] I_field_y1,
    input  wire [11:0] I_dbg_x,
    input  wire [11:0] I_dbg_y,
    input  wire        I_dbg_en,

    // ---- 手势源（A 的识别结果，C 在顶层接过来；未接时 I_ctrl_valid = 0）----
    input  wire [10:0] I_ctrl_x,
    input  wire [10:0] I_ctrl_y,
    input  wire        I_ctrl_valid,

    // ---- 归一化刀尖坐标（上屏像素）----
    output reg  [11:0] O_x,
    output reg  [11:0] O_y,
    output reg         O_valid,

    // ---- 观测：假源当前坐标（调试用，可悬空）----
    output wire [11:0] O_fake_x,
    output wire [11:0] O_fake_y
);

    // ---- 帧计数器与三角波 ---------------------------------------------------
    // 两个相位/速率不同的三角波拼成 Lissajous：便宜、确定、无乘法、无 ROM。
    reg [15:0] S_x_cnt;
    reg [15:0] S_y_cnt;
    reg        S_vs_d;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_x_cnt <= 16'd0;
            S_y_cnt <= 16'd0;
            S_vs_d  <= 1'b0;
        end
        else begin
            S_vs_d <= I_vsync;
            if(I_vsync & ~S_vs_d) begin
                S_x_cnt <= S_x_cnt + 16'd7;      // 每帧步进 7 / 11 → 不可公度，轨迹不重样
                S_y_cnt <= S_y_cnt + 16'd11;
            end
        end
    end

    // 三角波：输入低 11 位，最高位为 1 时取反 → 0..2047 往返
    function [10:0] F_tri;
        input [10:0] I_c;
        begin
            F_tri = I_c[10] ? ~I_c[9:0] : {1'b0, I_c[9:0]};
        end
    endfunction

    wire [10:0] S_x_tri = F_tri(S_x_cnt[10:0]);
    // 档位 0：y 用独立计数器（乱舞）；档位 1：y 由 x 计数器 2 分频派生（闭合轨迹）
    wire [10:0] S_y_src = (I_cfg[3:2] == 2'd1) ? {S_x_cnt[9:0], 1'b0} : S_y_cnt[10:0];
    wire [10:0] S_y_tri = F_tri(S_y_src);

    // 场地内映射：x = 64 + tri/2（64..1087），y = y0 + tri/4（y0..y0+511，再截到 y1）
    wire [11:0] S_fake_x = 12'd64 + {1'b0, S_x_tri[10:1]};
    wire [12:0] S_fake_y_raw = {1'b0, I_field_y0[11:0]} + {2'b0, S_y_tri[10:2]};
    wire [11:0] S_fake_y = (S_fake_y_raw > {1'b0, I_field_y1}) ? I_field_y1
                                                               : S_fake_y_raw[11:0];

    // ---- 手势源：保持最后有效坐标 + 偏置归一化 ------------------------------
    // 偏置（0x88）按需求单 1 的语义只作用在**手势源**（A 的坐标归一化）上：
    // 有符号 8 位各轴，加完截到屏幕范围内。增益（0x87）本版不参与运算（见文件头）。
    wire signed [12:0] S_off_x   = {{5{I_offset[15]}}, I_offset[15:8]};
    wire signed [12:0] S_off_y   = {{5{I_offset[7]}},  I_offset[7:0]};
    wire signed [12:0] S_ges_x_c = $signed({1'b0, I_ctrl_x}) + S_off_x;
    wire signed [12:0] S_ges_y_c = $signed({1'b0, I_ctrl_y}) + S_off_y;
    wire [11:0] S_ges_x_n = (S_ges_x_c[12] | (S_ges_x_c > 13'sd1279)) ? 12'd0 : S_ges_x_c[11:0];
    wire [11:0] S_ges_y_n = (S_ges_y_c[12] | (S_ges_y_c > 13'sd719))  ? 12'd0 : S_ges_y_c[11:0];

    reg [11:0] S_ges_x;
    reg [11:0] S_ges_y;
    reg        S_ges_valid;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_ges_x     <= 12'd640;
            S_ges_y     <= 12'd400;
            S_ges_valid <= 1'b0;
        end
        else if(I_ctrl_valid) begin
            S_ges_x     <= S_ges_x_n;
            S_ges_y     <= S_ges_y_n;
            S_ges_valid <= 1'b1;
        end
    end

    // ---- 源选择 -------------------------------------------------------------
    wire [1:0] S_fake_gear = I_cfg[3:2];

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            O_x     <= 12'd640;
            O_y     <= 12'd400;
            O_valid <= 1'b0;
        end
        else begin
            case(I_src[1:0])
                2'd1: begin                        // 手势
                    O_x     <= S_ges_x;
                    O_y     <= S_ges_y;
                    O_valid <= S_ges_valid;
                end
                2'd0, 2'd2: begin                  // 假源（含"手柄预留"档）
                    if(S_fake_gear == 2'd2) begin   // UART 直给
                        O_x     <= I_dbg_x;
                        O_y     <= I_dbg_y;
                        O_valid <= I_dbg_en;
                    end
                    else begin                      // 乱舞 / 固定轨迹
                        O_x     <= S_fake_x;
                        O_y     <= S_fake_y;
                        O_valid <= 1'b1;
                    end
                end
                default: begin
                    O_x     <= S_fake_x;
                    O_y     <= S_fake_y;
                    O_valid <= 1'b1;
                end
            endcase
        end
    end

    assign O_fake_x = S_fake_x;
    assign O_fake_y = S_fake_y;

endmodule
