// ============================================================================
// game_sprite_rom —— 水果精灵 ROM（ERAM，单口，读延迟固定 1 拍）
//
// 内容：4 种水果 × 32×32 × 8bit（RGB332，`8'h00` = 透明），共 4096 个单元。
//   地址 = {pal[1:0], dy[4:0], dx[4:0]}（pal 是水果种类，dy/dx 是**源像素**坐标）。
//   上屏 2× 放大由调用方换算（`dx = (x - OBJ_X) >> 1`），ROM 本身不知道缩放。
//   半片（切开的两半）复用同一块 ROM 的**列窗**：只是把 dx 换成 16..31，
//   所以"切开两半"零额外 ERAM（见 B 线规划 §3 第 5 步 / §4.4 第 2 条）。
//
// 读延迟：地址第 N 拍给出、数据第 N+1 拍有效（REGMODE_A = "OUTREG"、ocea = 1）。
//   因此**不能用"当前像素"的坐标算地址**，必须用"下一个 de 像素"的坐标（前视一拍），
//   否则精灵整体偏 2 像素、纹理每列错位（见规划 §4.4 第 3 条）。调用方是 game_top。
//
// 初始化文件：`game_sprite.dat`（与本文件同目录；TD 的 ERAM 靠文件名在源码目录里找，
//   不登记进 .al / .prj，与 anlogic_logo_rom.dat 是同一套机制）。
//   重新生成：`pwsh -NoProfile -File tools/game_sprite_gen.ps1`（脚本内含穷举校验）。
//
// 资源：4096 × 8bit = 32 Kbit ≈ **2 块 ERAM20K**（与规划 §7.2 的账一致），
//   本模块自身逻辑 ≈ 10 LUT6（只有一块 ERAM 例化），无 DSP。
// 时钟域：像素域 75 MHz 单时钟，不跨域，不需要 SDC 约束。
// ============================================================================
module game_sprite_rom #(
    parameter integer ADDR_WIDTH = 12,
    parameter integer DATA_WIDTH = 8
) (
    input  wire                    I_clk,
    input  wire [ADDR_WIDTH-1:0]   I_addr,     // {pal[1:0], dy[4:0], dx[4:0]}
    output wire [DATA_WIDTH-1:0]   O_pixel     // 下一拍有效；8'h00 = 透明
);

    localparam integer DATA_DEPTH = (1 << ADDR_WIDTH);

    PH1P_LOGIC_ERAM #(
        .DATA_WIDTH_A           (DATA_WIDTH),
        .DATA_WIDTH_B           (DATA_WIDTH),
        .ADDR_WIDTH_A           (ADDR_WIDTH),
        .ADDR_WIDTH_B           (ADDR_WIDTH),
        .DATA_DEPTH_A           (DATA_DEPTH),
        .DATA_DEPTH_B           (DATA_DEPTH),
        .MODE                   ("SP"),
        .REGMODE_A              ("OUTREG"),
        .REGMODE_B              ("NOREG"),
        .WRITEMODE_A            ("NORMAL"),
        .WRITEMODE_B            ("NORMAL"),
        .IMPLEMENT              ("20K(FAST)"),
        .ECC_ENCODE             ("DISABLE"),
        .ECC_DECODE             ("DISABLE"),
        .CLKMODE                ("ASYNC"),
        .SSROVERCE              ("DISABLE"),
        .OREGSET_A              ("RESET"),
        .OREGSET_B              ("RESET"),
        .RESETMODE_A            ("ASYNC"),
        .RESETMODE_B            ("ASYNC"),
        .ASYNC_RESET_RELEASE_A  ("ASYNC"),
        .ASYNC_RESET_RELEASE_B  ("ASYNC"),
        .INIT_FILE              ("game_sprite.dat"),
        .FILL_ALL               ("NONE")
    ) u_eram (
        .dia            ({DATA_WIDTH{1'b0}}),
        .dib            ({DATA_WIDTH{1'b0}}),
        .addra          (I_addr),
        .addrb          ({ADDR_WIDTH{1'b0}}),
        .cea            (1'b1),
        .ceb            (1'b0),
        .ocea           (1'b1),          // 输出寄存器一直使能 —— 读延迟固定 1 拍
        .oceb           (1'b0),
        .clka           (I_clk),
        .clkb           (1'b0),
        .wea            (1'b0),          // 只读
        .web            (1'b0),
        .bea            (1'b0),
        .beb            (1'b0),
        .rsta           (1'b0),          // OREGSET_A = "RESET"：上电即为 0
        .rstb           (1'b0),
        .doa            (O_pixel),
        .dob            (),
        .ecc_sbiterr    (),
        .ecc_dbiterr    (),
        .ecc_sbiterrinj (1'b0),
        .ecc_dbiterrinj (1'b0)
    );

endmodule
