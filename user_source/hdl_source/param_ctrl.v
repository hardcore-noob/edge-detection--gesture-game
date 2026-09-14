// ============================================================================
// param_ctrl —— PARAM_BUS 插座的寄存器文件与写入仲裁（像素域）
//
// 写口约定：param_we / param_addr[7:0] / param_data[15:0]，单拍脉冲，像素域。
// 源优先级：UART 命令 > KEY4 长按（示教） > KEY4 短按（游戏层开关） >
//           KEY1 短按（RAW/EDGE）> 拨码开关变化（20 ms 消抖）。
//
// M0 地址表（0x40~0x7F A 段、0x80~0xBF B 段、0xC0~0xFF C 段留给后续里程碑）：
//   0x00 display_mode[3:0]  R/W  0=RAW, 1=EDGE
//   0x01 game_mode[3:0]     R/W  0=关
//   0x02 edge_th_sel[3:0]   R/W  EDGE 门限档位：TH = 16 + 4×sel
//   0x03 teach_req          W1P  写 1 触发一次示教请求（M1 消费）
//   0x04 teach_cnt[15:0]    RO   示教请求累计次数
//   0x05 key4_evt[7:0]      RO   {长按次数[3:0], 短按次数[3:0]}
//   0x06 param_wr_cnt[15:0] RO   成功写入次数（UART 命令是否真的落地，看这个）
//   0x07 mode_commit_cnt    RO   模式在相机帧首提交的次数
//
// 模式值本身要跨到 CSI 域、在帧首提交（见 mode_sync），所以这里输出的 display_mode /
// edge_th_sel 是"请求值"，DBG 行的 S 字段显示的是提交后的生效值。
//
// 延迟：写 1 拍生效；拨码消抖 20 ms。
// 时钟域：像素域单时钟；按键/拨码是异步输入，内部两级同步。
// 资源：约 150 FF + 120 LUT，无 ERAM / DSP。
// ============================================================================
module param_ctrl #(
    parameter integer CLK_HZ         = 75000000,
    parameter integer SW_DEBOUNCE_MS = 20
)(
    input  wire        I_clk,
    input  wire        I_rst_n,

    // 按键事件（像素域 1 拍脉冲，由 key_event 产生）
    input  wire        I_key1_short,
    input  wire        I_key4_short,
    input  wire        I_key4_long,

    // 拨码开关（原始电平，内部同步 + 消抖）
    input  wire [3:0]  I_sw_raw,

    // 外部写（UART 命令解析器）
    input  wire        I_ext_we,
    input  wire [7:0]  I_ext_addr,
    input  wire [15:0] I_ext_data,

    // 模式提交回执（来自 mode_sync 的像素侧）
    input  wire        I_commit_pulse,

    // 读回（M0 暂无消费者，M1 起给 OSD/DBG 用）
    input  wire [7:0]  I_rd_addr,
    output reg  [15:0] O_rd_data,

    // 对外状态
    output reg  [3:0]  O_display_mode,
    output reg  [3:0]  O_game_mode,
    output reg  [3:0]  O_edge_th_sel,
    output wire [10:0] O_edge_th,
    output reg  [15:0] O_teach_cnt,
    output reg  [15:0] O_param_wr_cnt,
    output reg  [15:0] O_mode_commit_cnt,
    output reg  [7:0]  O_key4_evt,
    output reg         O_teach_req,
    output wire [15:0] O_mode_word,
    output wire [3:0]  O_led
);

    localparam integer SW_TICKS = (CLK_HZ / 1000) * SW_DEBOUNCE_MS;
    localparam integer SW_W     = $clog2(SW_TICKS);

    // ---- 拨码开关：两级同步 + 20 ms 电平消抖 ---------------------------------
    reg [1:0]      S_sw_s1;
    reg [1:0]      S_sw_s2;
    reg [3:0]      S_sw_level;
    reg [SW_W-1:0] S_sw_cnt;
    reg [3:0]      S_sw_seen;     // 已经上报给寄存器的值

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_sw_s1    <= 2'b00;
            S_sw_s2    <= 2'b00;
            S_sw_level <= 4'd0;
            S_sw_cnt   <= {SW_W{1'b0}};
        end
        else begin
            S_sw_s1 <= {I_sw_raw[1], I_sw_raw[0]};
            S_sw_s2 <= {I_sw_raw[3], I_sw_raw[2]};

            // 两个 2 位同步器拼起来就是 4 位的两级同步（省一半触发器）
            if({S_sw_s2[1], S_sw_s1[1], S_sw_s2[0], S_sw_s1[0]} != S_sw_level) begin
                if(S_sw_cnt == SW_TICKS - 1) begin
                    S_sw_level <= {S_sw_s2[1], S_sw_s1[1], S_sw_s2[0], S_sw_s1[0]};
                    S_sw_cnt   <= {SW_W{1'b0}};
                end
                else
                    S_sw_cnt <= S_sw_cnt + 1'b1;
            end
            else
                S_sw_cnt <= {SW_W{1'b0}};
        end
    end

    wire S_sw_changed = (S_sw_level != S_sw_seen);

    // ---- 写仲裁 -------------------------------------------------------------
    reg [7:0]  S_addr;
    reg [15:0] S_wdata;
    reg        S_we;

    always @(*) begin
        S_we    = 1'b1;
        S_addr  = 8'h00;
        S_wdata = 16'd0;

        if(I_ext_we) begin                       // UART 命令
            S_addr  = I_ext_addr;
            S_wdata = I_ext_data;
        end
        else if(I_key4_long) begin               // 一键示教请求
            S_addr  = 8'h03;
            S_wdata = 16'h0001;
        end
        else if(I_key4_short) begin              // 游戏层开 / 关
            S_addr  = 8'h01;
            S_wdata = {12'b0, ~O_game_mode[0]};
        end
        else if(I_key1_short) begin              // RAW / EDGE
            S_addr  = 8'h00;
            S_wdata = {12'b0, ~O_display_mode[0]};
        end
        else if(S_sw_changed) begin              // 门限档位（现场拨码）
            S_addr  = 8'h02;
            S_wdata = {12'b0, S_sw_level};
        end
        else
            S_we = 1'b0;
    end

    // ---- 寄存器写入 ---------------------------------------------------------
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            O_display_mode    <= 4'd0;
            O_game_mode       <= 4'd0;
            O_edge_th_sel     <= 4'd0;
            O_teach_cnt       <= 16'd0;
            O_param_wr_cnt    <= 16'd0;
            O_mode_commit_cnt <= 16'd0;
            O_key4_evt        <= 8'd0;
            O_teach_req       <= 1'b0;
            S_sw_seen         <= 4'd0;
        end
        else begin
            O_teach_req <= 1'b0;

            if(S_sw_changed)
                S_sw_seen <= S_sw_level;

            if(S_we) begin
                case(S_addr)
                    8'h00: begin
                        O_display_mode <= S_wdata[3:0];
                        O_param_wr_cnt <= O_param_wr_cnt + 1'b1;
                    end
                    8'h01: begin
                        O_game_mode    <= S_wdata[3:0];
                        O_param_wr_cnt <= O_param_wr_cnt + 1'b1;
                    end
                    8'h02: begin
                        O_edge_th_sel  <= S_wdata[3:0];
                        O_param_wr_cnt <= O_param_wr_cnt + 1'b1;
                    end
                    8'h03: begin
                        O_teach_req    <= 1'b1;
                        O_teach_cnt    <= O_teach_cnt + 1'b1;
                        O_param_wr_cnt <= O_param_wr_cnt + 1'b1;
                    end
                    default: ;   // 未登记地址：忽略
                endcase
            end

            if(I_key4_short)
                O_key4_evt[3:0] <= O_key4_evt[3:0] + 1'b1;
            if(I_key4_long)
                O_key4_evt[7:4] <= O_key4_evt[7:4] + 1'b1;

            if(I_commit_pulse)
                O_mode_commit_cnt <= O_mode_commit_cnt + 1'b1;
        end
    end

    // 门限档位 → 实际门限值（1 bit 数据 ×4 就是 sel<<2，16 + 4×sel = 16..76）
    assign O_edge_th = 11'd16 + ({7'b0, O_edge_th_sel} << 2);

    // 给 OSD / DBG 的模式字：{8'h0, game_mode[3:0], display_mode[3:0]}
    assign O_mode_word = {8'h00, O_game_mode, O_display_mode};

    // ---- 板载 4 个独立 LED ---------------------------------------------------
    // {KEY4 事件闪 0.3 s, 心跳 ~1.1 Hz, game_mode 指示, display_mode 指示}
    reg [24:0] S_hb_cnt;
    reg [24:0] S_flash_cnt;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_hb_cnt    <= 25'd0;
            S_flash_cnt <= 25'd0;
        end
        else begin
            S_hb_cnt <= S_hb_cnt + 1'b1;      // 位 24：75 MHz / 2^25 ≈ 0.45 s 翻转

            if(I_key4_short | I_key4_long)
                S_flash_cnt <= 25'd22500000;  // 75 MHz × 0.3 s
            else if(S_flash_cnt != 25'd0)
                S_flash_cnt <= S_flash_cnt - 1'b1;
        end
    end

    assign O_led = { (S_flash_cnt != 25'd0), S_hb_cnt[24],
                     (O_game_mode != 4'd0), O_display_mode[0] };

    // ---- 读回 ---------------------------------------------------------------
    always @(*) begin
        case(I_rd_addr)
            8'h00:   O_rd_data = {12'b0, O_display_mode};
            8'h01:   O_rd_data = {12'b0, O_game_mode};
            8'h02:   O_rd_data = {12'b0, O_edge_th_sel};
            8'h03:   O_rd_data = {15'b0, O_teach_req};
            8'h04:   O_rd_data = O_teach_cnt;
            8'h05:   O_rd_data = {8'b0, O_key4_evt};
            8'h06:   O_rd_data = O_param_wr_cnt;
            8'h07:   O_rd_data = O_mode_commit_cnt;
            default: O_rd_data = 16'hFFFF;
        endcase
    end

endmodule
