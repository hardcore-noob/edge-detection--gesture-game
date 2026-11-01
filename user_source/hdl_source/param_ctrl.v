// ============================================================================
// param_ctrl —— PARAM_BUS 插座的寄存器文件与写入仲裁（像素域）
//
// 写口约定：param_we / param_addr[7:0] / param_data[15:0]，单拍脉冲，像素域。
// 源优先级：UART 命令 > KEY4 长按（示教） > KEY4 短按（游戏层开关） >
//           KEY1 短按（RAW/EDGE）> 拨码开关变化（20 ms 消抖）。
//
// M0 地址表（0x40~0x7F A 段、0x80~0xBF B 段、0xC0~0xFF C 段留给后续里程碑）：
//   0x00 display_mode[3:0]  R/W  0=RAW, 1=EDGE
//   0x01 game_mode[3:0]     R/W  0=关 / 1=切水果 / 2=接果篮
//   0x02 edge_th_sel[3:0]   R/W  EDGE 门限档位：TH = 16 + 4×sel
//   0x03 teach_req          W1P  写 1 触发一次示教请求（M1 消费）
//   0x04 teach_cnt[15:0]    RO   示教请求累计次数
//   0x05 key4_evt[7:0]      RO   {长按次数[3:0], 短按次数[3:0]}
//   0x06 param_wr_cnt[15:0] RO   成功写入次数（UART 命令是否真的落地，看这个）
//   0x07 mode_commit_cnt    RO   模式在相机帧首提交的次数
//   0x08 recog_algo[3:0]    R/W  0 = 识别停 / 1 = 手势识别（M1 消费）
//                               KEY4 短按循环 0→1→2→0，进入任一游戏置 1、退出置 0
//
// 0x80~0xBF（B 段）不在本模块解析，而是用 O_b_we/O_b_addr/O_b_wdata 原样转发给
// game_top 的 game_param；读回由 I_b_rd_data 按段选通（M4a 接通，2026-10-13）。

// 模式值本身要跨到 CSI 域、在帧首提交（见 mode_sync），所以这里输出的 display_mode /
// edge_th_sel 是"请求值"，DBG 行的 S 字段显示的是提交后的生效值。

//
// 跨域判据（2026-09-17 定）：**算法类**（display_mode / game_mode / recog_algo）经 mode_sync
// 在相机帧首提交到 CSI 域（26 位字，布局见 mode_sync 头注释）；**系数类**（肤色上下限 /
// 运动阈值 / quiet_th）**不走这里**——A 的阈值由 CSI 域自己的示教逻辑用 min/max 包络
// 产生并保存，A 段 0x40~0x7F 只保留"读回来复盘"的语义。
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

    // 显示帧同步脉冲（帧首 1 拍）：LED 心跳与事件闪烁都从帧计数派生
    input  wire        I_frame_strobe,

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
    output reg  [3:0]  O_recog_algo,
    output reg  [3:0]  O_edge_th_sel,
    output wire [10:0] O_edge_th,
    output reg  [15:0] O_teach_cnt,
    output reg  [15:0] O_param_wr_cnt,
    output reg  [15:0] O_mode_commit_cnt,
    output reg  [7:0]  O_key4_evt,
    output reg         O_teach_req,
    output wire [15:0] O_mode_word,
    output wire [3:0]  O_led,

    // ---- B 段（0x80~0xBF）写转发 / 读回（M4a 接通，C 集成）------------------
    output wire        O_b_we,
    output wire [5:0]  O_b_addr,
    output wire [15:0] O_b_wdata,
    input  wire [15:0] I_b_rd_data
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

    // 0 -> 切水果 -> 接果篮 -> 退出。game_mode 不再是布尔量。
    wire [3:0] S_key4_game_next =
        (O_game_mode == 4'd0) ? 4'd1 :
        (O_game_mode == 4'd1) ? 4'd2 : 4'd0;

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
        else if(I_key4_short) begin              // 切水果 / 接果篮 / 退出
            S_addr  = 8'h01;
            S_wdata = {12'b0, S_key4_game_next};
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

    // ---- B 段写转发（与寄存器写同拍、同仲裁结果）---------------------------
    wire S_b_sel = (S_addr[7:6] == 2'b10);      // 0x80~0xBF
    assign O_b_we    = S_we & S_b_sel;
    assign O_b_addr  = S_addr[5:0];
    assign O_b_wdata = S_wdata;

    // ---- 寄存器写入 ---------------------------------------------------------
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            O_display_mode    <= 4'd0;
            O_game_mode       <= 4'd0;
            O_recog_algo      <= 4'd0;
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
                    8'h08: begin
                        O_recog_algo   <= S_wdata[3:0];
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

                // B 段写（转发给 game_param）也计一次，便于串口确认落地
                if(S_b_sel)
                    O_param_wr_cnt <= O_param_wr_cnt + 1'b1;
            end

            // KEY4 短按：进 game_mode 用干净游戏视图（6：识别继续、掩码/准星不叠加），
            // 退出就停识别（0，省功耗）。视图 1 仍保留为串口掩码调试视图。
            // 同一拍 UART 显式写 0x08 时不覆盖——UART 优先级最高。
            if(I_key4_short && !(I_ext_we && (I_ext_addr == 8'h08)))
                O_recog_algo <= (S_key4_game_next != 4'd0) ? 4'd6 : 4'd0;

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
    assign O_mode_word = {4'h00, O_recog_algo, O_game_mode, O_display_mode};   // 请求侧快照；DBG 的 K 用已提交值

    // ---- 板载 4 个独立 LED ---------------------------------------------------
    // {KEY4 事件闪 ~0.33 s, 心跳 ~0.9 Hz, game_mode 指示, display_mode 指示}
    // 从显示帧计数派生（60 Hz）：位 5 每 32 帧翻转一次 ≈ 0.53 s，闪烁数 20 帧 ≈ 0.33 s。
    reg [9:0] S_frame_cnt;
    reg [4:0] S_flash_frames;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_frame_cnt    <= 10'd0;
            S_flash_frames <= 5'd0;
        end
        else begin
            if(I_frame_strobe)
                S_frame_cnt <= S_frame_cnt + 1'b1;

            if(I_key4_short | I_key4_long)
                S_flash_frames <= 5'd20;
            else if(I_frame_strobe && (S_flash_frames != 5'd0))
                S_flash_frames <= S_flash_frames - 1'b1;
        end
    end

    assign O_led = { (S_flash_frames != 5'd0), S_frame_cnt[5],
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
            8'h08:   O_rd_data = {12'b0, O_recog_algo};
            default: O_rd_data = (I_rd_addr[7:6] == 2'b10) ? I_b_rd_data : 16'hFFFF;
        endcase
    end

endmodule
