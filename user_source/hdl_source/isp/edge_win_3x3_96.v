// ============================================================================
// edge_win_3x3_96 —— 3x3 行缓存窗口生成器（灰度 → 逐像素平滑 → 行轮转 → 窗口）
//
// 2026-09-14 从 edge_detect_96.v 里原样拆出来的前半级（M0 模块重构），Sobel 算子
// 只消费本模块输出的窗口。后续形态学去噪/掩码窗口复用同一套行轮转结构。拆分时
// 逐拍对齐、逐表达式照抄，行为与原实现等价：
//   * 96 位字里的 4 个像素是同一行相邻像素，pix0 最左、pix3 最右（依据见
//     README 第 4 节：demosaic 的 rgb_data0 是最左像素，data128_96 把它映射到
//     96 位的最高字段，下游按 MSB 先出还原）；
//   * 灰度 = R/4 + G/2 + B/4（官方 720P 例程公式，最大 253，不回绕不用除法）；
//   * 逐像素 [1 2 1]/4 水平平滑，滤波器形状与官方例程一致，只是从"组平均域"
//     搬到了"逐像素域"；
//   * 3 块 48bit x (IMG_WIDTH/4) 的 ERAM 行缓存按行轮转：某一行的数据只写其中
//     一块，同时从另外两块读第 y-1、y-2 行；每块每拍要么读要么写，读地址寄存、
//     数据下一拍有效（这是块 RAM 的标准模板，也是必须的——全分辨率下行缓存若
//     落成触发器会把 FF 打满，TD 报 PHY-9002）；
//   * 每块 6 列 x 3 行：每行保存列 [4k-2 .. 4k+3]，低字节最左。存 6 列而不是 4
//     列，是为了读一次地址就拿到算 4 个像素 Sobel 所需的完整左右邻域；因此输出
//     像素 j 对应列 4k-1+j，整幅边缘图相对 RAW 左移 1 像素。
//
// 延迟：1 拍（地址/数据对齐 + 窗口寄存器）；接上 Sobel 级后总延迟 2 拍（与拆分前一致）。
// 时钟域：ISP（CSI）像素域，单时钟，不跨域，不需要额外 SDC 约束。
// 资源：3 块 ERAM20K（48bit x IMG_WIDTH/4 各一块），无 DSP、无分布式 RAM。
// ============================================================================
module edge_win_3x3_96 #(
    parameter IMG_WIDTH  = 1280,
    parameter IMG_HEIGHT = 720
)(
    input               I_clk,
    input               I_rst_n,
    input               I_tlast,
    input               I_tuser,
    input      [95:0]   I_tdata,
    input               I_tvalid,

    // 与窗口严格对齐（同为 1 拍延迟）的三行 6 列窗口与坐标
    output     [47:0]   O_cur,    // 当前行 y   , 列 4k-2..4k+3
    output     [47:0]   O_mid,    // 第 y-1 行
    output     [47:0]   O_top,    // 第 y-2 行
    output     [10:0]   O_x,      // 列组号 k（x_grp）
    output     [10:0]   O_y,
    output reg          O_valid,
    output reg          O_user,
    output reg          O_last
);

    wire [23:0] pix0 = I_tdata[95:72];
    wire [23:0] pix1 = I_tdata[71:48];
    wire [23:0] pix2 = I_tdata[47:24];
    wire [23:0] pix3 = I_tdata[23:0];

    // 灰度：R、G、B 依次在 pix[23:16]、pix[15:8]、pix[7:0]。
    wire [7:0] gray0 = {2'b0,pix0[23:18]} + {1'b0,pix0[15:9]} + {2'b0,pix0[7:2]};
    wire [7:0] gray1 = {2'b0,pix1[23:18]} + {1'b0,pix1[15:9]} + {2'b0,pix1[7:2]};
    wire [7:0] gray2 = {2'b0,pix2[23:18]} + {1'b0,pix2[15:9]} + {2'b0,pix2[7:2]};
    wire [7:0] gray3 = {2'b0,pix3[23:18]} + {1'b0,pix3[15:9]} + {2'b0,pix3[7:2]};

    localparam IMG_WIDTH_GRP = (IMG_WIDTH >> 2);

    reg [10:0] x_grp;
    reg [10:0] y_pos;
    reg [1:0]  row_phase;     // 0/1/2 轮转：本行写入哪一块
    reg [1:0]  row_phase_d1;  // 上一拍的轮转相位，用来选"这一拍有效的 ERAM 读出数据"

    // 逐像素水平平滑 s[n] = (g[n] + 2*g[n-1] + g[n-2]) / 4 的历史寄存器。
    reg [7:0] gray_h1;
    reg [7:0] gray_h2;
    reg [7:0] sm_h1;
    reg [7:0] sm_h2;

    // 当拍平滑结果与 6 列窗口：写成显式线网——ERAM 的写数据必须能在 always 块外
    // 看到（否则综合器把它当寄存器，写数据会比写地址晚一拍，行缓存整体错 4 像素）。
    wire [7:0]  S_sm0 = ({2'b00, gray0} + ({2'b00, gray_h1} << 1) + {2'b00, gray_h2}) >> 2;
    wire [7:0]  S_sm1 = ({2'b00, gray1} + ({2'b00, gray0}   << 1) + {2'b00, gray_h1}) >> 2;
    wire [7:0]  S_sm2 = ({2'b00, gray2} + ({2'b00, gray1}   << 1) + {2'b00, gray0})   >> 2;
    wire [7:0]  S_sm3 = ({2'b00, gray3} + ({2'b00, gray2}   << 1) + {2'b00, gray1})   >> 2;
    wire [47:0] S_win_cur = {S_sm3, S_sm2, S_sm1, S_sm0, sm_h1, sm_h2};

    // ---- 行缓存：3 块 PH1P ERAM（每块 IMG_WIDTH/4 x 48 位，1 拍读延迟）----------
    // 写使能带上 I_rst_n：原实现的写操作在 always 块的"非复位"分支里，复位期间不写。
    wire [47:0] S_mem0_q, S_mem1_q, S_mem2_q;
    wire        S_we0 = I_rst_n && I_tvalid && (row_phase == 2'd0);
    wire        S_we1 = I_rst_n && I_tvalid && (row_phase == 2'd1);
    wire        S_we2 = I_rst_n && I_tvalid && (row_phase == 2'd2);

    eram_spram #(.DATA_WIDTH(48), .ADDR_WIDTH(9)) u_line_mem0 (
        .I_clk(I_clk), .I_we(S_we0), .I_addr(x_grp[8:0]), .I_wdata(S_win_cur), .O_rdata(S_mem0_q));
    eram_spram #(.DATA_WIDTH(48), .ADDR_WIDTH(9)) u_line_mem1 (
        .I_clk(I_clk), .I_we(S_we1), .I_addr(x_grp[8:0]), .I_wdata(S_win_cur), .O_rdata(S_mem1_q));
    eram_spram #(.DATA_WIDTH(48), .ADDR_WIDTH(9)) u_line_mem2 (
        .I_clk(I_clk), .I_we(S_we2), .I_addr(x_grp[8:0]), .I_wdata(S_win_cur), .O_rdata(S_mem2_q));

    // 读出的三块里取"第 y-1 行"和"第 y-2 行"：地址在上一拍给出，所以相位也用上一拍的。
    wire [47:0] mid_r = (row_phase_d1 == 2'd0) ? S_mem2_q :
                        (row_phase_d1 == 2'd1) ? S_mem0_q : S_mem1_q;
    wire [47:0] top_r = (row_phase_d1 == 2'd0) ? S_mem1_q :
                        (row_phase_d1 == 2'd1) ? S_mem2_q : S_mem0_q;

    reg [47:0] cur_r;   // 当前行 y，列 4k-2..4k+3，与 x_r/y_r/O_valid 同拍
    reg [10:0] x_r;
    reg [10:0] y_r;

    assign O_cur = cur_r;
    assign O_mid = mid_r;
    assign O_top = top_r;
    assign O_x   = x_r;
    assign O_y   = y_r;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            x_grp <= 11'd0;
            y_pos <= 11'd0;
            row_phase <= 2'd0;
            row_phase_d1 <= 2'd0;
            gray_h1 = 8'd0;
            gray_h2 = 8'd0;
            sm_h1 = 8'd0;
            sm_h2 = 8'd0;
            cur_r <= 48'd0;
            x_r   <= 11'd0;
            y_r   <= 11'd0;
            O_valid <= 1'b0;
            O_user  <= 1'b0;
            O_last  <= 1'b0;
        end
        else begin
            // 与 ERAM 读出数据对齐：这一拍有效的 doa 对应上一拍给出的地址，
            // 所以读侧选择（mid_r/top_r）要用上一拍的轮转相位。
            // 消隐期 x_grp 不变，读出的数据不会被使用。
            row_phase_d1 <= row_phase;

            O_valid <= I_tvalid;
            O_user  <= I_tuser;
            O_last  <= I_tlast;

            if(I_tvalid) begin
                if(I_tuser) begin
                    x_grp <= 11'd0;
                    y_pos <= 11'd0;
                    row_phase <= 2'd0;
                    gray_h1 = 8'd0;
                    gray_h2 = 8'd0;
                    sm_h1 = 8'd0;
                    sm_h2 = 8'd0;
                end

                // 逐像素 [1 2 1]/4 平滑的当拍结果在 S_sm0..S_sm3（上面做了 10 位
                // 扩展避免 8 位回绕）。这里只更新历史寄存器。
                gray_h2 = gray2;
                gray_h1 = gray3;
                sm_h2 = S_sm2;
                sm_h1 = S_sm3;

                // 写行缓存由 S_we0/1/2 驱动（见上面的 eram_spram 实例），写数据与写
                // 地址都取自当拍：地址 x_grp、数据 S_win_cur（6 列窗口）。
                cur_r <= S_win_cur;
                x_r   <= x_grp;
                y_r   <= y_pos;

                if(x_grp == IMG_WIDTH_GRP - 1) begin
                    x_grp <= 11'd0;
                    if(y_pos == IMG_HEIGHT - 1)
                        y_pos <= 11'd0;
                    else
                        y_pos <= y_pos + 1'b1;

                    row_phase <= (row_phase == 2'd2) ? 2'd0 : (row_phase + 2'd1);

                    gray_h1 = 8'd0;
                    gray_h2 = 8'd0;
                    sm_h1 = 8'd0;
                    sm_h2 = 8'd0;
                end
                else begin
                    x_grp <= x_grp + 1'b1;
                end
            end
        end
    end

endmodule
