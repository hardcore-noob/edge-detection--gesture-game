module isp_top #(
    // 边缘显示增益（显示灰度 = clamp((|gx|+|gy|) << shift)）。门限本身从 M0 起是
    // **运行时**的（I_edge_th，由像素域的模式寄存器在相机帧首提交过来），不再编译期
    // 写死。增益 0 让饱和点落在 Δ≈64；TH=16 对应"Δ≥4 灰阶就可见"。
    parameter integer EDGE_GAIN_SHIFT = 0,

    // 调试叠加开关：1 = 无条件把识别结果（掩码高亮/指针）画在 RAW 画面上，板上看效果用；
    // 0 = 正式行为，由 C 的 mode_word 决定（recog_algo[15:12]==1 即"手势"时才叠加）。
    // ⚠ 2026-10-11 M2.2 上板诊断：置 1 → 叠加（掩码高亮 + 准星 + **指尖方点**）常开，
    // 开机就能看到"掩码有没有贴住手、指尖跟不跟手"，不用按 KEY4、不用串口。
    // 交付版改回 0（那时只有 recog_algo==1 才叠加）。
    // ⚠ 2026-10-16 合并队友 M4a 游戏层后改回 0（交付安全）：常开会把掩码烤进 DDR 帧，
    // 游戏画面的背景就会带红色叠加。要"开机就看到掩码+准星+指尖点"，改回 1 即可；
    // 或者（不改编译）用下面的诊断档：`W 08 0005 / 000C / 000D / 000E` 都会打开叠加。
    parameter integer MASK_PREVIEW = 0,

    // 调试版模式选择（默认 0 = 交付行为）：
    //   1 = 用 C 的 recog_algo[15:12] 当"运行时视图号"，任一非 0 值都出叠加；
    //       串口 `W 08 000X` 实时切换，不用重编译（视图表见下面"叠加通路"一段）
    //   0 = 交付行为：只有 recog_algo==1 才叠加，与原来完全一致
    parameter integer DIAG_MODE_SEL = 0,

    // 彩色通路的**数字增益**（暗光应急用，不改 C 的 ae_set.v）：
    //   0 = **按档位自动**（见下面 S_dgain：8/12/13/14/15 = ×2、9 = ×4、其余 ×1）；
    //   1 = 强制 ×2、2 = 强制 ×4（忽略档位，方便以后一次编译定死）。
    // 只作用在"彩色流"上（**识别支路的 tap + RAW 显示**），**不动边缘检测那条路**，
    // 所以 EDGE 画面的行为不变。注意：开启后一切基于绝对数值的颜色判据都要按新亮度重调。
    // ⚠ 2026-10-17：以前这路增益**只进显示**，recog_top 的 tap 拿的是未增益的 awb_O_tdata
    //   （两个注释互相矛盾）→ 画面亮了、判据还是暗的。现在 tap 也接 S_awb_g（见实例化）。
    parameter integer DIG_GAIN_SHIFT = 0
)(
    input           axi4s_video_aclk,
    input           I_rst_n,
    input           I_alg_sel,
    input  [10:0]   I_edge_th,
    input  [25:0]   I_mode_committed,   // mode_sync 的提交字（CSI 域）：透传给 recog_top（M1 用它选算法）
    input           I_tlast,
    input           I_tuser,
    input  [39:0]   I_tdata,
    input           I_tvalid,
    input  [9:0]    I_tdest,
    input           O_tready,
    output [127:0]  O_tdata,
    output          O_tlast,
    output          O_tuser,
    output          O_tvalid,
    output          I_tready,
    output          O_edge_dbg_valid,
    output          O_edge_dbg_nonzero,

    // VIDEO_TAP（M0 新增）：识别支路取点就在本模块内部、RAW/EDGE MUX 之前，
    // 这样 EDGE 模式下彩色流依然存在（肤色的 Plan B 要用），而且不用把 96 位流
    // 拉到顶层（feedthrough 已经很紧）。对外只引出小宽度的观测与 CTRL_SYNC 端点。
    input  [25:0]   I_ctrl_rx_data,
    input           I_ctrl_rx_valid,
    output [25:0]   O_ctrl_tx_data,
    output          O_ctrl_tx_valid,
    output [11:0]   O_tap_px_shift,
    output [15:0]   O_mask_cnt_shift,
    output [13:0]   O_bbox_x,
    output [11:0]   O_bbox_y,
    output          O_status_toggle,
    // M1 追踪结果（VIDEO_TAP 观测包扩展，帧锁存；像素域用 toggle 整包捕获）—— 队友 C 的
    // 游戏层要用（6c95b87 加的 3 个口，合并时保留）
    output [10:0]   O_track_x,
    output [9:0]    O_track_y,
    output          O_track_locked
);

    // Algorithm selection: 0 = RAW (AWB output), 1 = EDGE (edge_detect_96 output).
    // I_alg_sel 已在顶层做跨时钟域同步（稳定电平），直接驱动 MUX。
    // 切换瞬间当前写入帧可能撕裂，下一帧即恢复正常。

    wire         m_aixs_tvalid;  //synthesis keep
    wire [127:0] m_aixs_tdata;  //synthesis keep
    wire         m_aixs_tuser;  //synthesis keep
    wire         m_aixs_tlast;  //synthesis keep
    wire         m_aixs_tready;  //synthesis keep

    wire [ 95:0] m_aixs_tdata_96;  //synthesis keep

    wire         awb_O_tlast;  //synthesis keep
    wire         awb_O_tuser;  //synthesis keep
    wire [ 95:0] awb_O_tdata;  //synthesis keep
    wire         awb_O_tvalid;  //synthesis keep

    wire         awb_O_tuser_128;  //synthesis keep
    wire         awb_O_tvalid_128;  //synthesis keep
    wire [127:0] awb_O_tdata_128;  //synthesis keep
    wire         awb_O_tlast_128;  //synthesis keep

    wire         edge_O_tlast;  //synthesis keep
    wire         edge_O_tuser;  //synthesis keep
    wire [ 95:0] edge_O_tdata;  //synthesis keep
    wire         edge_O_tvalid;  //synthesis keep

    // Stream selected by S_alg_sel and sent to data_96bit_to_128bit
    wire         sel_tlast;
    wire         sel_tuser;
    wire [ 95:0] sel_tdata;
    wire         sel_tvalid;

    // ---- 叠加通路（使能取自 C 的 mode_word 契约，见 mode_sync.v）---------------
    // 布局：recog_algo = I_mode_committed[15:12]、game_mode = [11:8]（见 mode_sync.v 文件头）。
    // recog_algo 同时当**运行时视图号**（串口 `W 08 000X`，不用重编译）：
    //   0 = 原摄像头画面（不叠加）          1 = 融合掩码 + 准星（正常交付视图）
    //   2 = 背景帧预览（画面换成背景帧）    3 = AWB 之前视图
    //   4 = 运动门归因（红=两门都过/绿=只过绝对门/青=只过相对门）
    //   5 = 只看肤色门(红)  6 = ROI 边框+融合  7 = 三色诊断
    //   12 = **亮度灰阶**（画面换成 8 位灰度 Y，看亮度分布）
    //   13 = 肤色判据观测（过肤色判据的像素按 Y 分档着色：绿/青/黄/红）
    //   14 = ② 亮暖反射门 + 运动门（候选）；**15 = ② + 运动门 + ① 块级占比门（交付候选）**
    //   10/11 = 旧肤色预设；15 = 运动门全家桶
    //   ⚠ 2026-10-17：**8/12/13/14/15 = 数字增益 ×2、9 = ×4**（其余 ×1）——
    //     档 8/9 原来分别是"旧 Y 基准 / 柔和跟随"的老标定档，现在改当**亮度 A/B 档**：
    //     `W 08 0001`（×1）↔ `W 08 0008`（×2）↔ `W 08 0009`（×4）可以直接比亮度和杂码。
    //   ⚠ 2026-10-16：4/6/7 原来**不在 S_dbg_ovl 里** → 那几档没开叠加通路，看着像"没反应"。
    //   ⚠ 2026-10-16：档 **2/3 改给"运动门开/关"**（见 recog_top 的 S_mot_on）——
    //     档 2 = 运动门开（融合 = 肤色 ∩ 运动）、档 3 = 关（对照）。原来的"背景帧预览"
    //     是 DIAG_MODE_SEL=1 时的视角（`S_bgview`，默认关），两者只在 DIAG_MODE_SEL=1
    //     同板对比时才冲突（那时别用 2 档做运动门 A/B，用 3 档当"关"的对照）。
    // MASK_PREVIEW=1 时无条件叠加；DIAG_MODE_SEL=1 时任一非 0 视图号都叠加；
    // 正式交付两者都为 0 → 只有 recog_algo==1 才叠加。
    // 【第 4 轮】再加一条：一键示教的"2 秒闪叠加"（recog_top 的 O_teach_flash）—— 采样窗结束后
    //   不管判定过不过都无条件叠加约 2 s，用来立刻看"示范时手有没有被掩码点亮"。平时恒 0，
    //   所以开机画面不受影响（这条是 A 线为了示教验收加的唯一一条叠加使能）。
    // 每像素 3 bit 色码（recog_top 的 O_ovl_sel 给）：
    //   0=原像素 1=掩码高亮(红) 2=准星(黄) 3=只过肤色(纯红) 4=只过运动(纯绿)
    //   5=两者都过(纯黄) 6=ROI 窗口边框(纯蓝) 7=准星(青)
    wire [11:0] S_ovl_sel;
    wire [7:0]  S_bg_px;                       // recog_top 给的"当前块背景灰度"
    wire        S_teach_flash;                 // recog_top 的一键示教"闪叠加"指示（~2 s）
    wire [3:0]  S_dbg_mode = I_mode_committed[15:12];
    // 【M2.2】归因档（5 = 只看原始肤色门；12/13/14 = 投票/门的组合）也打开叠加：
    //   否则这几个档位下用户看不到掩码，没法做"哪一档被谁啃了"的判断。
    // ⚠ 2026-10-16 第 3 轮：**这里漏了 4/6/7** —— 用户上板看"档 4 一根掩码都没有"，
    //   根因不是运动门，是这几档根本没开叠加通路（画面就是纯摄像头）。现在把
    //   4/5/6/7 全部补上（诊断视图一律能看）。
    wire S_dbg_ovl = (S_dbg_mode == 4'd4)  || (S_dbg_mode == 4'd5)  ||
                     (S_dbg_mode == 4'd6)  || (S_dbg_mode == 4'd7)  ||
                     (S_dbg_mode == 4'd12) || (S_dbg_mode == 4'd13) || (S_dbg_mode == 4'd14) ||
                     (S_dbg_mode == 4'd10) || (S_dbg_mode == 4'd11) ||
                     (S_dbg_mode == 4'd15) ||
                     (S_dbg_mode == 4'd2)  || (S_dbg_mode == 4'd3);
    // 档 12 = **亮度灰阶**（画面直接换成 8 位灰度 Y）：看"手 vs 反光"的亮度分布。
    wire S_yview = (S_dbg_mode == 4'd12);
    // 10/11 = 旧肤色预设（当前走普通融合视图），15 = 运动门全家桶；
    // **2 = 运动门开、3 = 运动门关（对照）**（2026-10-16 从新实现运动门时加的）——
    // 这两档都要能在画面里看到掩码 + 准星，现场才能"同一个手、同一个位置，切 2/3 对比"。
    // 【2026-10-17 ⑤】13 = 肤色判据观测（皮肤掩码按 Y 分档着色）、14 = ② 亮暖反射门
    //   + 运动门（最终候选）；两档都借 P/Q 报"掩码内 Y/sat 的帧内极值"。
    //   4 = 运动门归因（红=两个门都过 / 绿=只过绝对门 / 青=只过相对门）。
    wire S_ovl_en = MASK_PREVIEW | S_teach_flash | S_dbg_ovl |
                    ((DIAG_MODE_SEL != 0) ? (S_dbg_mode != 4'd0) : (S_dbg_mode == 4'd1));
    wire S_bgview = (DIAG_MODE_SEL != 0) && (S_dbg_mode == 4'd2);

    function [23:0] F_ovl_pix;
        input [23:0] I_pix;
        input [2:0]  I_sel;
        begin
            case (I_sel)
                3'd1: F_ovl_pix = {8'hFF, I_pix[15:9], 1'b0, I_pix[7:1], 1'b0}; // 掩码：红拉满+G/B 减半
                3'd2: F_ovl_pix = 24'hFFFF00;   // 准星（黄）
                3'd3: F_ovl_pix = 24'hFF0000;   // 诊断：只过肤色
                3'd4: F_ovl_pix = 24'h00FF00;   // 诊断：只过运动
                3'd5: F_ovl_pix = 24'hFFFF00;   // 诊断：两者都过
                3'd6: F_ovl_pix = 24'h0000FF;   // 诊断：ROI 窗口边框
                3'd7: F_ovl_pix = 24'h00FFFF;   // 诊断：准星（青）
                default: F_ovl_pix = I_pix;
            endcase
        end
    endfunction

    // 【2026-10-16 第 3 轮】亮度灰阶（档 12）：把像素换成 8 位灰度 Y = (R + 2G + B)/4。
    //   与 recog_top 的肤色判据用**同一个 Y 公式**（截位方式逐位相同），所以屏幕上看到的
    //   灰阶就是判据吃的那个 Y —— "手在哪个灰阶、铁皮反光在哪个灰阶"一眼可读，
    //   不用再靠串口读数字（用户要求："干脆画成灰阶梯，一眼看亮度分布"）。
    // 成本：4 像素 ×（2 个移位加法）≈ 50 LUT6。
    function [7:0] F_gray8;
        input [23:0] I_pix;
        begin
            F_gray8 = {2'b0, I_pix[23:18]} + {1'b0, I_pix[15:9]} + {2'b0, I_pix[7:2]};
        end
    endfunction

    // 背景帧预览：直接把背景灰度当像素显示（背景 ERAM 若是空的，这里就是整屏黑）
    function [23:0] F_preview_pix;
        input [23:0] I_pix;
        input [2:0]  I_sel;
        reg   [7:0]  S_y;
        begin
            S_y = F_gray8(I_pix);
            F_preview_pix = S_bgview ? {S_bg_px, S_bg_px, S_bg_px}
                          : S_yview  ? {S_y,     S_y,     S_y}
                                     : F_ovl_pix(I_pix, I_sel);
        end
    endfunction
    // mode 3：直接看 **AWB 之前** 的画面（demosaic 直出、不做白平衡）——
    // 用来分辨"画面偏绿"是 AWB 增益的锅，还是 demosaic/Bayer 相位的锅。
    // 这一路的时间基准必须跟着 demosaic 流走（与叠加那一路不是同一拍）。
    // ---- 数字增益：单通道饱和左移（**运行时可切**，2026-10-17）------------------
    // 用户实测这一场极暗（肤色像素 Y≈32..63），而彩色判据的下界是 Y/21 ⇒ 只有 2 个 LSB，
    // 和暗场噪声（±2~3）同量级 —— 判据在赌噪声。先提亮再谈阈值。
    //   档 8 / 12 / 13 / 14 / 15 = **×2**（候选档与观测档统一到同一亮度，读数才对得上）
    //   档 9 = **×4**（更激进、亮部会削顶；顺便保留它原有的柔和跟随，看掩码不受影响）
    //   其余档 = ×1（交付档 0/1 不变）
    // `DIG_GAIN_SHIFT` 非 0 时强制覆盖（1=×2、2=×4）。
    wire [1:0] S_dgain = (DIG_GAIN_SHIFT == 2) ? 2'd2 :
                         (DIG_GAIN_SHIFT != 0) ? 2'd1 :
                         ((S_dbg_mode == 4'd9) ? 2'd2 :
                          ((S_dbg_mode == 4'd8)  || (S_dbg_mode == 4'd12) ||
                           (S_dbg_mode == 4'd13) || (S_dbg_mode == 4'd14) ||
                           (S_dbg_mode == 4'd15)) ? 2'd1 : 2'd0);

    function [7:0] F_sat_shl;
        input [7:0] I_v;
        input [1:0] I_sh;
        reg [9:0]   S_t;
        begin
            S_t = {2'b0, I_v} << I_sh;          // ×1/×2/×4（≤ 1020）
            F_sat_shl = S_t[9:8] ? 8'hFF : S_t[7:0];
        end
    endfunction

    function [23:0] F_dig_gain_px;
        input [23:0] I_px;
        begin
            F_dig_gain_px = { F_sat_shl(I_px[23:16], S_dgain),
                              F_sat_shl(I_px[15:8],  S_dgain),
                              F_sat_shl(I_px[7:0],   S_dgain) };
        end
    endfunction

    // 带增益彩色流：**显示与识别支路共用**（同源 ⇒ 屏幕上看到的亮度就是判据吃的亮度）
    wire [95:0] S_awb_g = { F_dig_gain_px(awb_O_tdata[95:72]), F_dig_gain_px(awb_O_tdata[71:48]),
                            F_dig_gain_px(awb_O_tdata[47:24]), F_dig_gain_px(awb_O_tdata[23:0]) };

    // ★ 2026-10-17：**增益后打一拍**再往下送。原因：运行时可切的增益（2 级 barrel shift +
    //   饱和比较）正好落在原来就最紧的那条路上（`awb → 肤色判据 → g_cent 的 Σw·x 累加器`），
    //   没打拍时 final Setup WNS 只剩 **+33 ps**（门禁要 ≥ +300 ps）。
    //   把 tdata/tvalid/tlast/tuser **整包一起**打一拍 ⇒ 显示与识别支路仍然严格同拍，
    //   叠加不会错位；代价 99 FF。
    reg [95:0] r_awb_g;
    reg        r_awb_g_vld, r_awb_g_lst, r_awb_g_usr;
    always @(posedge axi4s_video_aclk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            r_awb_g     <= 96'd0;
            r_awb_g_vld <= 1'b0;
            r_awb_g_lst <= 1'b0;
            r_awb_g_usr <= 1'b0;
        end
        else begin
            r_awb_g     <= S_awb_g;
            r_awb_g_vld <= awb_O_tvalid;
            r_awb_g_lst <= awb_O_tlast;
            r_awb_g_usr <= awb_O_tuser;
        end
    end
    wire [95:0] S_awb_gd     = r_awb_g;
    wire        S_awb_gd_vld = r_awb_g_vld;
    wire        S_awb_gd_lst = r_awb_g_lst;
    wire        S_awb_gd_usr = r_awb_g_usr;

    // 叠加/显示用的像素取**打拍后**的同一包（与 recog_top 的 tap 严格同拍）
    wire [95:0] S_preview_ovl = {
        F_preview_pix(S_awb_gd[95:72], S_ovl_sel[11:9]),   // 字内最左像素
        F_preview_pix(S_awb_gd[71:48], S_ovl_sel[8:6]),
        F_preview_pix(S_awb_gd[47:24], S_ovl_sel[5:3]),
        F_preview_pix(S_awb_gd[23:0],  S_ovl_sel[2:0])
    };

    wire S_preawbview = (DIAG_MODE_SEL != 0) && (S_dbg_mode == 4'd3);
    wire [95:0] S_preview_tdata = S_preawbview ? m_aixs_tdata_96 : S_preview_ovl;
    wire        S_pre_vld = S_preawbview ? m_aixs_tvalid : S_awb_gd_vld;
    wire        S_pre_lst = S_preawbview ? m_aixs_tlast  : S_awb_gd_lst;
    wire        S_pre_usr = S_preawbview ? m_aixs_tuser  : S_awb_gd_usr;

    // 叠加时时间基准锁在 RAW 流上（掩码就是在 RAW 上算的，同拍对齐）
    assign sel_tdata  = S_ovl_en ? S_preview_tdata : (I_alg_sel ? edge_O_tdata  : S_awb_gd);
    assign sel_tvalid = S_ovl_en ? S_pre_vld       : (I_alg_sel ? edge_O_tvalid : S_awb_gd_vld);
    assign sel_tlast  = S_ovl_en ? S_pre_lst       : (I_alg_sel ? edge_O_tlast  : S_awb_gd_lst);
    assign sel_tuser  = S_ovl_en ? S_pre_usr       : (I_alg_sel ? edge_O_tuser  : S_awb_gd_usr);

    // 下游 data_96bit_to_128bit 无反压，awb/edge 的输入 ready 直接接 1；
    // 它们的输出 ready（模块内部为直通）悬空不接，避免组合环路。
    assign O_tdata  = awb_O_tdata_128;
    assign O_tlast  = awb_O_tlast_128;
    assign O_tuser  = awb_O_tuser_128;
    assign O_tvalid = awb_O_tvalid_128;
    assign O_edge_dbg_valid = edge_O_tvalid;
    assign O_edge_dbg_nonzero = |edge_O_tdata;

    //assign m_aixs_tready = O_tready;
    //assign O_tdata  = m_aixs_tdata;
    //assign O_tlast  = m_aixs_tlast;
    //assign O_tuser  = m_aixs_tuser;
    //assign O_tvalid = m_aixs_tvalid;

    demosaic #(
        .IMG_HEIGHT          (720),  // 图像高度
        .IMG_WIDTH           (1280),   // 图像宽度
        .data_complete_delay (50  ),
        .BAYER_MODE          ("BGGR")
    )
    u_demosaic
    (
        .I_clk              (axi4s_video_aclk),
        .I_rst_n            (I_rst_n),
        .axi4s_video_tdata  (I_tdata),
        .axi4s_video_tdest  (I_tdest),
        .axi4s_video_tlast  (I_tlast),
        .axi4s_video_tvalid (I_tvalid),
        .axi4s_video_tuser  (I_tuser),
        .axi4s_video_tready (I_tready),
        .O_tlast            (m_aixs_tlast),
        .O_tuser            (m_aixs_tuser),
        .O_tdata            (m_aixs_tdata),
        .O_tvalid           (m_aixs_tvalid),
        .O_tready           (m_aixs_tready)
    );

    data128_96 u_data128_96 (
        .I_tdata(m_aixs_tdata),
        .O_tdata(m_aixs_tdata_96)
    );

    awb #(
        .IMG_HEIGHT(720),
        .IMG_WIDTH (1280)
    ) u_awb (
        .I_clk   (axi4s_video_aclk),
        .I_rst_n (I_rst_n),
        .I_tlast (m_aixs_tlast),
        .I_tuser (m_aixs_tuser),
        .I_tdata (m_aixs_tdata_96),
        .I_tvalid(m_aixs_tvalid),
        .I_tready(),
        .O_tlast (awb_O_tlast),
        .O_tuser (awb_O_tuser),
        .O_tdata (awb_O_tdata),
        .O_tvalid(awb_O_tvalid),
        .O_tready(1'b1)
    );

    edge_detect_96 #(
        .IMG_WIDTH (1280),
        .IMG_HEIGHT(720),
        .EDGE_GAIN_SHIFT(EDGE_GAIN_SHIFT)
    ) u_edge_detect_96 (
        .I_clk   (axi4s_video_aclk),
        .I_rst_n (I_rst_n),
        .I_tlast (awb_O_tlast),
        .I_tuser (awb_O_tuser),
        .I_tdata (awb_O_tdata),
        .I_tvalid(awb_O_tvalid),
        .I_tready(1'b1),
        .I_thresh(I_edge_th),
        .O_tlast (edge_O_tlast),
        .O_tuser (edge_O_tuser),
        .O_tdata (edge_O_tdata),
        .O_tvalid(edge_O_tvalid),
        .O_tready()
    );

    // ---- 识别支路（M0：tap 监视 + 掩码统计 + CTRL_SYNC 端点）------------------
    // 取点：AWB 输出的彩色 RAW 流与边缘流，都在上面的 MUX 之前。
    recog_top u_recog_top (
        .I_clk           (axi4s_video_aclk),
        .I_rst_n         (I_rst_n),
        // 【2026-10-17】识别支路也吃**带数字增益**的流（以前这里接的是 awb_O_tdata，
        // 所以 DIG_GAIN_SHIFT 只提亮了屏幕、判据还是暗的）。
        .I_raw_tdata     (S_awb_gd),
        .I_raw_tuser     (S_awb_gd_usr),
        .I_raw_tlast     (S_awb_gd_lst),
        .I_raw_tvalid    (S_awb_gd_vld),
        .I_edge_tdata    (edge_O_tdata),
        .I_edge_tuser    (edge_O_tuser),
        .I_edge_tlast    (edge_O_tlast),
        .I_edge_tvalid   (edge_O_tvalid),
        .I_mode_word     (I_mode_committed),
        .I_ctrl_rx_data  (I_ctrl_rx_data),
        .I_ctrl_rx_valid (I_ctrl_rx_valid),
        .O_ctrl_tx_data  (O_ctrl_tx_data),
        .O_ctrl_tx_valid (O_ctrl_tx_valid),
        .O_tap_px_shift  (O_tap_px_shift),
        .O_mask_cnt_shift(O_mask_cnt_shift),
        .O_bbox_x        (O_bbox_x),
        .O_bbox_y        (O_bbox_y),
        .O_status_toggle (O_status_toggle),
        .O_track_x       (O_track_x),
        .O_track_y       (O_track_y),
        .O_track_locked  (O_track_locked),
        .O_ovl_sel       (S_ovl_sel),
        .O_bg_px         (S_bg_px),
        .O_teach_flash   (S_teach_flash)
    );

    data_96bit_to_128bit u_data_96bit_to_128bit(
        .I_clk              ( axi4s_video_aclk  ),
        .I_rst_n            ( I_rst_n           ),

        .I_96b_frame_start  ( sel_tuser         ),
        .I_96b_valid        ( sel_tvalid        ),
        .I_96b_data         ( sel_tdata         ),
        .I_96b_tlast        ( sel_tlast         ),

        .O_128b_frame_start ( awb_O_tuser_128   ),
        .O_128b_valid       ( awb_O_tvalid_128  ),
        .O_128b_data        ( awb_O_tdata_128   ),
        .O_128b_tlast       ( awb_O_tlast_128   )
    );

    //data96_128 u_data96_128 (
    //    .I_tdata(awb_O_tdata),
    //    .O_tdata(awb_O_tdata_128)
    //);

endmodule
