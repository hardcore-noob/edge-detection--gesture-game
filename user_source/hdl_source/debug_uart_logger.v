/*
 * 运行时调试日志：通过板载 USB-UART (TXD=H1) 以 115200-8-N-1 输出。
 *
 * 每 1 秒输出一帧状态，字段：
 *   F    HDMI 显示帧计数        (HEX)
 *   A    AE 曝光目标值           (HEX)
 *   G    AG 增益目标值           (HEX)
 *   T    24 位流水线状态位图     (HEX)
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
    output reg         O_tx
);

    localparam integer CLK_PER_BIT = (CLK_HZ + BAUD - 1) / BAUD;
    localparam [25:0] TIMEOUT_CNT =
        ((CLK_HZ / 1000) * LOG_PERIOD_MS) - 1;

    localparam [2:0] TX_IDLE  = 3'd0;
    localparam [2:0] TX_START = 3'd1;
    localparam [2:0] TX_DATA  = 3'd2;
    localparam [2:0] TX_STOP  = 3'd3;

    localparam [6:0] LINE_LAST = 7'd69;

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

    function [7:0] F_line_byte;
        input [6:0]  I_idx;
        input [23:0] I_status;
        input [15:0] I_frame;
        input [15:0] I_ae;
        input [15:0] I_ag;
        input [19:0] I_cnt;
        input [19:0] I_bright;
        input [19:0] I_very;
        input [9:0]  I_max;
        input [7:0]  I_dmax;
        begin
            case (I_idx)
                6'd0:  F_line_byte = 8'h44;
                6'd1:  F_line_byte = 8'h42;
                6'd2:  F_line_byte = 8'h47;
                6'd3:  F_line_byte = 8'h3A;
                6'd4:  F_line_byte = 8'h46;
                6'd5:  F_line_byte = 8'h3D;
                6'd6:  F_line_byte = F_hex_nibble(I_frame[15:12]);
                6'd7:  F_line_byte = F_hex_nibble(I_frame[11:8]);
                6'd8:  F_line_byte = F_hex_nibble(I_frame[7:4]);
                6'd9:  F_line_byte = F_hex_nibble(I_frame[3:0]);
                6'd10: F_line_byte = 8'h20;
                6'd11: F_line_byte = 8'h41;
                6'd12: F_line_byte = 8'h3D;
                6'd13: F_line_byte = F_hex_nibble(I_ae[15:12]);
                6'd14: F_line_byte = F_hex_nibble(I_ae[11:8]);
                6'd15: F_line_byte = F_hex_nibble(I_ae[7:4]);
                6'd16: F_line_byte = F_hex_nibble(I_ae[3:0]);
                6'd17: F_line_byte = 8'h20;
                6'd18: F_line_byte = 8'h47;
                6'd19: F_line_byte = 8'h3D;
                6'd20: F_line_byte = F_hex_nibble(I_ag[15:12]);
                6'd21: F_line_byte = F_hex_nibble(I_ag[11:8]);
                6'd22: F_line_byte = F_hex_nibble(I_ag[7:4]);
                6'd23: F_line_byte = F_hex_nibble(I_ag[3:0]);
                6'd24: F_line_byte = 8'h20;
                6'd25: F_line_byte = 8'h54;
                6'd26: F_line_byte = 8'h3D;
                6'd27: F_line_byte = F_hex_nibble(I_status[23:20]);
                6'd28: F_line_byte = F_hex_nibble(I_status[19:16]);
                6'd29: F_line_byte = F_hex_nibble(I_status[15:12]);
                6'd30: F_line_byte = F_hex_nibble(I_status[11:8]);
                6'd31: F_line_byte = F_hex_nibble(I_status[7:4]);
                6'd32: F_line_byte = F_hex_nibble(I_status[3:0]);
                6'd33: F_line_byte = 8'h20;
                6'd34: F_line_byte = 8'h4E;
                6'd35: F_line_byte = 8'h3D;
                6'd36: F_line_byte = F_hex_nibble(I_cnt[19:16]);
                6'd37: F_line_byte = F_hex_nibble(I_cnt[15:12]);
                6'd38: F_line_byte = F_hex_nibble(I_cnt[11:8]);
                6'd39: F_line_byte = F_hex_nibble(I_cnt[7:4]);
                6'd40: F_line_byte = F_hex_nibble(I_cnt[3:0]);
                6'd41: F_line_byte = 8'h20;
                6'd42: F_line_byte = 8'h42;
                6'd43: F_line_byte = 8'h3D;
                6'd44: F_line_byte = F_hex_nibble(I_bright[19:16]);
                6'd45: F_line_byte = F_hex_nibble(I_bright[15:12]);
                6'd46: F_line_byte = F_hex_nibble(I_bright[11:8]);
                6'd47: F_line_byte = F_hex_nibble(I_bright[7:4]);
                6'd48: F_line_byte = F_hex_nibble(I_bright[3:0]);
                6'd49: F_line_byte = 8'h20;
                6'd50: F_line_byte = 8'h43;
                6'd51: F_line_byte = 8'h3D;
                6'd52: F_line_byte = F_hex_nibble(I_very[19:16]);
                6'd53: F_line_byte = F_hex_nibble(I_very[15:12]);
                6'd54: F_line_byte = F_hex_nibble(I_very[11:8]);
                6'd55: F_line_byte = F_hex_nibble(I_very[7:4]);
                6'd56: F_line_byte = F_hex_nibble(I_very[3:0]);
                6'd57: F_line_byte = 8'h20;
                6'd58: F_line_byte = 8'h4D;
                6'd59: F_line_byte = 8'h3D;
                6'd60: F_line_byte = F_hex_nibble({2'b0, I_max[9:8]});
                6'd61: F_line_byte = F_hex_nibble(I_max[7:4]);
                6'd62: F_line_byte = F_hex_nibble(I_max[3:0]);
                6'd63: F_line_byte = 8'h20;
                6'd64: F_line_byte = 8'h4C;
                6'd65: F_line_byte = 8'h3D;
                6'd66: F_line_byte = F_hex_nibble(I_dmax[7:4]);
                6'd67: F_line_byte = F_hex_nibble(I_dmax[3:0]);
                6'd68: F_line_byte = 8'h0D;
                7'd69: F_line_byte = 8'h0A;
                default: F_line_byte = 8'h20;
            endcase
        end
    endfunction

    reg [25:0] S_period_cnt;
    reg        S_first_send;
    reg        S_send_busy;
    reg [6:0]  S_line_idx;
    reg [7:0]  S_tx_byte;
    reg        S_tx_start;

    reg [2:0]  S_tx_state;
    reg [8:0]  S_tx_div;
    reg [3:0]  S_tx_bit;
    reg [9:0]  S_tx_shift;

    reg [23:0] S_status_sync1;
    reg [23:0] S_status_sync2;
    reg [15:0] S_frame_sync1;
    reg [15:0] S_frame_sync2;
    reg [15:0] S_ae_sync1;
    reg [15:0] S_ae_sync2;
    reg [15:0] S_ag_sync1;
    reg [15:0] S_ag_sync2;
    reg [19:0] S_nonzero_sync1;
    reg [19:0] S_nonzero_sync2;
    reg [19:0] S_bright_sync1;
    reg [19:0] S_bright_sync2;
    reg [19:0] S_very_sync1;
    reg [19:0] S_very_sync2;
    reg [9:0]  S_max_sync1;
    reg [9:0]  S_max_sync2;
    reg [7:0]  S_dmax_sync1;
    reg [7:0]  S_dmax_sync2;

    wire S_tx_done = (S_tx_state == TX_STOP) &&
                     (S_tx_div == CLK_PER_BIT - 1);

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            S_status_sync1 <= 24'd0;
            S_status_sync2 <= 24'd0;
            S_frame_sync1  <= 16'd0;
            S_frame_sync2  <= 16'd0;
            S_ae_sync1     <= 16'd0;
            S_ae_sync2     <= 16'd0;
            S_ag_sync1     <= 16'd0;
            S_ag_sync2     <= 16'd0;
            S_nonzero_sync1 <= 20'd0;
            S_nonzero_sync2 <= 20'd0;
            S_bright_sync1 <= 20'd0;
            S_bright_sync2 <= 20'd0;
            S_very_sync1 <= 20'd0;
            S_very_sync2 <= 20'd0;
            S_max_sync1 <= 10'd0;
            S_max_sync2 <= 10'd0;
            S_dmax_sync1 <= 8'd0;
            S_dmax_sync2 <= 8'd0;
        end
        else begin
            S_status_sync1 <= I_status;
            S_status_sync2 <= S_status_sync1;
            S_frame_sync1  <= I_frame_cnt;
            S_frame_sync2  <= S_frame_sync1;
            S_ae_sync1     <= I_ae;
            S_ae_sync2     <= S_ae_sync1;
            S_ag_sync1     <= I_ag;
            S_ag_sync2     <= S_ag_sync1;
            S_nonzero_sync1 <= I_nonzero_cnt;
            S_nonzero_sync2 <= S_nonzero_sync1;
            S_bright_sync1 <= I_bright_cnt;
            S_bright_sync2 <= S_bright_sync1;
            S_very_sync1 <= I_very_cnt;
            S_very_sync2 <= S_very_sync1;
            S_max_sync1 <= I_max_px;
            S_max_sync2 <= S_max_sync1;
            S_dmax_sync1 <= I_disp_max_px;
            S_dmax_sync2 <= S_dmax_sync1;
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n)
            S_period_cnt <= 26'd0;
        else if (S_period_cnt == TIMEOUT_CNT)
            S_period_cnt <= 26'd0;
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
                        S_tx_byte  <= F_line_byte(
                            S_line_idx + 1'b1,
                            S_status_sync2,
                            S_frame_sync2,
                            S_ae_sync2,
                            S_ag_sync2,
                            S_nonzero_sync2,
                            S_bright_sync2,
                            S_very_sync2,
                            S_max_sync2,
                            S_dmax_sync2
                        );
                        S_tx_start <= 1'b1;
                    end
                end
            end
            else begin
                if (S_first_send || (S_period_cnt == TIMEOUT_CNT)) begin
                    S_send_busy  <= 1'b1;
                    S_line_idx   <= 7'd0;
                    S_tx_byte    <= F_line_byte(
                        6'd0,
                        S_status_sync2,
                        S_frame_sync2,
                        S_ae_sync2,
                        S_ag_sync2,
                        S_nonzero_sync2,
                        S_bright_sync2,
                        S_very_sync2,
                        S_max_sync2,
                        S_dmax_sync2
                    );
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
            S_tx_div   <= 9'd0;
            S_tx_bit   <= 4'd0;
            S_tx_shift <= 10'd0;
        end
        else begin
            if (S_tx_div == CLK_PER_BIT - 1)
                S_tx_div <= 9'd0;
            else
                S_tx_div <= S_tx_div + 1'b1;

            case (S_tx_state)
                TX_IDLE: begin
                    O_tx <= 1'b1;
                    if (S_tx_start) begin
                        S_tx_state <= TX_START;
                        S_tx_shift <= {1'b1, S_tx_byte, 1'b0};
                        S_tx_div   <= 9'd0;
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
