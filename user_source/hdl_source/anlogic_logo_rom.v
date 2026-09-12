// ============================================================================
// anlogic_logo_rom —— 安路 Logo 位图 ROM（ERAM / 块 RAM 版，读延迟 1 拍）
//
// 原始版本（官方 lab_ex3_osd 例程，本仓库 2026-09-12 之前）用 6387 条 case
// 语句拼成组合 ROM。综合报告（camera_to_dsi_display_rtl.area）显示这块逻辑在
// RTL 级占 38426 个门，是它的父模块 hdmi_mixer（38822 个门）的 99%；技术映射
// 之后这些门被摊进父模块，最终 hdmi_mixer 的 2633 个 LUT6 里绝大部分就是它。
// 换成 ERAM 之后这部分 LUT 全部还给逻辑资源，代价是 ERAM：25 位 x 16384 深
// = 400 Kbit，按 ERAM20K 每块 20 Kbit 估算约占 20 块（器件共 108 块，原设计
// 已用 39 块）。
//
// 读延迟：本模块是 1 拍（地址在第 N 拍给出，数据在第 N+1 拍有效）。
//   * ERAM 原语 REGMODE_A = "OUTREG" + ocea = 1 就是"输出寄存一拍"的同步读；
//   * 所以调用方必须把地址提前一拍给出。hdmi_mixer.v 里用的是
//     S_x_1d/S_y_1d 的"预取地址"（下一拍才变成 S_x_2d/S_y_2d），这样数据仍在
//     *_2d 那一拍与像素对齐，整条链路的总延迟不变。
//   * 如果哪天发现 Logo 整体右移了 1 个像素，说明这一拍的约定被打破了
//     （要么把 REGMODE 改成 NOREG，要么挪动调用方的预取级）。
//
// 地址映射（与原 case 版本逐位一致，由 tools/logo_rom_case_to_dat.ps1 生成并穷举校验）：
//   原始地址 = y * LOGO_W + x（LOGO_W = 160），有内容的地址区间是 [5494, 20426]。
//   这里整体下移 ROM_BASE = 4096，用 14 位行号索引 [0, 16383]，覆盖地址
//   [4096, 20479]；落在窗口外的地址一律索引第 0 行，而第 0 行内容为 0
//   （alpha = 0，不叠加），等价于原 case 的 default 分支。
//   → 对全部 15 位地址空间（0..32767），新旧实现逐地址等价，已用脚本穷举验证。
//
// 位图数据：user_source/hdl_source/anlogic_logo_rom.dat
//   * 格式 = TD IP 生成器的 .dat 约定：一行一个存储单元，行序即地址序，
//     每行 25 个二进制字符、高位在前；
//   * 改位图时重新生成：先把 case 版源文件取出（git show <commit>:user_source/
//     hdl_source/anlogic_logo_rom.v > tmp/logo_rom_case.v），再跑
//     pwsh -File tools/logo_rom_case_to_dat.ps1 -CaseFile tmp/logo_rom_case.v，
//     脚本会拒绝超出窗口的内容，避免"画到一半消失"这种静默错误；
//   * 注意：TD 的 .al / .prj 里不登记 .dat，靠文件名在源码目录里找
//     （与 DDR PHY 的 ddrphy_cfg_rom.txt 同一套机制），所以 .dat 必须与
//     本文件放在同一个目录。
// ============================================================================

module anlogic_logo_rom (
    input  wire        I_clk,
    input  wire [14:0] I_addr,      // 绝对地址：y * LOGO_W + x，与 case 版一致
    output wire [24:0] O_pixel      // {alpha, R, G, B}，alpha = 1 才叠加
);

    localparam integer ROM_WIDTH = 25;
    localparam integer ROM_DEPTH = 16384;
    localparam integer ROM_ADDRW = 14;
    localparam [14:0]  ROM_BASE  = 15'd4096;
    localparam [14:0]  ROM_LAST  = ROM_BASE + ROM_DEPTH - 1;   // 20479

    // 窗口外的地址强制到第 0 行（内容为 0），等价原 case 的 default 分支。
    // 这一步在地址通路上，位于 *_1d 寄存器与 ERAM 输入之间，不影响读延迟。
    // 注意必须先做 15 位减法再取低 14 位：I_addr[13:0] 对 >= 16384 的地址不是
    // "绝对地址的低 14 位"（位图第 102 行以下正好落在这个区间），直接切片会读错行。
    wire        S_in_range = (I_addr >= ROM_BASE) && (I_addr <= ROM_LAST);
    wire [14:0] S_offset   = I_addr - ROM_BASE;
    wire [13:0] S_row      = S_in_range ? S_offset[13:0] : {ROM_ADDRW{1'b0}};

    PH1P_LOGIC_ERAM #(
        .DATA_WIDTH_A           (ROM_WIDTH),
        .DATA_WIDTH_B           (ROM_WIDTH),
        .ADDR_WIDTH_A           (ROM_ADDRW),
        .ADDR_WIDTH_B           (ROM_ADDRW),
        .DATA_DEPTH_A           (ROM_DEPTH),
        .DATA_DEPTH_B           (ROM_DEPTH),
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
        .INIT_FILE              ("anlogic_logo_rom.dat"),
        .FILL_ALL               ("NONE")
    ) u_eram (
        .dia            ({ROM_WIDTH{1'b0}}),
        .dib            ({ROM_WIDTH{1'b0}}),
        .addra          (S_row),
        .addrb          ({ROM_ADDRW{1'b0}}),
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
