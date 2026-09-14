// ============================================================================
// uart_cmd —— 串口在线调参命令解析（ASCII，只写不回显）
//
// 命令格式：`W <addr 2 位hex> <data 4 位hex>` + CR/LF
//   例：`W 02 0003` → 写地址 0x02（EDGE 门限档位）= 0x0003（TH=28）
//   大小写通吃；多余的空白允许；非法字符或长度不对 → 整行丢弃，不回显。
// 数值是人为选 ASCII 的：现场用串口助手就能敲，脚本也好写；代价是每个命令约
// 20 字节（115200 下 ~1.7 ms），调参场景完全够。
//
// 生效确认：不做回显，看 DBG 行的 S 字段（提交后的生效门限）与 O_param_wr_cnt。
//
// 延迟：收到行尾后 1 拍输出写脉冲。
// 时钟域：像素域单时钟。
// 资源：约 40 FF + 60 LUT。
// ============================================================================
module uart_cmd (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire [7:0]  I_byte,
    input  wire        I_byte_valid,
    output reg         O_we,
    output reg  [7:0]  O_addr,
    output reg  [15:0] O_data
);

    // 返回 {合法标志, 数值}
    function [4:0] F_hexv;
        input [7:0] I_c;
        begin
            if((I_c >= 8'h30) && (I_c <= 8'h39))
                F_hexv = {1'b1, I_c[3:0]};
            else if((I_c >= 8'h41) && (I_c <= 8'h46))
                F_hexv = {1'b1, I_c[3:0] + 4'd9};
            else if((I_c >= 8'h61) && (I_c <= 8'h66))
                F_hexv = {1'b1, I_c[3:0] + 4'd9};
            else
                F_hexv = 5'd0;
        end
    endfunction

    reg [23:0] S_acc;      // 收到的 6 个 hex 位：{addr[7:0], data[15:0]}
    reg [2:0]  S_nib;
    reg        S_active;   // 已经看到开头的 'W'

    wire [4:0] S_hex   = F_hexv(I_byte);
    wire       S_is_w  = (I_byte == 8'h57) || (I_byte == 8'h77);
    wire       S_is_eol= (I_byte == 8'h0d) || (I_byte == 8'h0a);
    wire       S_is_sp = (I_byte == 8'h20);

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_acc   <= 24'd0;
            S_nib   <= 3'd0;
            S_active<= 1'b0;
            O_we    <= 1'b0;
            O_addr  <= 8'd0;
            O_data  <= 16'd0;
        end
        else begin
            O_we <= 1'b0;

            if(I_byte_valid) begin
                if(S_is_eol) begin
                    if(S_active && (S_nib == 3'd6)) begin
                        O_addr <= S_acc[23:16];
                        O_data <= S_acc[15:0];
                        O_we   <= 1'b1;
                    end
                    S_acc    <= 24'd0;
                    S_nib    <= 3'd0;
                    S_active <= 1'b0;
                end
                else if(!S_active) begin
                    if(S_is_w) S_active <= 1'b1;   // 行首不是 W 就一直等到行尾
                end
                else if(S_hex[4]) begin
                    S_acc <= {S_acc[19:0], S_hex[3:0]};
                    if(S_nib != 3'd7) S_nib <= S_nib + 1'b1;
                end
                else if(!S_is_sp) begin
                    S_nib <= 3'd7;                 // 非法字符：整行作废（EOL 时不会触发写）
                end
            end
        end
    end

endmodule
