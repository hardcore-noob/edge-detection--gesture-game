// ============================================================================
// recog_top —— 识别支路容器（VIDEO_TAP 插座的消费者，CSI 域）
//
// 取点位置：isp_top 内部、RAW/EDGE MUX **之前**——RAW 是 AWB 输出的彩色流，
// EDGE 是 edge_detect_96 的梯度流。EDGE 模式下彩色流依然存在，所以肤色/运动
// 掩码两种模式都能用（这是把取点放在 MUX 之前的原因）。
//
// M0 内容（只有地基，没有识别算法）：
//   * tap 监视：数每一帧的 tap 字数（像素数 = 字数×4），帧首锁存成 >>10 的输出，
//     1280x720 期望 0x0384 —— 用来证明抽头接的是完整的一帧；
//   * 掩码统计：掩码源先固定为"边缘非零"（M1 再接肤色/运动/融合），实例化
//     mask_stats，输出像素数 >>4 与包围盒（16 像素粒度）；
//   * CTRL_SYNC 上行端点：M0 把收到的下行字原样回传（往返自检），M1 换成真实
//     识别结果（质心/手型/事件）。
//
// M1 Step 1 内容（2026-09-20，肤色掩码）：
//   * 在 tap 点取 RAW（AWB 彩色流）重算一份 Y = R/4+G/2+B/4（不动已验证的
//     edge_win_3x3_96），逐像素做 (B−Y)/(R−Y) 双区间判定 → 4 bit 肤色掩码；
//   * 掩码源用编译期参数 MASK_SRC 选：2 = 融合（肤色 ∩ 运动，Step 2 默认）、
//     1 = 只看肤色、0 = M0 的"边缘非零"自检源（回归用）。源选在综合时是常量，
//     不生成 mux，也**不生成用不到的那条支路**（运动支路在 generate 里）；
//   * 接的还是同一个 mask_stats，所以 DBG 的 P/Q/R 直接变成肤色像素数与包围盒，
//     不需要 C 加新字段；
//   * 阈值是模块参数（D1_*/D2_*，见下面注释），现场标定改这里 —— 在线调参要等 C
//     把 A 段 0x40~0x7F 的寄存器经一条 ctrl_sync 送进 CSI 域（A 的待提需求）。
//
// M1 Step 2 内容（2026-09-20，运动掩码 + 融合）：
//   * 背景帧 80x45：块 = 16x16 像素（x[10:4], y[9:4]），每块一个 8 bit 灰度参考值，
//     线性地址 = y[9:4]*80 + x[10:4]，共 3600 块 → 2 块 ERAM（eram_spram 2048x8 x2）；
//   * 运动掩码 = |当前像素灰度 − 本块背景灰度| > MOTION_TH，与肤色掩码按位与出融合掩码；
//   * 背景更新 = quiet 门控 + 限速蠕变：只有 |样本 − 背景| < QUIET_TH（且 QUIET_TH <
//     MOTION_TH，形成滞回）的块才动，且每块每 2^6=64 帧最多动 1 个 LSB；
//   * **上电自举**：复位后前 BOOT_FRAMES 帧把每块直接装载成样本值（否则背景全是 0，
//     运动掩码会恒 1、融合退化成纯肤色）。规划里的"KEY4 长按手动采样"要等 C 把
//     teach_req 送进 CSI 域，见 Step 4；在那之前**开机时画面里别放手**。
//
// 几何提醒：肤色源用的是 RAW 的字几何（字内 [95:72] 是最左像素），而 mask_stats
// 的列号按"列 4k-1..4k+2"（边缘流那套，边缘图整体比 RAW 左移 1 像素）算，所以
// 肤色掩码的列号整体偏左 1 像素 —— Q 是 16 像素粒度，看不出来；M2 做指尖坐标
// 对齐时按任务清单 §4 处理。
//
// 延迟：肤色判定与统计都是 0 拍组合计入（纯组合掩码 + 帧锁存输出），锁存发生在
//       所选用掩码源的 tuser 上；运动掩码同样是 0 拍组合（背景值在每块开始时就已经
//       预取到手，见下），所以融合掩码相对像素流不产生额外延迟；CTRL_SYNC 回传是
//       组合直连。
// 时钟域：CSI 域单时钟，不跨域（到像素域的同步在 design_top_wrapper 里做）。
// 资源：M0 地基约 150 FF + 100 LUT；肤色判定 ≈150~250 LUT6（4 像素并行，每像素
//       3 个移位加法 + 2 个 9 位减法 + 4 个比较）；运动支路 2 块 ERAM +
//       ≈60 FF + ≈150~250 LUT6（4 路 9 位减法/比较 + 块地址 + 更新控制）。0 DSP。
// ============================================================================
module recog_top #(
    // ---- M1 Step 1 / Step 2：掩码源与阈值 ------------------------------------
    // 掩码源：0 = 边缘非零自检源（M0 行为，回归用）；1 = 肤色掩码；
    //         2 = 融合掩码（肤色 ∩ 运动，Step 2 默认）。
    parameter integer MASK_SRC = 2,

    // 肤色区间（9 位有符号，范围 −255..255）。**按 Y = R/4+G/2+B/4 标定，不要抄
    // 教科书的 Cb/Cr 数值**：第一版按《Step 1 开工包》取**偏宽**的区间，只作为上板
    // 标定的起点、不是结论（教科书 Cb∈[77,127] / Cr∈[133,173] 换算过来是
    // d1∈[−90,−2] / d2∈[7,63]，比这组窄）。
    parameter signed [8:0] D1_MIN = -9'sd100,   // d1 = B−Y 下限
    parameter signed [8:0] D1_MAX =  -9'sd5,    // d1 = B−Y 上限
    parameter signed [8:0] D2_MIN =   9'sd0,    // d2 = R−Y 下限
    parameter signed [8:0] D2_MAX =  9'sd70,    // d2 = R−Y 上限

    // 运动阈值：|当前灰度 − 背景灰度| 大于它才算"这个像素在动"。
    parameter signed [8:0] MOTION_TH = 9'sd8,
    // quiet 阈值：块背景允许蠕变的"死区"，必须 < MOTION_TH（滞回）：
    // 样本与背景差得少才认为这块是静背景、可以慢慢跟；差得多说明有前景，不许动。
    parameter signed [8:0] QUIET_TH  = 9'sd4,
    // 块内用哪一行做背景采样（16 行里的第几行，取中间行）。
    parameter [3:0] BG_SAMPLE_ROW = 4'd7,
    // 上电自举帧数：这几帧里每块无条件装载样本值（之后转为 quiet 蠕变）。
    // 取 32（≈0.5 s）是故意留出 AWB 收敛时间——AWB 是自适应的，开机头几帧的颜色
    // 还没稳，拿那时的灰度当背景会得到一个整体偏色的参考值，而 quiet 门控又不会
    // 自己爬回来，现象就是"开机后满屏都在动"。最后一次写入生效，所以窗口越长越稳。
    parameter [5:0] BOOT_FRAMES = 6'd32,

    // ---- M1 Step 3：ROI 门控 / α-β 平滑 / 丢失保持 ---------------------------
    // 命中阈值：一帧的掩码像素数低于它就当作"没看到目标"（2000 px ≈ 45x45）。
    parameter [19:0] MIN_CNT = 20'd2000,
    // ROI 外扩余量（像素）：锁定后只在"上一帧包围盒 ± 这个余量"内统计，
    // 窗口外的干扰被物理隔离。
    // ROI 余量：手快速移动时也要留在窗口里（太小会"滑出窗口 → 判丢失 → 准星停住"）。
    parameter [10:0] ROI_MARGIN = 11'd160,
    // 连续几帧命中才认为重新锁定（验收：回画 3 帧内重锁）。
    parameter [3:0]  LOCK_FRAMES = 4'd3,
    // 连续几帧打不中才认为丢失（验收：出画 5 帧内丢失）。
    parameter [3:0]  HOLD_FRAMES = 4'd5,
    // ---- Step 4 调优：准星尺寸 / 目标形状门控 -------------------------------
    parameter [10:0] CROSS_LEN = 11'd10,   // 准星半臂长（像素）
    parameter [10:0] CROSS_TH  = 11'd1,    // 准星线宽（±CROSS_TH，即 3 像素宽）
    // 目标门控：包围盒太小的（唇膏、指尖、噪声）和太细长的（笔、杆）不算有效目标。
    parameter [10:0] MIN_W     = 11'd60,   // 最小宽度（像素）
    parameter [10:0] MIN_H     = 11'd60,   // 最小高度（像素）
    // 长宽比判据固定按 3 倍（×3 用移位加法实现，**不能用乘法器**——A 线 DSP 配额是 0）
    // α-β 滤波移位量：α = 1/2^ALPHA_SHIFT（位置修正）、β = 1/2^BETA_SHIFT（速度项）。
    // α-β 移位量调小 = 跟得更快（原来 α=1/4、β=1/16 有明显滞后）。
    parameter integer ALPHA_SHIFT = 1,
    parameter integer BETA_SHIFT  = 3,
    // 准星锚点：必须落在**包围盒中心**（用户 2026-09-23 明确要求）。
    // 曾试过 1 = 用包围盒上缘（想贴指尖），结果准星跑到框的顶边、看着像错位，已改回 0。
    // 真正的"指尖优先"要靠 M2 的每列轮廓扫描，不能用"取上缘"这种近似。
    parameter integer TRACK_Y_FROM_TOP = 0
)(
    input  wire        I_clk,
    input  wire        I_rst_n,

    // VIDEO_TAP：与 MUX 之前的流严格对齐
    input  wire [95:0] I_raw_tdata,
    input  wire        I_raw_tuser,
    input  wire        I_raw_tlast,
    input  wire        I_raw_tvalid,
    input  wire [95:0] I_edge_tdata,
    input  wire        I_edge_tuser,
    input  wire        I_edge_tlast,
    input  wire        I_edge_tvalid,

    // CTRL_SYNC（CSI 侧端点）：下行收到的字 + 上行要发的字
    input  wire [25:0] I_ctrl_rx_data,
    input  wire        I_ctrl_rx_valid,
    output wire [25:0] O_ctrl_tx_data,
    output wire        O_ctrl_tx_valid,

    // 观测输出（帧锁存，供 DBG 行；到像素域由顶层用 toggle+整包捕获同步）
    // 位宽按实际取值范围给足（不做成固定 16 位）：跨域线少一根就少一份走线压力。
    output wire [11:0] O_tap_px_shift,    // 每帧 tap 像素数 >>10（1280x720 应为 900 = 0x384）
    output wire [15:0] O_mask_cnt_shift,  // 掩码像素数 >>4
    output wire [13:0] O_bbox_x,          // {x_min/16[6:0], x_max/16[6:0]}（x/16 ≤ 79）
    output wire [11:0] O_bbox_y,          // {y_min/16[5:0], y_max/16[5:0]}（y/16 ≤ 44）
    // 帧锁存值更新时翻转一次（用边沿流帧首），像素域据此"整包捕获"。
    // 数据在 toggle 之前就已经锁存稳定，所以不存在逐位同步的混采问题。
    output reg         O_status_toggle,

    // 实时掩码（每拍 4 bit，bit0 = 字内最左像素 [95:72]）：**只给调试图用**
    // （isp_top 的 MASK_PREVIEW 把它涂红叠在 RAW 画面上看效果），统计/跨域都不用它。
    // 与 I_raw_tdata 严格同拍。
    output wire [3:0]  O_mask_px,

    // Step 3 跟踪结果 + 叠加选择：目前只有 isp_top 的 MASK_PREVIEW 调试图消费，
    // 正规交付路径（MASK_PREVIEW=0）里整段会被综合消掉，画面不受任何影响。
    output wire [10:0] O_track_x,        // α-β 平滑后的准星列（0..1279）
    output wire [9:0]  O_track_y,        // 平滑后的准星行（0..719）
    output wire        O_track_locked,   // 已锁定（连续命中 ≥ LOCK_FRAMES）
    output wire [7:0]  O_ovl_sel         // 每像素 2 bit：0=原像素 1=掩码(红) 2=准星(黄)
);

    // ---- tap 监视：每帧字数 -------------------------------------------------
    reg [19:0] S_tap_cnt;
    reg [15:0] S_tap_hold;

    // **帧首必须与 I_tvalid 解耦**（2026-09-15 上板踩到）：awb.v 里 `assign O_tuser = I_tuser`
    // 是**不带延迟直通**的（而 valid 是流水后的，中间还有行间空隙——同文件里
    // `O_tlast = (valid_d1==0)&&(valid_d2==1)` 就是靠 valid 的空隙检测出每个行首的）。
    // 所以 tuser 脉冲可能落在 valid=0 的拍上：如果把它闸在 valid 里，脉冲会被整帧吞掉，
    // 计数与锁存永远不会发生（现象就是 U/P/Q/R 四个观测字段恒 0，而 X/Y 这种走 ctrl_sync
    // 的通路照常正常）。
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_tap_cnt  <= 20'd0;
            S_tap_hold <= 16'd0;
        end
        else begin
            if(I_raw_tvalid && (S_tap_cnt != 20'hFFFFF))
                S_tap_cnt <= S_tap_cnt + 1'b1;

            if(I_raw_tuser) begin
                // 帧首：锁存上一帧的字数。像素数 = 字数×4，所以
                // "像素数 >> 10" 就是 "字数 >> 8"（1280x720 → 230400 >> 8 = 900）。
                S_tap_hold <= S_tap_cnt >> 8;
                S_tap_cnt  <= 20'd0;
            end
        end
    end

    assign O_tap_px_shift = S_tap_hold;

    // ---- 行内字号 / 行号（ROI 门控、运动块地址、准星叠加共用）-----------------
    // 几何与 mask_stats 完全一致：按 valid 走、行尾 319 回卷、帧首归零。
    reg [10:0] S_x_grp;
    reg [9:0]  S_y_pos;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_x_grp <= 11'd0;
            S_y_pos <= 10'd0;
        end
        else begin
            // 帧首归零，**不闸 valid**（tuser 常落在 valid=0 的拍上，见上面 tap 段注释）
            if(I_raw_tuser) begin
                S_x_grp <= 11'd0;
                S_y_pos <= 10'd0;
            end
            if(I_raw_tvalid) begin
                if(I_raw_tuser)
                    S_x_grp <= 11'd1;       // 与 mask_stats 对齐：帧首那一拍算第 0 组
                else if(S_x_grp == 11'd319) begin
                    S_x_grp <= 11'd0;
                    S_y_pos <= (S_y_pos == 10'd719) ? 10'd0 : (S_y_pos + 10'd1);
                end
                else
                    S_x_grp <= S_x_grp + 11'd1;
            end
        end
    end

    // ---- 掩码源 0：边缘非零自检（M0 行为，MASK_SRC=0 时的回归源）--------------
    // bit0 对应列 4k-1，也就是 96 位字的最高字段（out0），与 edge_detect_96 的
    // 输出几何一致。
    wire [3:0] S_edge_mask = {|I_edge_tdata[95:72], |I_edge_tdata[71:48],
                              |I_edge_tdata[47:24], |I_edge_tdata[23:0]};

    // ---- 掩码源 1：肤色掩码（M1 Step 1）-------------------------------------
    // 逐像素 (B−Y)/(R−Y) 双区间判定。Y 用与 edge_win_3x3_96 逐位相同的公式
    // （R/4+G/2+B/4，最大 253），在这里重算一份，不动已验证的边缘模块。
    // 由 Cb = 0.564(B−Y)+128、Cr = 0.713(R−Y)+128 可知它与 Cb/Cr 双区间完全等价，
    // 但只剩移位/加减/比较：0 DSP（不做 3x3 矩阵乘法——那是 36 乘/拍）。
    // 这份 Y 同时给 Step 2 的运动掩码用（同一个灰度定义，两边共用一份）。
    wire [23:0] S_raw_pix0 = I_raw_tdata[95:72];   // 字内最左像素
    wire [23:0] S_raw_pix1 = I_raw_tdata[71:48];
    wire [23:0] S_raw_pix2 = I_raw_tdata[47:24];
    wire [23:0] S_raw_pix3 = I_raw_tdata[23:0];

    wire [7:0] S_gray0 = {2'b0, S_raw_pix0[23:18]} + {1'b0, S_raw_pix0[15:9]} + {2'b0, S_raw_pix0[7:2]};
    wire [7:0] S_gray1 = {2'b0, S_raw_pix1[23:18]} + {1'b0, S_raw_pix1[15:9]} + {2'b0, S_raw_pix1[7:2]};
    wire [7:0] S_gray2 = {2'b0, S_raw_pix2[23:18]} + {1'b0, S_raw_pix2[15:9]} + {2'b0, S_raw_pix2[7:2]};
    wire [7:0] S_gray3 = {2'b0, S_raw_pix3[23:18]} + {1'b0, S_raw_pix3[15:9]} + {2'b0, S_raw_pix3[7:2]};

    function F_skin_px;
        input [7:0] I_r, I_b, I_y;       // R、B 与已经算好的灰度 Y
        reg signed [8:0] S_d1, S_d2;
        begin
            S_d1 = {1'b0, I_b} - {1'b0, I_y};      // d1 = B − Y
            S_d2 = {1'b0, I_r} - {1'b0, I_y};      // d2 = R − Y
            F_skin_px = (S_d1 >= D1_MIN) && (S_d1 <= D1_MAX) &&
                        (S_d2 >= D2_MIN) && (S_d2 <= D2_MAX);
        end
    endfunction

    // 掩码 bit 序与 S_edge_mask 一致：bit0 = 字内最左像素 [95:72]。
    wire [3:0] S_skin_mask = {F_skin_px(S_raw_pix3[23:16], S_raw_pix3[7:0], S_gray3),
                              F_skin_px(S_raw_pix2[23:16], S_raw_pix2[7:0], S_gray2),
                              F_skin_px(S_raw_pix1[23:16], S_raw_pix1[7:0], S_gray1),
                              F_skin_px(S_raw_pix0[23:16], S_raw_pix0[7:0], S_gray0)};

    // ========================================================================
    // M1 Step 2：背景帧（80x45 灰度）+ 运动掩码 → 融合掩码 = 肤色 ∩ 运动
    //
    // 为什么要背景差分而不是帧间差分：帧间差分只能发现"这一帧和上一帧不一样"，
    // 手停住就不动了；背景差分是"和背景不一样"，静止的手照样是前景。前提是背景
    // 更新必须带 quiet 门控（见下），否则静止的手会慢慢被吸进背景。
    //
    // 几何：块 = 16x16 像素，80x45 = 3600 块，每块 1 字节灰度参考值。
    //   块列 = x[10:4] = 行内字号 >> 2（一拍 4 像素不跨 16 像素边界），
    //   块行 = y[9:4]，地址 = 块行*80 + 块列（80 = 64+16，纯移位加法）；
    //   → 每块每行只读一次背景，同一块内 4 拍的像素共用这个值。
    //
    // 采样（背景更新的依据）：块内第 BG_SAMPLE_ROW 行的**前 8 个像素**的均值
    //   （2 拍 × 4 像素，>>3）。在 phase==1 算完、phase==2 写回。不用整块 256 像素
    //   均值的原因：那要么给 80 个块各配一个 12 位部分和（≈960 FF），要么再开一块
    //   ERAM 当暂存；而背景值只是"参考"，8 像素均值已经能压掉单像素噪声。
    //
    // ERAM 读写时序（eram_spram = 单口 + 1 拍读延迟，同一拍不能既读又写）：
    //   phase 0/1：地址 = 本块，读（phase==0 直接用读出的数据，phase 1~3 用寄存副本）
    //   phase 2  ：地址 = 本块，we = 更新决策（这一拍是"只写"）
    //   phase 3  ：地址 = **下一块**（地址预取），读 → 数据正好在下一块 phase==0 有效
    //   所以 4 拍里读/写各占各的槽，既没有冲突也不需要场消隐期的额外地址生成器。
    //   行尾（块列 79）的下一块是本块行第 0 列（下一行的同一个块行），地址要回卷。
    //
    // 背景更新（quiet 门控 + 限速蠕变，规划 §3 M1）：
    //   * |样本 − 背景| < QUIET_TH 才允许动（QUIET_TH < MOTION_TH 形成滞回）；
    //   * 每块每 64 帧最多动 1 个 LSB（"帧计数低位 == 块地址低位"挑帧，3600 块里
    //     每帧约 56 块有更新机会）；60 fps 下等效时间常数几十秒；
    //   * 复位后前 BOOT_FRAMES 帧例外：每块无条件装载样本值（自举），否则背景全是
    //     0，运动掩码恒 1、融合退化成纯肤色。**开机时画面里别放手**。
    //
    // 延迟：0 拍（背景值在每块第一拍就已经拿到，与像素同拍比较）。跨域：不跨。
    //       SDC：不需要额外约束（ERAM 与像素流同一时钟域）。
    // 资源：2 块 ERAM + ≈60 FF + ≈150~250 LUT6，0 DSP。
    // ========================================================================
    wire [3:0] S_motion_mask;

    generate
    if (MASK_SRC == 2) begin : g_motion

        // 行内字号 S_x_grp / 行号 S_y_pos 现在在模块顶部统一维护（ROI/准星也要用）
        wire [1:0] S_phase = S_x_grp[1:0];          // 块内第几拍（0..3）
        wire [6:0] S_blk_x = S_x_grp[6:2];          // 行内块列 0..79
        wire [5:0] S_band  = S_y_pos[9:4];          // 块行 0..44
        wire       S_sample_row = (S_y_pos[3:0] == BG_SAMPLE_ROW);

        wire [11:0] S_row_base  = {S_band, 6'b0} + {S_band, 4'b0};   // 块行*80
        wire [11:0] S_addr_cur  = S_row_base + {{5{1'b0}}, S_blk_x};
        wire [11:0] S_addr_next = (S_blk_x == 7'd79) ? S_row_base : (S_addr_cur + 12'd1);

        // ---- 背景帧存储：2 块 ERAM（各 2048x8，够放 3600 个块）------------------
        // 单口 + 1 拍读延迟：地址在上一块 phase==3 发出（预取）→ 本块 phase==0 有效。
        // 地址 bit11 选片子；读出数据的片选要用**上一拍**的地址位，所以打一拍。
        wire [11:0] S_bg_addr;
        wire        S_bg_we;
        wire [7:0]  S_bg_wdata;
        reg  [11:0] S_bg_addr_d1;
        wire [7:0]  S_bg_q0, S_bg_q1;
        wire [7:0]  S_bg_rdata = S_bg_addr_d1[11] ? S_bg_q1 : S_bg_q0;

        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n) S_bg_addr_d1 <= 12'd0;
            else         S_bg_addr_d1 <= S_bg_addr;
        end

        eram_spram #(.DATA_WIDTH(8), .ADDR_WIDTH(11)) u_bg_mem0 (
            .I_clk  (I_clk),
            .I_we   (S_bg_we & ~S_bg_addr[11]),
            .I_addr (S_bg_addr[10:0]),
            .I_wdata(S_bg_wdata),
            .O_rdata(S_bg_q0)
        );

        eram_spram #(.DATA_WIDTH(8), .ADDR_WIDTH(11)) u_bg_mem1 (
            .I_clk  (I_clk),
            .I_we   (S_bg_we &  S_bg_addr[11]),
            .I_addr (S_bg_addr[10:0]),
            .I_wdata(S_bg_wdata),
            .O_rdata(S_bg_q1)
        );

        // ---- 帧计数：只用来"挑帧"（每块每 64 帧一次更新机会）-------------------
        reg [5:0] S_frame_cnt;
        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n)         S_frame_cnt <= 6'd0;
            else if(I_raw_tuser) S_frame_cnt <= S_frame_cnt + 6'd1;
        end
        wire S_boot = (S_frame_cnt < BOOT_FRAMES);

        // ---- 采样：本块采样行的前 8 像素均值 ----------------------------------
        wire [9:0] S_sum4 = {2'b0, S_gray0} + {2'b0, S_gray1} +
                            {2'b0, S_gray2} + {2'b0, S_gray3};
        reg [9:0] S_row_acc;
        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n)          S_row_acc <= 10'd0;
            else if(I_raw_tvalid) S_row_acc <= (S_phase == 2'd0) ? S_sum4
                                                                 : (S_row_acc + S_sum4);
        end
        // phase==1 时 S_row_acc 已经是第 0 拍的和，加上当拍就是 8 像素和 → >>3 取均值
        wire [10:0] S_sum8   = {1'b0, S_row_acc} + {1'b0, S_sum4};
        wire [7:0]  S_sample = S_sum8[10:3];

        // ---- 背景读数据：phase==0 用直通（预取刚回来），其余用寄存副本 ----------
        reg [7:0] S_bg_reg;
        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n) S_bg_reg <= 8'd0;
            // phase==3 那拍数据来自"phase==2 的写访问"，对单口 RAM 没有意义，不能收
            else if(I_raw_tvalid && (S_phase != 2'd3)) S_bg_reg <= S_bg_rdata;
        end
        wire [7:0] S_bg_use = (S_phase == 2'd0) ? S_bg_rdata : S_bg_reg;

        // ---- 更新决策：自举装载 / quiet 蠕变 ---------------------------------
        wire signed [8:0] S_bg_diff = {1'b0, S_sample} - {1'b0, S_bg_use};
        wire S_quiet = (S_bg_diff > -QUIET_TH) && (S_bg_diff < QUIET_TH);
        wire S_turn  = (S_frame_cnt == S_addr_cur[5:0]);
        wire S_upd   = (S_phase == 2'd1) && S_sample_row &&
                       (S_boot ? 1'b1
                               : (S_turn && S_quiet && (S_bg_diff != 9'sd0)));
        wire [7:0] S_new = S_boot ? S_sample
                                  : (S_bg_diff[8] ? ((S_bg_use == 8'd0) ? 8'd0
                                                                        : (S_bg_use - 8'd1))
                                                  : (S_bg_use + 8'd1));

        // 决策在 phase==1 产生、写发生在 phase==2，所以打一拍
        reg       S_upd_d1;
        reg [7:0] S_new_d1;
        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n) begin
                S_upd_d1 <= 1'b0;
                S_new_d1 <= 8'd0;
            end
            else begin
                S_upd_d1 <= S_upd;
                S_new_d1 <= S_new;
            end
        end

        assign S_bg_addr  = (S_phase == 2'd3) ? S_addr_next : S_addr_cur;
        assign S_bg_we    = (S_phase == 2'd2) && S_upd_d1;
        assign S_bg_wdata = S_new_d1;

        // ---- 运动掩码：|灰度 − 背景| > MOTION_TH ------------------------------
        wire signed [8:0] S_m0 = {1'b0, S_gray0} - {1'b0, S_bg_use};
        wire signed [8:0] S_m1 = {1'b0, S_gray1} - {1'b0, S_bg_use};
        wire signed [8:0] S_m2 = {1'b0, S_gray2} - {1'b0, S_bg_use};
        wire signed [8:0] S_m3 = {1'b0, S_gray3} - {1'b0, S_bg_use};

        // bit0 = 字内最左像素，与肤色掩码同一 bit 序（否则融合会错位）
        assign S_motion_mask = { (S_m3 > MOTION_TH) || (S_m3 < -MOTION_TH),
                                 (S_m2 > MOTION_TH) || (S_m2 < -MOTION_TH),
                                 (S_m1 > MOTION_TH) || (S_m1 < -MOTION_TH),
                                 (S_m0 > MOTION_TH) || (S_m0 < -MOTION_TH) };

    end
    else begin : g_nomotion
        // 不建运动支路时（MASK_SRC = 0/1）：融合掩码退化成肤色掩码，且 0 资源开销
        assign S_motion_mask = 4'b1111;
    end
    endgenerate

    wire [3:0] S_fusion_mask = S_skin_mask & S_motion_mask;

    // ---- 掩码源选择（编译期常量 → 综合后没有 mux，也没有多余负载）------------
    wire [3:0] S_mask_sel = (MASK_SRC == 2) ? S_fusion_mask :
                            (MASK_SRC == 1) ? S_skin_mask   : S_edge_mask;

    // ---- mask_stats 的输出（Step 3 要用"上一帧"的包围盒/计数，先声明）---------
    wire [19:0] S_mcnt;
    wire [10:0] S_xmin, S_xmax, S_ymin, S_ymax;
    wire [30:0] S_sumx;
    wire [29:0] S_sumy;
    wire        S_empty;

    // ========================================================================
    // M1 Step 3：ROI 门控 + α-β 平滑 + 丢失保持 / 重锁
    //
    // 目标：把"每帧一张掩码"变成"一个稳定的准星"。
    //   * ROI 门控：锁定后只在上一帧包围盒 ±ROI_MARGIN 的窗口内统计（窗口外的干扰
    //     被物理隔离）；丢了又没锁定时回到全帧重搜。
    //   * α-β 滤波：位置一阶修正 α=1/2^ALPHA_SHIFT，速度项 β=1/2^BETA_SHIFT，
    //     跟手平滑不抖；全部用移位实现，**不做除法**。
    //   * 丢失保持：打不中就按速度外推，连续 HOLD_FRAMES 帧打不中才判丢失；
    //     重新看到目标要连续 LOCK_FRAMES 帧命中才重新锁定（防抖）。
    // 全部在相机帧首更新一次（60 Hz），CSI 域、不跨域。
    // 资源：≈120~180 LUT6 + ≈90 FF，0 ERAM / 0 DSP。
    // ========================================================================
    wire [3:0]  S_mask_gated;
    wire [10:0] S_trk_x;
    wire [9:0]  S_trk_y;
    wire        S_trk_locked;
    wire [7:0]  S_ovl_sel;

    generate
    if (MASK_SRC != 0) begin : g_track

        // 像素列：一拍 4 像素，bit0 对应最左像素 → 列 = 4*x_grp + j
        wire [10:0] S_col0 = {S_x_grp, 2'b00};
        wire [10:0] S_col1 = S_col0 + 11'd1;
        wire [10:0] S_col2 = S_col0 + 11'd2;
        wire [10:0] S_col3 = S_col0 + 11'd3;

        reg [10:0] S_roi_x0, S_roi_x1;
        reg [9:0]  S_roi_y0, S_roi_y1;

        function F_in_roi;
            input [10:0] I_x;
            input [9:0]  I_y;
            begin
                F_in_roi = (I_x >= S_roi_x0) && (I_x <= S_roi_x1) &&
                           (I_y >= S_roi_y0) && (I_y <= S_roi_y1);
            end
        endfunction

        // ---- 形态学去噪 ①a：水平 3 点开运算（腐蚀→膨胀）-----------------------
        // 开运算 = 先腐蚀再膨胀：先去掉孤立/毛刺像素，再把目标尺寸恢复回来。
        // 只用同一个 96 位字里的水平邻居（j-1 / j / j+1），所以**不引入任何拍延迟**、
        // 不破坏与像素和坐标的对齐、也不占 ERAM；列首/列尾没有外侧邻居时用自身近似。
        // 代价：宽度 ≤2 像素的细窄结构会被抹掉（对手部掩膜是有益的去噪）。
        wire [3:0] S_m_erode, S_m_open;
        assign S_m_erode[0] = S_mask_sel[0] &  S_mask_sel[1];
        assign S_m_erode[1] = S_mask_sel[1] &  S_mask_sel[0] & S_mask_sel[2];
        assign S_m_erode[2] = S_mask_sel[2] &  S_mask_sel[1] & S_mask_sel[3];
        assign S_m_erode[3] = S_mask_sel[3] &  S_mask_sel[2];
        assign S_m_open[0]  = S_m_erode[0]  |  S_m_erode[1];
        assign S_m_open[1]  = S_m_erode[1]  |  S_m_erode[0] | S_m_erode[2];
        assign S_m_open[2]  = S_m_erode[2]  |  S_m_erode[1] | S_m_erode[3];
        assign S_m_open[3]  = S_m_erode[3]  |  S_m_erode[2];

        // 喂给 mask_stats 的就是这个"开运算 + ROI 门控"后的掩码
        assign S_mask_gated = S_m_open &
                              { F_in_roi(S_col3, S_y_pos), F_in_roi(S_col2, S_y_pos),
                                F_in_roi(S_col1, S_y_pos), F_in_roi(S_col0, S_y_pos) };

        // ---- 帧首：命中/丢失计数、锁定状态机、α-β、ROI 窗口 ------------------
        reg               S_locked;
        reg [3:0]         S_hit_cnt, S_miss_cnt;
        reg signed [12:0] S_pos_x, S_pos_y;
        reg signed [12:0] S_vel_x, S_vel_y;

        wire [10:0] S_obs_x = (S_xmin + S_xmax) >> 1;   // 上一帧包围盒中心（观测值）
        // 纵向观测：默认取包围盒**上缘**（TRACK_Y_FROM_TOP=1）→ 准星贴指尖而不是手掌心
        wire [9:0]  S_obs_y = TRACK_Y_FROM_TOP ? S_ymin[9:0] : ((S_ymin + S_ymax) >> 1);
        // 目标门控：像素数够 + 包围盒够大 + 不细长（挡掉唇膏/笔/碎噪声这类非手目标）
        wire [10:0] S_w     = S_xmax - S_xmin;
        wire [10:0] S_h     = S_ymax - S_ymin;
        wire [11:0] S_h3 = (S_h << 1) + S_h;      // ×3（移位加法，避免 DSP）
        wire [11:0] S_w3 = (S_w << 1) + S_w;
        wire S_size_ok = (S_w >= MIN_W) && (S_h >= MIN_H) &&
                         (S_w <= S_h3) && (S_h <= S_w3);
        wire        S_hit   = (S_mcnt >= MIN_CNT) && S_size_ok;

        wire signed [12:0] S_err_x  = {2'b0, S_obs_x} - S_pos_x;
        wire signed [12:0] S_err_y  = {2'b0, S_obs_y} - S_pos_y;
        wire signed [12:0] S_pos_nx = S_pos_x + (S_err_x >>> ALPHA_SHIFT) + S_vel_x;
        wire signed [12:0] S_pos_ny = S_pos_y + (S_err_y >>> ALPHA_SHIFT) + S_vel_y;
        wire signed [12:0] S_vel_nx = S_vel_x + (S_err_x >>> BETA_SHIFT);
        wire signed [12:0] S_vel_ny = S_vel_y + (S_err_y >>> BETA_SHIFT);
        wire signed [12:0] S_pos_hx = S_pos_x + S_vel_x;   // 丢失时按速度外推
        wire signed [12:0] S_pos_hy = S_pos_y + S_vel_y;

        always @(posedge I_clk or negedge I_rst_n) begin
            if(!I_rst_n) begin
                S_roi_x0 <= 11'd0;    S_roi_x1 <= 11'd1279;
                S_roi_y0 <= 10'd0;    S_roi_y1 <= 10'd719;
                S_locked <= 1'b0;     S_hit_cnt <= 4'd0;  S_miss_cnt <= 4'd0;
                S_pos_x  <= 13'sd640; S_pos_y  <= 13'sd360;
                S_vel_x  <= 13'sd0;   S_vel_y  <= 13'sd0;
            end
            else if(I_raw_tuser) begin
                // (1) 命中/丢失计数与锁定状态
                if(S_hit) begin
                    S_miss_cnt <= 4'd0;
                    S_hit_cnt  <= (S_hit_cnt == 4'hF) ? 4'hF : (S_hit_cnt + 4'd1);
                    if(!S_locked && (S_hit_cnt >= LOCK_FRAMES)) S_locked <= 1'b1;
                end
                else begin
                    S_hit_cnt  <= 4'd0;
                    S_miss_cnt <= (S_miss_cnt == 4'hF) ? 4'hF : (S_miss_cnt + 4'd1);
                    if(S_locked && (S_miss_cnt >= HOLD_FRAMES)) S_locked <= 1'b0;
                end

                // (2) α-β 滤波：命中→按观测修正；丢失→按速度外推（最多几帧就判丢失）
                S_pos_x <= S_hit ? S_pos_nx : S_pos_hx;
                S_pos_y <= S_hit ? S_pos_ny : S_pos_hy;
                S_vel_x <= S_hit ? S_vel_nx : S_vel_x;
                S_vel_y <= S_hit ? S_vel_ny : S_vel_y;

                // (3) ROI 窗口：命中→按新包围盒外扩；丢失且未锁定→回全帧重搜
                if(S_hit) begin
                    S_roi_x0 <= (S_xmin > ROI_MARGIN) ? (S_xmin - ROI_MARGIN) : 11'd0;
                    S_roi_x1 <= (S_xmax > (11'd1279 - ROI_MARGIN)) ? 11'd1279
                                                                  : (S_xmax + ROI_MARGIN);
                    S_roi_y0 <= (S_ymin > ROI_MARGIN) ? (S_ymin[9:0] - ROI_MARGIN[9:0]) : 10'd0;
                    S_roi_y1 <= (S_ymax > (10'd719 - ROI_MARGIN[9:0])) ? 10'd719
                                                                       : (S_ymax + ROI_MARGIN[9:0]);
                end
                else if(!S_locked) begin
                    S_roi_x0 <= 11'd0;    S_roi_x1 <= 11'd1279;
                    S_roi_y0 <= 10'd0;    S_roi_y1 <= 10'd719;
                end
            end
        end

        // ---- 准星位置（钳到画面内，给调试图用）-------------------------------
        assign S_trk_x = (S_pos_x < 13'sd0)    ? 11'd0
                                               : ((S_pos_x > 13'sd1279) ? 11'd1279 : S_pos_x[10:0]);
        assign S_trk_y = (S_pos_y < 13'sd0)    ? 10'd0
                                               : ((S_pos_y > 13'sd719)  ? 10'd719  : S_pos_y[9:0]);
        assign S_trk_locked = S_locked;

        // ---- 调试图叠加选择：0=原像素 1=掩码(红) 2=准星(黄) 3=包围盒(绿) ------
        function [1:0] F_ovl;
            input [10:0] I_x;
            input [9:0]  I_y;
            input        I_mask;
            reg          S_in, S_on_x, S_on_y, S_th_x, S_th_y;
            begin
                S_in   = (I_x >= S_roi_x0) && (I_x <= S_roi_x1) &&
                         (I_y >= S_roi_y0) && (I_y <= S_roi_y1);
                // 臂长 ±CROSS_LEN、线宽 ±CROSS_TH（十字两个方向各一条粗线）
                S_on_x = (I_x + CROSS_LEN >= S_trk_x) && (I_x <= S_trk_x + CROSS_LEN);
                S_on_y = (I_y + CROSS_LEN >= S_trk_y) && (I_y <= S_trk_y + CROSS_LEN);
                S_th_x = (I_x + CROSS_TH  >= S_trk_x) && (I_x <= S_trk_x + CROSS_TH);
                S_th_y = (I_y + CROSS_TH  >= S_trk_y) && (I_y <= S_trk_y + CROSS_TH);
                if((S_on_x && S_th_y) || (S_on_y && S_th_x))
                    F_ovl = 2'd2;                       // 准星（黄）
                else if(I_mask)
                    F_ovl = 2'd1;                       // 掩码（红）
                else
                    F_ovl = 2'd0;
            end
        endfunction

        assign S_ovl_sel = { F_ovl(S_col3, S_y_pos, S_mask_gated[3]),
                             F_ovl(S_col2, S_y_pos, S_mask_gated[2]),
                             F_ovl(S_col1, S_y_pos, S_mask_gated[1]),
                             F_ovl(S_col0, S_y_pos, S_mask_gated[0]) };

    end
    else begin : g_notrack
        // MASK_SRC=0（边缘自检回归）时不要 ROI/平滑，保持 M0 的行为
        assign S_mask_gated = S_mask_sel;
        assign S_trk_x      = 11'd640;
        assign S_trk_y      = 10'd360;
        assign S_trk_locked = 1'b0;
        assign S_ovl_sel    = 8'd0;
    end
    endgenerate

    // ---- 掩码统计器的输入流选择 ---------------------------------------------
    wire       S_ms_valid = (MASK_SRC == 0) ? I_edge_tvalid : I_raw_tvalid;
    wire       S_ms_user  = (MASK_SRC == 0) ? I_edge_tuser  : I_raw_tuser;
    wire       S_ms_last  = (MASK_SRC == 0) ? I_edge_tlast  : I_raw_tlast;

    // 调试图出口：把"ROI 门控后的实时掩码"和 Step 3 的跟踪结果引出去
    // （不改统计、不跨域；只有 isp_top 的 MASK_PREVIEW 调试图会消费）
    assign O_mask_px      = S_mask_gated;
    assign O_track_x      = S_trk_x;
    assign O_track_y      = S_trk_y;
    assign O_track_locked = S_trk_locked;
    assign O_ovl_sel      = S_ovl_sel;

    // ---- 掩码统计器（M0 建好，M1 起换掩码源、M1 Step 3 起吃 ROI 门控后的掩码）---
    mask_stats u_mask_stats (
        .I_clk  (I_clk),
        .I_rst_n(I_rst_n),
        .I_mask (S_mask_gated),
        .I_valid(S_ms_valid),
        .I_user (S_ms_user),
        .I_last (S_ms_last),
        .O_cnt  (S_mcnt),
        .O_xmin (S_xmin),
        .O_xmax (S_xmax),
        .O_ymin (S_ymin),
        .O_ymax (S_ymax),
        .O_sumx (S_sumx),
        .O_sumy (S_sumy),
        .O_empty(S_empty)
    );

    assign O_mask_cnt_shift = S_mcnt >> 4;
    assign O_bbox_x         = {S_xmin[10:4], S_xmax[10:4]};
    assign O_bbox_y         = {S_ymin[9:4],  S_ymax[9:4]};

    // 用边沿流（比 raw 流晚 2 拍）的帧首翻 toggle：此刻 tap 计数与掩码统计都已锁存
    // （肤色源在 raw tuser 那一拍就锁存完了，比这早 2 拍，数据先稳定、toggle 后翻转，
    // 正是"发送侧数据先于 toggle 稳定"的跨域约定）。同样**不能闸在 tvalid 上**——
    // 理由见上面 tap 计数器那段的注释。
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            O_status_toggle <= 1'b0;
        else if(I_edge_tuser)
            O_status_toggle <= ~O_status_toggle;
    end

    // 说明：S_sumx / S_sumy / S_empty 在 M0 里没有消费者（会综合掉），M1 接质心与
    // 丢失判定时自然回来——接口先冻结，省得 M1 再改一次模块端口。

    // ---- CTRL_SYNC 上行：M0 原样回传收到的字（往返自检）-----------------------
    assign O_ctrl_tx_data  = I_ctrl_rx_data;
    assign O_ctrl_tx_valid = I_ctrl_rx_valid;

endmodule
