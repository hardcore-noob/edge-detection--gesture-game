// ============================================================================
// mode_sync —— 模式寄存器到 CSI 域的"帧首提交"桥（像素域 ↔ CSI 域）
//
// 为什么要它：alg mux 与边缘门限都在 CSI 域决定写入 DDR 的像素，而按键/参数在
// 像素域。如果让模式在任意时刻生效，正在写的那一帧会被切成两种算法（README 第 5
// 节记的"切换瞬间可能出现短暂撕裂"）。本模块把新值先送到 CSI 域挂起，等下一个
// **相机帧首**（I_frame_start = ISP 输出的 tuser）再提交，于是写入 DDR 的每一帧
// 都是单一模式。
//
// 结构：两条 ctrl_sync（下行请求、上行回执）——同一套跨域手法，不新增机制。
//
// **提交字布局（26 位，消费侧必须按这个取位）**：I_req_data / O_committed 都是
//     bit[3:0]   edge_th_sel[3:0]   TH = 16 + 4×档位
//     bit[7:4]   display_mode[3:0]  算法位 = bit4（0=RAW / 1=EDGE）
//     bit[11:8]  game_mode[3:0]     0 = 游戏层关
//     bit[15:12] recog_algo[3:0]    0 = 识别停 / 1 = 手势识别（M1 消费）
//     bit[19:16] teach_cnt[3:0]     示教请求计数低位：**值变了 = 有新请求**（事件语义）
//     bit[25:20] 保留 0
//   ⚠ bit[7:4] / bit[3:0] 两个字段位置**保持 M0 原样不动**——2026-09-14 踩过位序取反
//     （顶层按 bit0 取算法、bit7:4 取档位，结果"字样变了、画面不切"）。
//
// 哪些寄存器要跨到 CSI 域（2026-09-17 定的判据）：
//   * **算法类**（display_mode / recog_algo / game_mode）→ 走本提交字，相机帧首生效，
//     避免把一帧切成两种算法；
//   * **系数类**（肤色上下限 / 运动阈值 / quiet_th）→ **不跨**：由 CSI 域自己的示教逻辑
//     用 min/max 包络产生并保存；A 段 0x40~0x7F 只保留"读回来复盘"的语义。
// 2026-09-14 踩过坑：顶层一开始按 bit0 取算法位、按 bit7:4 取档位，正好把两个字
// 段取反了——现象是 OSD 字样变了（用的是像素域的请求值）而画面不切（alg mux 拿到的
// 是恒 0 的门限最低位）。见 CHANGELOG《手势游戏 M0》阶段 4。
//
// 延迟：请求侧发现变化 1 拍 + 跨域 2~3 拍 + 等帧首（≤16.7 ms）+ 回执 2~3 拍。
// 时钟域：跨域模块。请在 SDC 里给这两个时钟对加 set_max_delay -datapath_only。
// 资源：两个 ctrl_sync，约 60 FF + 60 LUT。
// ============================================================================
module mode_sync (
    // 请求侧（像素域）
    input  wire       I_req_clk,
    input  wire       I_req_rst_n,
    input  wire [25:0] I_req_data,    // 26 位提交字，布局见文件头
    output wire [25:0] O_echo_data,   // 已完成提交的值（像素域）
    output wire       O_echo_valid,   // 提交完成 1 拍脉冲（像素域）

    // 提交侧（CSI 域）
    input  wire       I_ack_clk,
    input  wire       I_ack_rst_n,
    input  wire       I_frame_start,  // 相机帧首（ISP 输出 tuser）
    output reg  [25:0] O_committed,   // 已提交值（CSI 域）
    output reg        O_commit_pulse  // 提交 1 拍脉冲（CSI 域）
);

    // ---- 下行：请求侧每次发现值变了就发一次 --------------------------------
    reg [25:0] S_sent;
    wire      S_fwd_valid = (I_req_data != S_sent);

    always @(posedge I_req_clk or negedge I_req_rst_n) begin
        if(!I_req_rst_n)          S_sent <= 26'd0;
        else if(S_fwd_valid)      S_sent <= I_req_data;
    end

    wire [25:0] S_fwd_data;
    wire        S_fwd_rx_valid;

    ctrl_sync u_fwd (
        .I_tx_clk  (I_req_clk),
        .I_tx_rst_n(I_req_rst_n),
        .I_tx_valid(S_fwd_valid),
        .I_tx_data (I_req_data),
        .I_rx_clk  (I_ack_clk),
        .I_rx_rst_n(I_ack_rst_n),
        .O_rx_data (S_fwd_data),
        .O_rx_valid(S_fwd_rx_valid)
    );

    // ---- 提交侧：挂起到帧首再生效 ------------------------------------------
    reg [25:0] S_pending;
    reg       S_pending_flag;

    // 提交那一拍：数据用 S_pending（组合给出，与 valid 同拍稳定），
    // 同时把 O_committed 更新成同一个值。
    wire       S_ack_tx_valid = I_frame_start & S_pending_flag;
    wire [25:0] S_ack_word    = S_pending;

    always @(posedge I_ack_clk or negedge I_ack_rst_n) begin
        if(!I_ack_rst_n) begin
            S_pending      <= 26'd0;
            S_pending_flag <= 1'b0;
            O_committed    <= 26'd0;
            O_commit_pulse <= 1'b0;
        end
        else begin
            O_commit_pulse <= 1'b0;

            if(S_fwd_rx_valid) begin
                S_pending      <= S_fwd_data;
                S_pending_flag <= 1'b1;
            end

            if(S_ack_tx_valid) begin
                O_committed    <= S_pending;
                O_commit_pulse <= 1'b1;
                S_pending_flag <= 1'b0;
            end
        end
    end

    // ---- 上行：把提交结果回送（像素域）-------------------------------------
    wire [25:0] S_echo_data;

    ctrl_sync u_echo (
        .I_tx_clk  (I_ack_clk),
        .I_tx_rst_n(I_ack_rst_n),
        .I_tx_valid(S_ack_tx_valid),
        .I_tx_data (S_ack_word),
        .I_rx_clk  (I_req_clk),
        .I_rx_rst_n(I_req_rst_n),
        .O_rx_data (S_echo_data),
        .O_rx_valid(O_echo_valid)
    );

    assign O_echo_data = S_echo_data;

endmodule
