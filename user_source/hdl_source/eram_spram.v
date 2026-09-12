// ============================================================================
// eram_spram —— PH1P ERAM 单口 RAM 封装（固定 1 拍读延迟）
//
// 为什么需要这个封装：TD 不认 `(* ram_style = "block" *)` 这类属性，大数组会被
// 综合成分布式 RAM（LUTRAM）而不是 ERAM —— 面积表里 u_edge_detect_96 的
// dram lut = 1152、eram = 0 就是证据（见 README 11.4）。要让数据真正落进块 RAM，
// 只能像 TD 自己的 IP 那样显式例化 `PH1P_LOGIC_ERAM`。这里把它收成一个通用封装，
// 供行缓存/延迟线使用（logo ROM 是只读场景，单独写在 anlogic_logo_rom.v 里）。
//
// 时序约定（用之前必须对齐）：
//   I_addr 在当拍给出 → O_rdata 在**下一拍**有效（REGMODE_A = "OUTREG"，
//   地址由 ERAM 内部寄存、输出寄存常开）。也就是说本模块等价于
//   `always @(posedge clk) dout <= mem[addr];`。
//   0 拍的组合读在块 RAM 上不被支持（TD 的 apm_memory 模型直接报错），
//   所以不要试图把 REGMODE_A 改成 "NOREG"。
//   写端口与地址共用一条通路：I_we = 1 的那一拍是"只写"，读出值没有意义
//   （调用方应保证同一块不会在同一拍既读又写；行轮转那种三块轮换天然满足）。
//
// 初值：FILL_ALL("0")，上电即为全 0，与原来 LUTRAM 未写过的位置是 0 保持一致。
// ============================================================================

module eram_spram #(
    parameter integer DATA_WIDTH = 48,
    parameter integer ADDR_WIDTH = 9
) (
    input  wire                    I_clk,
    input  wire                    I_we,
    input  wire [ADDR_WIDTH-1:0]   I_addr,
    input  wire [DATA_WIDTH-1:0]   I_wdata,
    output wire [DATA_WIDTH-1:0]   O_rdata
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
        .INIT_FILE              ("NONE"),
        .FILL_ALL               ("0")
    ) u_eram (
        .dia            (I_wdata),
        .dib            ({DATA_WIDTH{1'b0}}),
        .addra          (I_addr),
        .addrb          ({ADDR_WIDTH{1'b0}}),
        .cea            (1'b1),
        .ceb            (1'b0),
        .ocea           (1'b1),          // 输出寄存器常开 —— 读延迟固定 1 拍
        .oceb           (1'b0),
        .clka           (I_clk),
        .clkb           (1'b0),
        .wea            (I_we),
        .web            (1'b0),
        .bea            (1'b0),
        .beb            (1'b0),
        .rsta           (1'b0),          // OREGSET_A = "RESET"：上电即为 0
        .rstb           (1'b0),
        .doa            (O_rdata),
        .dob            (),
        .ecc_sbiterr    (),
        .ecc_dbiterr    (),
        .ecc_sbiterrinj (1'b0),
        .ecc_dbiterrinj (1'b0)
    );

endmodule
