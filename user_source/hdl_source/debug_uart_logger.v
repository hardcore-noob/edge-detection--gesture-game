/*
 * 运行时调试日志：通过板载 USB-UART (TXD=H1) 以 115200-8-N-1 输出。
 *
 * 每 1 秒输出一帧状态，字段：
 *   F    HDMI 显示帧计数        (HEX)
 *   A    AE 曝光目标值           (HEX)
 *   G    AG 增益目标值           (HEX)
 *   T    24 位流水线状态位图     (HEX)
 *
 * 2026-09-12 追加 4 个字段（都在行尾，T 位图不动）：
 *   D    video_in  FIFO（ISP→DDR）上一帧丢写次数  (HEX=16 位)
 *   E    video_out FIFO（DDR→HDMI）上一帧丢写次数 (HEX=16 位)
 *   W    video_in  FIFO 上一帧最大占用 0..511     (HEX=9 位)
 *   V    video_out FIFO 上一帧最大占用 0..511     (HEX=9 位)
 *   D/E 恒为 0 表示这一秒没有因为 FIFO 满而丢数据；W/V 越接近 1FF 说明离写满越近。
 *
 * T 位定义（bit 23 -> bit 0）：
 *  23 MC 初始化完成
 *  22 MC APP READY
 *  21 MC WDF READY
 *  20 MC CMD POP
 *  19 DDR 读数据有效
 *  18 DDR 写请求
 *  17 DDR READY
 *  16 DDR 写请求脉冲
 *  15 ISP valid
 *  14 ISP frame-start
 *  13 ISP 有数据
 *  12 RAW stream 有数据
 *  11 RAW10 有数据
 *  10 CSI 有数据
 *   9 MIPI HS 有效
 *   8 摄像头配置完成
 *   7 EDGE 输出 valid 有效
 *   6 EDGE 输出数据非零
 *   5 DDR 读到非零视频
 *   4 HDMI 显示像素非零
 *   3 算法状态（0=RAW，1=EDGE）
 *   2 HDMI OUT DE
 *   1 HDMI DE
 *   0 HDMI 窗口读使能
 */
