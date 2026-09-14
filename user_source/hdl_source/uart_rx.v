// ============================================================================
// uart_rx —— 115200-8-N-1 接收（像素域过采样，起始位中点对齐）
//
// 板载 USB-UART 的 RXD 引脚（J1）直接进本模块。75 MHz / 115200 ≈ 651 拍/位，
// 过采样足够，不需要额外时钟域。位宽一律用 $clog2 从参数推导（不要写死，
// 见 README 第 7 节那次"分频计数器位宽不够，TXD 恒低"的坑）。
//
// 延迟：一帧（10 位）约 87 us。
// 时钟域：像素域；输入是异步串行信号，内部两级同步。
// 资源：约 30 FF + 30 LUT。
// ============================================================================
module uart_rx #(
    parameter integer CLK_HZ = 75000000,
    parameter integer BAUD   = 115200
)(
    input  wire       I_clk,
    input  wire       I_rst_n,
    input  wire       I_rx,
    output reg  [7:0] O_data,
    output reg        O_valid   // 1 拍脉冲：收到一个字节
);

    localparam integer CLK_PER_BIT   = (CLK_HZ + (BAUD / 2)) / BAUD;
    localparam integer CLK_PER_BIT_W = $clog2(CLK_PER_BIT);

    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_START = 2'd1;
    localparam [1:0] S_DATA  = 2'd2;
    localparam [1:0] S_STOP  = 2'd3;

    reg [2:0]  S_sync;
    reg [1:0]  S_state;
    reg [CLK_PER_BIT_W-1:0] S_div;
    reg [2:0]  S_bit;
    reg [7:0]  S_shift;

    wire S_line = S_sync[2];

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_sync  <= 3'b111;
            S_state <= S_IDLE;
            S_div   <= {CLK_PER_BIT_W{1'b0}};
            S_bit   <= 3'd0;
            S_shift <= 8'd0;
            O_data  <= 8'd0;
            O_valid <= 1'b0;
        end
        else begin
            S_sync  <= {S_sync[1:0], I_rx};
            O_valid <= 1'b0;

            case(S_state)
                S_IDLE: begin
                    // 起始位下降沿：等半个位宽，正好落在起始位中点
                    if(!S_line) begin
                        S_state <= S_START;
                        S_div   <= (CLK_PER_BIT >> 1);
                    end
                end

                S_START: begin
                    if(S_div == {CLK_PER_BIT_W{1'b0}}) begin
                        S_state <= S_DATA;
                        S_div   <= CLK_PER_BIT - 1;
                        S_bit   <= 3'd0;
                    end
                    else
                        S_div <= S_div - 1'b1;
                end

                S_DATA: begin
                    if(S_div == {CLK_PER_BIT_W{1'b0}}) begin
                        // 采样点在每一位的中点：LSB 先到
                        S_shift <= {S_line, S_shift[7:1]};
                        S_div   <= CLK_PER_BIT - 1;
                        if(S_bit == 3'd7)
                            S_state <= S_STOP;
                        else
                            S_bit <= S_bit + 1'b1;
                    end
                    else
                        S_div <= S_div - 1'b1;
                end

                S_STOP: begin
                    if(S_div == {CLK_PER_BIT_W{1'b0}}) begin
                        O_data  <= S_shift;
                        O_valid <= 1'b1;
                        S_state <= S_IDLE;
                    end
                    else
                        S_div <= S_div - 1'b1;
                end

                default: S_state <= S_IDLE;
            endcase
        end
    end

endmodule
