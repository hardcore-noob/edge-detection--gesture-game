/*
 * 算法切换控制模块（整合工程新增）
 * 板载按键为低有效（按下为 0），本模块内置：
 *   1) 4 级触发器同步，消除亚稳态；
 *   2) 20ms 电平消抖（24MHz 时钟下计数 480000）；
 *   3) 按下沿触发，每次按下切换一次算法。
 *
 * 算法编码：
 *   0 = RAW  （原始画面，AWB 输出）
 *   1 = EDGE （边缘检测画面，edge_detect_96 输出）
 * 电平输出给顶层做跨时钟域同步，最终在帧起始处生效。
 */
module alg_switch (
    input  wire I_clk,
    input  wire I_rst_n,
    input  wire I_key,
    output reg  O_alg_sel
);

    reg [3:0]   S_key_sync;
    reg         S_key_stable;
    reg         S_key_stable_1d;
    reg [18:0]  S_deb_cnt;
    wire        S_press_edge;

    // 输入同步
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            S_key_sync <= 4'b1111;
        else
            S_key_sync <= {S_key_sync[2:0], I_key};
    end

    // 20ms 消抖，S_key_stable = 1 表示松开，0 表示按下
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_key_stable    <= 1'b1;
            S_key_stable_1d <= 1'b1;
            S_deb_cnt       <= 19'd0;
        end
        else begin
            S_key_stable_1d <= S_key_stable;
            if(S_key_sync[3] != S_key_stable) begin
                if(S_deb_cnt == 19'd480000) begin
                    S_key_stable <= S_key_sync[3];
                    S_deb_cnt    <= 19'd0;
                end
                else begin
                    S_deb_cnt <= S_deb_cnt + 19'd1;
                end
            end
            else begin
                S_deb_cnt <= 19'd0;
            end
        end
    end

    // 按下沿：稳定电平由松开(1)变为按下(0)
    assign S_press_edge = S_key_stable_1d & ~S_key_stable;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            O_alg_sel <= 1'b0;
        else if(S_press_edge)
            O_alg_sel <= ~O_alg_sel;
    end

endmodule