module debug_uart_logger #(
    parameter integer CLK_HZ = 75000000,
    parameter integer BAUD = 115200,
    parameter integer LOG_PERIOD_MS = 1000
) (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire [23:0] I_status,
    input  wire [15:0] I_ae,
    input  wire [15:0] I_ag,
    input  wire [15:0] I_frame_cnt,
    input  wire [19:0] I_nonzero_cnt,
    input  wire [19:0] I_bright_cnt,
    input  wire [19:0] I_very_cnt,
    input  wire [9:0]  I_max_px,
    input  wire [7:0]  I_disp_max_px,
    input  wire [15:0] I_fifo_in_drop,
    input  wire [15:0] I_fifo_out_drop,
    input  wire [8:0]  I_fifo_in_used,
    input  wire [8:0]  I_fifo_out_used,
    output reg         O_tx
);

    // 分频值按四舍五入取整，位宽一律由参数用 $clog2 推导：
    // 75 MHz / 115200 需要 10 位，写死 9 位会在改时钟频率后卡死 UART。
    localparam integer CLK_PER_BIT   = (CLK_HZ + (BAUD / 2)) / BAUD;
    localparam integer CLK_PER_BIT_W = $clog2(CLK_PER_BIT);
    localparam integer LOG_TICKS     = (CLK_HZ / 1000) * LOG_PERIOD_MS;
    localparam integer LOG_TICKS_W   = $clog2(LOG_TICKS);
    localparam [LOG_TICKS_W-1:0] TIMEOUT_CNT = LOG_TICKS - 1;

    localparam [2:0] TX_IDLE  = 3'd0;
    localparam [2:0] TX_START = 3'd1;
    localparam [2:0] TX_DATA  = 3'd2;
    localparam [2:0] TX_STOP  = 3'd3;

    // 一行 96 字节：原来的 70 字节（到 L=xx 为止）+ 追加的 " D=xxxx E=xxxx W=xxx V=xxx"
    // + CRLF。115200 下发一行约 8.3 ms，仍远小于 1 s 的发送周期。
    localparam [6:0] LINE_LAST = 7'd95;

    function [7:0] F_hex_nibble;
        input [3:0] I_n;
        begin
            case (I_n)
                4'h0: F_hex_nibble = 8'h30;
                4'h1: F_hex_nibble = 8'h31;
                4'h2: F_hex_nibble = 8'h32;
                4'h3: F_hex_nibble = 8'h33;
                4'h4: F_hex_nibble = 8'h34;
                4'h5: F_hex_nibble = 8'h35;
                4'h6: F_hex_nibble = 8'h36;
                4'h7: F_hex_nibble = 8'h37;
                4'h8: F_hex_nibble = 8'h38;
                4'h9: F_hex_nibble = 8'h39;
                4'hA: F_hex_nibble = 8'h41;
                4'hB: F_hex_nibble = 8'h42;
                4'hC: F_hex_nibble = 8'h43;
                4'hD: F_hex_nibble = 8'h44;
                4'hE: F_hex_nibble = 8'h45;
                4'hF: F_hex_nibble = 8'h46;
                default: F_hex_nibble = 8'h30;
            endcase
        end
    endfunction

    // ---- 行模板 -------------------------------------------------------------
    // 一行 70 字节 = 32 个固定文本字节 + 38 个十六进制数字（F/A/G/T/N/B/C/M/L 的
    // nibble）。拆成"常量字节表 + nibble 源表 + 一份 hex 编码器"：
    // 直接写成一个 70 分支的 case 时，38 个数字分支各自带一份 4->8 位编码逻辑，
    // TD 面积表里 u_debug_uart_logger 那 201 个 LUT 大头就在这里。
    // 两张表由 tools 之外的一次性脚本从旧版 case 逐行转换而来，并做了 70 项穷举比对。
    function [7:0] F_tpl;
        input [6:0] I_idx;
        begin
            case (I_idx)
                7'd0 : F_tpl = 8'h44;   // 'D'
                7'd1 : F_tpl = 8'h42;   // 'B'
                7'd2 : F_tpl = 8'h47;   // 'G'
                7'd3 : F_tpl = 8'h3a;   // ':'
                7'd4 : F_tpl = 8'h46;   // 'F'
                7'd5 : F_tpl = 8'h3d;   // '='
                7'd6 : F_tpl = 8'h00;   // 数字位，不使用
                7'd7 : F_tpl = 8'h00;   // 数字位，不使用
                7'd8 : F_tpl = 8'h00;   // 数字位，不使用
                7'd9 : F_tpl = 8'h00;   // 数字位，不使用
                7'd10: F_tpl = 8'h20;   // ' '
                7'd11: F_tpl = 8'h41;   // 'A'
                7'd12: F_tpl = 8'h3d;   // '='
                7'd13: F_tpl = 8'h00;   // 数字位，不使用
                7'd14: F_tpl = 8'h00;   // 数字位，不使用
                7'd15: F_tpl = 8'h00;   // 数字位，不使用
                7'd16: F_tpl = 8'h00;   // 数字位，不使用
                7'd17: F_tpl = 8'h20;   // ' '
                7'd18: F_tpl = 8'h47;   // 'G'
                7'd19: F_tpl = 8'h3d;   // '='
                7'd20: F_tpl = 8'h00;   // 数字位，不使用
                7'd21: F_tpl = 8'h00;   // 数字位，不使用
                7'd22: F_tpl = 8'h00;   // 数字位，不使用
                7'd23: F_tpl = 8'h00;   // 数字位，不使用
                7'd24: F_tpl = 8'h20;   // ' '
                7'd25: F_tpl = 8'h54;   // 'T'
                7'd26: F_tpl = 8'h3d;   // '='
                7'd27: F_tpl = 8'h00;   // 数字位，不使用
                7'd28: F_tpl = 8'h00;   // 数字位，不使用
                7'd29: F_tpl = 8'h00;   // 数字位，不使用
                7'd30: F_tpl = 8'h00;   // 数字位，不使用
                7'd31: F_tpl = 8'h00;   // 数字位，不使用
                7'd32: F_tpl = 8'h00;   // 数字位，不使用
                7'd33: F_tpl = 8'h20;   // ' '
                7'd34: F_tpl = 8'h4e;   // 'N'
                7'd35: F_tpl = 8'h3d;   // '='
                7'd36: F_tpl = 8'h00;   // 数字位，不使用
                7'd37: F_tpl = 8'h00;   // 数字位，不使用
                7'd38: F_tpl = 8'h00;   // 数字位，不使用
                7'd39: F_tpl = 8'h00;   // 数字位，不使用
                7'd40: F_tpl = 8'h00;   // 数字位，不使用
                7'd41: F_tpl = 8'h20;   // ' '
                7'd42: F_tpl = 8'h42;   // 'B'
                7'd43: F_tpl = 8'h3d;   // '='
                7'd44: F_tpl = 8'h00;   // 数字位，不使用
                7'd45: F_tpl = 8'h00;   // 数字位，不使用
                7'd46: F_tpl = 8'h00;   // 数字位，不使用
                7'd47: F_tpl = 8'h00;   // 数字位，不使用
                7'd48: F_tpl = 8'h00;   // 数字位，不使用
                7'd49: F_tpl = 8'h20;   // ' '
                7'd50: F_tpl = 8'h43;   // 'C'
                7'd51: F_tpl = 8'h3d;   // '='
                7'd52: F_tpl = 8'h00;   // 数字位，不使用
                7'd53: F_tpl = 8'h00;   // 数字位，不使用
                7'd54: F_tpl = 8'h00;   // 数字位，不使用
                7'd55: F_tpl = 8'h00;   // 数字位，不使用
                7'd56: F_tpl = 8'h00;   // 数字位，不使用
                7'd57: F_tpl = 8'h20;   // ' '
                7'd58: F_tpl = 8'h4d;   // 'M'
                7'd59: F_tpl = 8'h3d;   // '='
                7'd60: F_tpl = 8'h00;   // 数字位，不使用
                7'd61: F_tpl = 8'h00;   // 数字位，不使用
                7'd62: F_tpl = 8'h00;   // 数字位，不使用
                7'd63: F_tpl = 8'h20;   // ' '
                7'd64: F_tpl = 8'h4c;   // 'L'
                7'd65: F_tpl = 8'h3d;   // '='
                7'd66: F_tpl = 8'h00;   // 数字位，不使用
                7'd67: F_tpl = 8'h00;   // 数字位，不使用
                7'd68: F_tpl = 8'h20;   // ' '
                7'd69: F_tpl = 8'h44;   // 'D'
                7'd70: F_tpl = 8'h3d;   // '='
                7'd71: F_tpl = 8'h00;   // 数字位，不使用
                7'd72: F_tpl = 8'h00;   // 数字位，不使用
                7'd73: F_tpl = 8'h00;   // 数字位，不使用
                7'd74: F_tpl = 8'h00;   // 数字位，不使用
                7'd75: F_tpl = 8'h20;   // ' '
                7'd76: F_tpl = 8'h45;   // 'E'
                7'd77: F_tpl = 8'h3d;   // '='
                7'd78: F_tpl = 8'h00;   // 数字位，不使用
                7'd79: F_tpl = 8'h00;   // 数字位，不使用
                7'd80: F_tpl = 8'h00;   // 数字位，不使用
                7'd81: F_tpl = 8'h00;   // 数字位，不使用
                7'd82: F_tpl = 8'h20;   // ' '
                7'd83: F_tpl = 8'h57;   // 'W'
                7'd84: F_tpl = 8'h3d;   // '='
                7'd85: F_tpl = 8'h00;   // 数字位，不使用
                7'd86: F_tpl = 8'h00;   // 数字位，不使用
                7'd87: F_tpl = 8'h00;   // 数字位，不使用
                7'd88: F_tpl = 8'h20;   // ' '
                7'd89: F_tpl = 8'h56;   // 'V'
                7'd90: F_tpl = 8'h3d;   // '='
                7'd91: F_tpl = 8'h00;   // 数字位，不使用
                7'd92: F_tpl = 8'h00;   // 数字位，不使用
                7'd93: F_tpl = 8'h00;   // 数字位，不使用
                7'd94: F_tpl = 8'h0d;   // (0x0d)
                7'd95: F_tpl = 8'h0a;   // (0x0a)
                default: F_tpl = 8'h00;
            endcase
        end
    endfunction

    // 数字位返回 {1'b1, nib_no[5:0]}；非数字位返回 7'd0。
    function [6:0] F_nib;
        input [6:0] I_idx;
        begin
            case (I_idx)
                7'd6 : F_nib = {1'b1, 6'd0};   // I_frame_cnt[15:12]
                7'd7 : F_nib = {1'b1, 6'd1};   // I_frame_cnt[11:8]
                7'd8 : F_nib = {1'b1, 6'd2};   // I_frame_cnt[7:4]
                7'd9 : F_nib = {1'b1, 6'd3};   // I_frame_cnt[3:0]
                7'd13: F_nib = {1'b1, 6'd4};   // I_ae[15:12]
                7'd14: F_nib = {1'b1, 6'd5};   // I_ae[11:8]
                7'd15: F_nib = {1'b1, 6'd6};   // I_ae[7:4]
                7'd16: F_nib = {1'b1, 6'd7};   // I_ae[3:0]
                7'd20: F_nib = {1'b1, 6'd8};   // I_ag[15:12]
                7'd21: F_nib = {1'b1, 6'd9};   // I_ag[11:8]
                7'd22: F_nib = {1'b1, 6'd10};   // I_ag[7:4]
                7'd23: F_nib = {1'b1, 6'd11};   // I_ag[3:0]
                7'd27: F_nib = {1'b1, 6'd12};   // I_status[23:20]
                7'd28: F_nib = {1'b1, 6'd13};   // I_status[19:16]
                7'd29: F_nib = {1'b1, 6'd14};   // I_status[15:12]
                7'd30: F_nib = {1'b1, 6'd15};   // I_status[11:8]
                7'd31: F_nib = {1'b1, 6'd16};   // I_status[7:4]
                7'd32: F_nib = {1'b1, 6'd17};   // I_status[3:0]
                7'd36: F_nib = {1'b1, 6'd18};   // I_nonzero_cnt[19:16]
                7'd37: F_nib = {1'b1, 6'd19};   // I_nonzero_cnt[15:12]
                7'd38: F_nib = {1'b1, 6'd20};   // I_nonzero_cnt[11:8]
                7'd39: F_nib = {1'b1, 6'd21};   // I_nonzero_cnt[7:4]
                7'd40: F_nib = {1'b1, 6'd22};   // I_nonzero_cnt[3:0]
                7'd44: F_nib = {1'b1, 6'd23};   // I_bright_cnt[19:16]
                7'd45: F_nib = {1'b1, 6'd24};   // I_bright_cnt[15:12]
                7'd46: F_nib = {1'b1, 6'd25};   // I_bright_cnt[11:8]
                7'd47: F_nib = {1'b1, 6'd26};   // I_bright_cnt[7:4]
                7'd48: F_nib = {1'b1, 6'd27};   // I_bright_cnt[3:0]
                7'd52: F_nib = {1'b1, 6'd28};   // I_very_cnt[19:16]
                7'd53: F_nib = {1'b1, 6'd29};   // I_very_cnt[15:12]
                7'd54: F_nib = {1'b1, 6'd30};   // I_very_cnt[11:8]
                7'd55: F_nib = {1'b1, 6'd31};   // I_very_cnt[7:4]
                7'd56: F_nib = {1'b1, 6'd32};   // I_very_cnt[3:0]
                7'd60: F_nib = {1'b1, 6'd33};   // {2'b0, I_max_px[9:8]}
                7'd61: F_nib = {1'b1, 6'd34};   // I_max_px[7:4]
                7'd62: F_nib = {1'b1, 6'd35};   // I_max_px[3:0]
                7'd66: F_nib = {1'b1, 6'd36};   // I_disp_max_px[7:4]
                7'd67: F_nib = {1'b1, 6'd37};   // I_disp_max_px[3:0]
                7'd71: F_nib = {1'b1, 6'd38};   // I_fifo_in_drop[15:12]
                7'd72: F_nib = {1'b1, 6'd39};   // I_fifo_in_drop[11:8]
                7'd73: F_nib = {1'b1, 6'd40};   // I_fifo_in_drop[7:4]
                7'd74: F_nib = {1'b1, 6'd41};   // I_fifo_in_drop[3:0]
                7'd78: F_nib = {1'b1, 6'd42};   // I_fifo_out_drop[15:12]
                7'd79: F_nib = {1'b1, 6'd43};   // I_fifo_out_drop[11:8]
                7'd80: F_nib = {1'b1, 6'd44};   // I_fifo_out_drop[7:4]
                7'd81: F_nib = {1'b1, 6'd45};   // I_fifo_out_drop[3:0]
                7'd85: F_nib = {1'b1, 6'd46};   // {3'b0, I_fifo_in_used[8]}
                7'd86: F_nib = {1'b1, 6'd47};   // I_fifo_in_used[7:4]
                7'd87: F_nib = {1'b1, 6'd48};   // I_fifo_in_used[3:0]
                7'd91: F_nib = {1'b1, 6'd49};   // {3'b0, I_fifo_out_used[8]}
                7'd92: F_nib = {1'b1, 6'd50};   // I_fifo_out_used[7:4]
                7'd93: F_nib = {1'b1, 6'd51};   // I_fifo_out_used[3:0]
                default: F_nib = 7'd0;
            endcase
        end
    endfunction

    // 行内 nibble：nib0 = 最先发送的那个（F 的最高位），nib51 = 最后一个（V 的最低位）。
    // 向量按"高编号在前"书写：最上面一项是 nib51（= V 的最低 4 位），最下面一项是 nib0。
    wire [207:0] S_nibble_vec = {
        I_fifo_out_used[3:0],          // nib51
        I_fifo_out_used[7:4],          // nib50
        {3'b0, I_fifo_out_used[8]},    // nib49
        I_fifo_in_used[3:0],           // nib48
        I_fifo_in_used[7:4],           // nib47
        {3'b0, I_fifo_in_used[8]},     // nib46
        I_fifo_out_drop[3:0],          // nib45
        I_fifo_out_drop[7:4],          // nib44
        I_fifo_out_drop[11:8],         // nib43
        I_fifo_out_drop[15:12],        // nib42
        I_fifo_in_drop[3:0],           // nib41
        I_fifo_in_drop[7:4],           // nib40
        I_fifo_in_drop[11:8],          // nib39
        I_fifo_in_drop[15:12],         // nib38
        I_disp_max_px[3:0],           // nib37
        I_disp_max_px[7:4],           // nib36
        I_max_px[3:0],            // nib35
        I_max_px[7:4],            // nib34
        {2'b0, I_max_px[9:8]},    // nib33
        I_very_cnt[3:0],           // nib32
        I_very_cnt[7:4],           // nib31
        I_very_cnt[11:8],          // nib30
        I_very_cnt[15:12],         // nib29
        I_very_cnt[19:16],         // nib28
        I_bright_cnt[3:0],         // nib27
        I_bright_cnt[7:4],         // nib26
        I_bright_cnt[11:8],        // nib25
        I_bright_cnt[15:12],       // nib24
        I_bright_cnt[19:16],       // nib23
        I_nonzero_cnt[3:0],            // nib22
        I_nonzero_cnt[7:4],            // nib21
        I_nonzero_cnt[11:8],           // nib20
        I_nonzero_cnt[15:12],          // nib19
        I_nonzero_cnt[19:16],          // nib18
        I_status[3:0],         // nib17
        I_status[7:4],         // nib16
        I_status[11:8],        // nib15
        I_status[15:12],       // nib14
        I_status[19:16],       // nib13
        I_status[23:20],       // nib12
        I_ag[3:0],             // nib11
        I_ag[7:4],             // nib10
        I_ag[11:8],            // nib9
        I_ag[15:12],           // nib8
        I_ae[3:0],             // nib7
        I_ae[7:4],             // nib6
        I_ae[11:8],            // nib5
        I_ae[15:12],           // nib4
        I_frame_cnt[3:0],          // nib3
        I_frame_cnt[7:4],          // nib2
        I_frame_cnt[11:8],         // nib1
        I_frame_cnt[15:12]         // nib0
    };

    reg [LOG_TICKS_W-1:0] S_period_cnt;
    reg        S_first_send;
    reg        S_send_busy;
    reg [6:0]  S_line_idx;
    reg [7:0]  S_tx_byte;
    reg        S_tx_start;

    reg [2:0]  S_tx_state;
    reg [CLK_PER_BIT_W-1:0] S_tx_div;
    reg [3:0]  S_tx_bit;
    reg [9:0]  S_tx_shift;

    // 下一个要发送的字节序号：发送中就是 S_line_idx+1，新开一帧就是 0。两个分支
    // 共用这一个组合结果，模板逻辑因此只被例化一份。
    wire [6:0] S_next_idx = S_send_busy ? (S_line_idx + 7'd1) : 7'd0;

    // 行模板输出：F_nib 指出当前位是不是数字位、是第几个 nibble；是数字位就查
    // nibble 向量并做一次 hex 编码，否则取常量字节表。
    wire [6:0] S_sel       = F_nib(S_next_idx);
    wire [5:0] S_nib_no    = S_sel[5:0];
    wire [3:0] S_nib_val   = S_nibble_vec[{S_nib_no, 2'b00} +: 4];
    wire [7:0] S_line_byte = S_sel[6] ? F_hex_nibble(S_nib_val) : F_tpl(S_next_idx);

    wire S_tx_done = (S_tx_state == TX_STOP) &&
                     (S_tx_div == CLK_PER_BIT - 1);

    // 说明：这里原来对 9 个输入各做了两级寄存（sync1/sync2），共约 300 个触发器。
    // 但本模块的 I_clk 就是统计计数器所在的那一个时钟（S_hdmi_pixel_clk），
    // 字段在同一个时钟域里，两级寄存器只是延迟，不提供任何同步作用；真正跨域的
    // 只有 M（RAW10 峰值），它在 design_top_wrapper 里已经用 S_dbg_raw_max_sync1/2
    // 同步过（并锁存在 _hold 里，整帧稳定）。所以直接接端口即可，见 2026-09-12
    // 的"精简调试/观测逻辑（第一批）"。

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n)
            S_period_cnt <= {LOG_TICKS_W{1'b0}};
        else if (S_period_cnt == TIMEOUT_CNT)
            S_period_cnt <= {LOG_TICKS_W{1'b0}};
        else
            S_period_cnt <= S_period_cnt + 1'b1;
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_tx_start   <= 1'b0;
            S_send_busy  <= 1'b0;
            S_line_idx   <= 7'd0;
            S_tx_byte    <= 8'h00;
            S_first_send <= 1'b1;
        end
        else begin
            S_tx_start <= 1'b0;
            if (S_send_busy) begin
                if (S_tx_done) begin
                    if (S_line_idx == LINE_LAST) begin
                        S_send_busy <= 1'b0;
                        S_line_idx  <= 7'd0;
                    end
                    else begin
                        S_line_idx <= S_line_idx + 1'b1;
                        S_tx_byte  <= S_line_byte;
                        S_tx_start <= 1'b1;
                    end
                end
            end
            else begin
                if (S_first_send || (S_period_cnt == TIMEOUT_CNT)) begin
                    S_send_busy  <= 1'b1;
                    S_line_idx   <= 7'd0;
                    S_tx_byte    <= S_line_byte;
                    S_tx_start   <= 1'b1;
                    S_first_send <= 1'b0;
                end
            end
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            O_tx       <= 1'b1;
            S_tx_state <= TX_IDLE;
            S_tx_div   <= {CLK_PER_BIT_W{1'b0}};
            S_tx_bit   <= 4'd0;
            S_tx_shift <= 10'd0;
        end
        else begin
            if (S_tx_div == CLK_PER_BIT - 1)
                S_tx_div <= {CLK_PER_BIT_W{1'b0}};
            else
                S_tx_div <= S_tx_div + 1'b1;

            case (S_tx_state)
                TX_IDLE: begin
                    O_tx <= 1'b1;
                    if (S_tx_start) begin
                        S_tx_state <= TX_START;
                        S_tx_shift <= {1'b1, S_tx_byte, 1'b0};
                        S_tx_div   <= {CLK_PER_BIT_W{1'b0}};
                        S_tx_bit   <= 4'd0;
                    end
                end
                TX_START: begin
                    O_tx <= 1'b0;
                    if (S_tx_div == CLK_PER_BIT - 1) begin
                        S_tx_state <= TX_DATA;
                        // 进入数据位前先右移一次，避免把起始位再次当作数据位发送
                        S_tx_shift <= {1'b0, S_tx_shift[9:1]};
                    end
                end
                TX_DATA: begin
                    O_tx <= S_tx_shift[0];
                    if (S_tx_div == CLK_PER_BIT - 1) begin
                        S_tx_shift <= {1'b0, S_tx_shift[9:1]};
                        S_tx_bit   <= S_tx_bit + 1'b1;
                        if (S_tx_bit == 4'd7)
                            S_tx_state <= TX_STOP;
                    end
                end
                TX_STOP: begin
                    O_tx <= 1'b1;
                    if (S_tx_div == CLK_PER_BIT - 1)
                        S_tx_state <= TX_IDLE;
                end
                default: begin
                    O_tx       <= 1'b1;
                    S_tx_state <= TX_IDLE;
                end
            endcase
        end
    end

endmodule
