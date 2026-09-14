// ============================================================================
// key_event —— 像素域的按键事件（20 ms 消抖 + 1 s 长按），KEY1 / KEY4 各一个实例
//
// 板载按键低有效（按下为 0）。输出三类事件，都是 1 拍脉冲：
//   O_short ：消抖后按下、并在 LONG_MS 之前松开（短按）
//   O_long  ：消抖后按住达到 LONG_MS（跨过阈值时只发一次，松手不再补短按）
//   O_level ：消抖后的电平（0 = 按下），给需要"按住"语义的场合兜底
//
// 延迟：消抖本身按 DEBOUNCE_MS 计；事件脉冲在判定成立的当拍给出。
// 时钟域：像素域（75 MHz）单时钟，不跨域（按键是异步输入，内部两级同步）。
// 资源：约 40 FF + 30 LUT（长按计数器 27 位）。
// ============================================================================
module key_event #(
    parameter integer CLK_HZ      = 75000000,
    parameter integer DEBOUNCE_MS = 20,
    parameter integer LONG_MS     = 1000,
    // HAS_LONG = 0 时整块长按检测都不生成（KEY1 只需要短按，省掉一个 27 位计数器与
    // 比较器：M0 优化实测每个实例约 20 LUT / 27 FF）。
    parameter integer HAS_LONG    = 1
)(
    input  wire I_clk,
    input  wire I_rst_n,
    input  wire I_key,
    output reg  O_short,
    output reg  O_long,
    output reg  O_level
);

    localparam integer DEB_TICKS  = (CLK_HZ / 1000) * DEBOUNCE_MS;
    localparam integer LONG_TICKS = (CLK_HZ / 1000) * LONG_MS;
    localparam integer DEB_W      = $clog2(DEB_TICKS);
    localparam integer LONG_W     = $clog2(LONG_TICKS);

    // 输入两级同步（按键对 75 MHz 是异步信号）
    reg [1:0] S_sync;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) S_sync <= 2'b11;
        else         S_sync <= {S_sync[0], I_key};
    end

    // 电平消抖：输入电平与已接受电平不同且持续 DEB_TICKS 才翻面
    reg [DEB_W-1:0] S_deb_cnt;
    reg             S_level;
    reg             S_level_d;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_level   <= 1'b1;
            S_level_d <= 1'b1;
            S_deb_cnt <= {DEB_W{1'b0}};
        end
        else begin
            S_level_d <= S_level;
            if(S_sync[1] != S_level) begin
                if(S_deb_cnt == DEB_TICKS - 1) begin
                    S_level   <= S_sync[1];
                    S_deb_cnt <= {DEB_W{1'b0}};
                end
                else
                    S_deb_cnt <= S_deb_cnt + 1'b1;
            end
            else
                S_deb_cnt <= {DEB_W{1'b0}};
        end
    end

    wire S_press   = ~S_level &  S_level_d;   // 消抖后按下沿
    wire S_release =  S_level & ~S_level_d;   // 消抖后松开沿

    reg  S_pressed;
    reg  S_long_seen;     // 本次按下已判定为长按（松手时不再补短按）
    wire S_long_now;      // 本拍达到长按阈值

    generate
    if (HAS_LONG) begin : g_long
        reg [LONG_W-1:0] S_long_cnt;

        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n)
                S_long_cnt <= {LONG_W{1'b0}};
            else if(!S_pressed)
                S_long_cnt <= {LONG_W{1'b0}};
            else if(S_long_cnt != LONG_TICKS - 1)
                S_long_cnt <= S_long_cnt + 1'b1;
        end

        // 计数停在阈值上，所以 S_long_now 会一直是 1；一次性由 S_long_seen 保证。
        assign S_long_now = (S_pressed && (S_long_cnt == LONG_TICKS - 1));
    end
    else begin : g_no_long
        assign S_long_now = 1'b0;
    end
    endgenerate

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_pressed   <= 1'b0;
            S_long_seen <= 1'b0;
            O_short     <= 1'b0;
            O_long      <= 1'b0;
            O_level     <= 1'b1;
        end
        else begin
            O_short <= 1'b0;
            O_long  <= 1'b0;
            O_level <= S_level;

            if(S_press) begin
                S_pressed   <= 1'b1;
                S_long_seen <= 1'b0;
            end

            if(S_long_now && !S_long_seen) begin
                S_long_seen <= 1'b1;
                O_long      <= 1'b1;
            end

            if(S_release) begin
                if(S_pressed && !S_long_seen)
                    O_short <= 1'b1;
                S_pressed   <= 1'b0;
                S_long_seen <= 1'b0;
            end
        end
    end

endmodule
