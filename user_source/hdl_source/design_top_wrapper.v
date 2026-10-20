

module design_top_wrapper (
    input wire        I_sys_clk,
    input wire        I_rst_n,
      
    output wire       O_cam_scl,
    inout  wire       IO_cam_sda,
    output wire       O_cam_24m,
    output wire       O_cam_rst,
      
    input wire [3:0]  I_button,
    input wire [3:0]  I_switch,
    input wire        I_uart_rx,

    output wire [3:0] O_led,
    output wire       O_buzzer,

    output wire       O_screen_pwm,
    output wire       O_tmds_ch0_p,
    output wire       O_tmds_ch1_p,
    output wire       O_tmds_ch2_p,
    output wire       O_tmds_clk_p,

    inout wire        IO_rx_clk_pad_n, 
    inout wire        IO_rx_clk_pad_p, 
    inout wire[3:0]   IO_rx_data_pad_n,
    inout wire[3:0]   IO_rx_data_pad_p,

    output wire       O_debug_tx,
    output wire[12:0] ddr_addr,
    output wire[ 1:0] ddr_ba,
    output wire[ 0:0] ddr_cke,
    output wire[ 0:0] ddr_odt,
    output wire[ 0:0] ddr_cs_n,
    output wire       ddr_ras_n,
    output wire       ddr_cas_n,
    output wire       ddr_we_n,
    output wire[ 0:0] ddr_ck_p,
    output wire[ 0:0] ddr_ck_n,
    inout wire[1:0]   ddr_dm,
    inout wire[15:0]  ddr_dq,
    inout wire[1:0]   ddr_dqs_p,
    inout wire[1:0]   ddr_dqs_n   
);


    wire        	S_100m_clk;
    wire        	S_24m_clk;
    wire        	S_aux_50m_clk;
	wire        	S_10m_clk;
		
	wire        	S_pll_lock;
    wire        	S_rst_n;
	
	wire [15:0] 	S_ae;
    wire [15:0] 	S_ag;
    wire 			S_cam_cfg_done;
    wire 			S_ae_cfg_done;
    wire 			S_ae_req; 
	
	wire        	S_csi_rx_clk;  
    wire        	S_hs_rx_valid;  
    wire[15:0]  	S_hs_rx_data;   
	wire[1:0]   	S_lane_error;
	
	wire        	S_csi_frame_start;       
	wire        	S_csi_frame_end;         
	wire        	S_csi_valid;             
	wire[31:0]  	S_csi_data;  
		
	wire        	S_raw10_frame_start; 
	wire        	S_raw10_frame_end;   
	wire        	S_raw10_valid;       
	wire [39:0] 	S_raw10_data;
		
	wire 			S_axis_tlast;  
	wire 			S_axis_tuser;  
	wire [39:0]		S_axis_tdata;  
	wire 			S_axis_tvalid; 
	
	wire [39:0]		S_raw_tdata ;
	wire			S_raw_tlast ;
	wire 			S_raw_tvalid;
	wire 			S_raw_tuser ;
	
	wire			S_ISP_O_tready;
	wire [127:0]	S_ISP_O_tdata ;
	wire 			S_ISP_O_tlast ;
	wire 			S_ISP_O_tuser ;
	wire 			S_ISP_O_tvalid; 
	

    wire        S_ddr_clk;
    wire        S_hdmi_pixel_clk;
    wire        S_hdmi_serial_clk;
    wire        S_hdmi_rst_n;
    wire        S_video_out_rst_n;


    wire        S_vi_128b_frame_start;
    wire        S_vi_128b_valid;      
    wire[127:0] S_vi_128b_data;    
    
    wire        S_video_out_rd_busy;
    wire        S_video_in_wr_busy; 
    wire[1:0]   S_video_out_rp;     

    wire        S_ddr_user_wr_en;       
    wire        S_ddr_user_rd_en;       
    wire[24:0]  S_ddr_user_addr;        
    wire[127:0] S_ddr_user_wr_data;     
    wire        S_ddr_user_ready;       
    wire        S_ddr_user_rd_valid;    
    wire[127:0] S_ddr_user_rd_data;     

    wire        S_vi_ddr_wr_en;   
    wire[24:0]  S_vi_ddr_wr_addr; 
    wire[127:0] S_vi_ddr_wr_data;
    wire        S_vi_ddr_wr_ready;

    wire        S_vo_ddr_rd_en;   
    wire[24:0]  S_vo_ddr_rd_addr; 
    wire        S_vo_ddr_rd_ready;
    wire        S_vo_dbg_fifo_rst;
    wire        S_vo_dbg_ddr_rd_valid;
    wire        S_vo_dbg_fifo_rd_en;
    wire        S_vo_dbg_fifo_empty;

    wire        S_init_calib_complete; 
    wire[24:0]  S_mc_app_addr;          
    wire[2:0]   S_mc_app_cmd;           
    wire        S_mc_app_en;            
    wire[127:0] S_mc_app_wdf_data;      
    wire        S_mc_app_wdf_end;       
    wire[15:0]  S_mc_app_wdf_mask;      
    wire        S_mc_app_wdf_wren;      
    wire[127:0] S_mc_app_rd_data;       
    wire        S_mc_app_rd_data_end;   
    wire        S_mc_app_rd_data_valid; 
    wire        S_mc_app_rdy;           
    wire        S_mc_app_wdf_rdy;       
    wire        S_mc_dbg_fifo_afull;
    wire        S_mc_dbg_app_rdy;
    wire        S_mc_dbg_wdf_rdy;
    wire        S_mc_dbg_cmd_pop;

    wire        S_hdmi_vsync;
    wire        S_hdmi_hsync;
    wire        S_hdmi_de;
    wire        S_hdmi_user;
    wire        S_hdmi_last;
    wire        S_video_out_vsync;
    reg         S_video_out_vsync_ddr_1d;
    reg         S_video_out_vsync_ddr_2d;
    wire        S_hdmi_window_rd_en;
    wire        S_hdmi_out_vsync;
    wire        S_hdmi_out_hsync;
    wire        S_hdmi_out_de;
    wire[23:0]  S_hdmi_out_data;

    wire[23:0]  S_video_rd_data;
    wire [7:0]  S_video_max_ch;
    reg         S_dbg_raw_seen;
    reg [9:0]   S_dbg_raw_max_px;
    reg [9:0]   S_dbg_raw_max_hold;
    reg [9:0]   S_dbg_raw_max_sync1;
    reg [9:0]   S_dbg_raw_max_sync2;
    reg         S_dbg_isp_seen;
    reg         S_dbg_ddr_wr_seen;
    reg         S_dbg_ddr_rd_seen;
    reg         S_dbg_cam_cfg_seen;
    reg         S_dbg_hs_seen;
    reg         S_dbg_csi_seen;
    reg         S_dbg_raw10_seen;
    reg         S_dbg_isp_fs_seen;
    reg         S_dbg_isp_valid_seen;
    reg         S_dbg_ddr_req_seen;
    reg         S_dbg_ddr_ready_seen;
    reg [1:0]   S_dbg_raw_seen_sync;
    reg [1:0]   S_dbg_isp_seen_sync;
    reg [1:0]   S_dbg_ddr_wr_seen_sync;
    reg [1:0]   S_dbg_ddr_rd_seen_sync;
    reg [1:0]   S_dbg_cam_cfg_seen_sync;
    reg [1:0]   S_dbg_hs_seen_sync;
    reg [1:0]   S_dbg_csi_seen_sync;
    reg [1:0]   S_dbg_raw10_seen_sync;
    reg [1:0]   S_dbg_isp_fs_seen_sync;
    reg [1:0]   S_dbg_isp_valid_seen_sync;
    reg [1:0]   S_dbg_ddr_req_seen_sync;
    reg [1:0]   S_dbg_ddr_ready_seen_sync;
    reg         S_dbg_video_nonzero_seen;
    reg         S_dbg_rd_req_seen;
    reg         S_dbg_rd_valid_seen;
    reg         S_dbg_rd_nonzero_seen;
    reg [1:0]   S_dbg_rd_req_seen_sync;
    reg [1:0]   S_dbg_rd_valid_seen_sync;
    reg [1:0]   S_dbg_rd_nonzero_seen_sync;
    reg         S_dbg_mc_init_seen;
    reg         S_dbg_mc_app_rdy_seen;
    reg         S_dbg_mc_wdf_rdy_seen;
    reg         S_dbg_mc_cmd_pop_seen;
    reg [1:0]   S_dbg_mc_init_seen_sync;
    reg [1:0]   S_dbg_mc_app_rdy_seen_sync;
    reg [1:0]   S_dbg_mc_wdf_rdy_seen_sync;
    reg [1:0]   S_dbg_mc_cmd_pop_seen_sync;
    wire[3:0]   S_hdmi_debug_status;
    wire[23:0]  S_debug_status_bus;
    reg [15:0]  S_frame_cnt_dbg;
    reg [19:0]  S_dbg_nonzero_px;
    reg [19:0]  S_dbg_bright_px;
    reg [19:0]  S_dbg_very_px;
    reg [7:0]   S_dbg_max_px;
    // 日志只报"上一完整帧"的统计：计数器在帧首清零前先锁存，避免一行 4.3ms 里
    // 边发边采样（N/B/C 各自采自帧内不同时刻，读数会在几倍之间乱跳）。
    reg [19:0]  S_dbg_nonzero_hold;
    reg [19:0]  S_dbg_bright_hold;
    reg [19:0]  S_dbg_very_hold;
    reg [7:0]   S_dbg_max_hold;
    // ---- FIFO 拥塞观测（2026-09-12 新增）------------------------------------
    // 两个 FIFO 的写侧都可能静默丢数据（没有 backpressure 闭环，见 README 第 9 节），
    // 这里把它们各自的"丢写次数 + 占用"同步到显示域，按显示帧统计后进 DBG 日志：
    //   D = video_in  FIFO（ISP→DDR）上一帧丢写次数
    //   E = video_out FIFO（DDR→HDMI）上一帧丢写次数
    //   W = video_in  FIFO 上一帧最大占用（0..511）
    //   V = video_out FIFO 上一帧最大占用（0..511）
    // 丢写次数在两个 FIFO 自己的写时钟域里自由计数，这里只同步数值、按帧取差，
    // 所以不会漏掉"单拍脉冲"；同步引入的偏斜最多一两拍，对统计无影响。
    wire [15:0] S_fifo_in_drop_raw;
    wire [15:0] S_fifo_out_drop_raw;
    wire [8:0]  S_fifo_in_used_raw;
    wire [8:0]  S_fifo_out_used_raw;
    reg  [15:0] S_fifo_in_drop_s1,  S_fifo_in_drop_s2;
    reg  [15:0] S_fifo_out_drop_s1, S_fifo_out_drop_s2;
    reg  [8:0]  S_fifo_in_used_s1,  S_fifo_in_used_s2;
    reg  [8:0]  S_fifo_out_used_s1, S_fifo_out_used_s2;
    reg  [15:0] S_fifo_in_drop_prev, S_fifo_out_drop_prev;
    reg  [15:0] S_dbg_fifo_in_drop,  S_dbg_fifo_out_drop;
    reg  [8:0]  S_dbg_fifo_in_used,  S_dbg_fifo_out_used;
    reg  [8:0]  S_fifo_in_used_max,  S_fifo_out_used_max;
    reg         S_hdmi_user_1d;
    reg         S_dbg_alg_prev;
    // 曝光/增益先落到像素域打一拍再进 logger（见下面 logger 实例处的说明）
    reg [15:0]  S_ae_px, S_ag_px;
    wire        S_edge_dbg_valid;
    wire        S_edge_dbg_nonzero;
    reg         S_dbg_edge_valid_seen;
    reg         S_dbg_edge_nonzero_seen;
    reg [1:0]   S_dbg_edge_valid_seen_sync;
    reg [1:0]   S_dbg_edge_nonzero_seen_sync;
    wire        S_lane_error_any;
    // ---- 模式寄存器 / PARAM_BUS / 四个插座（2026-09-14，手势游戏 M0）----------
    // 模式与参数的唯一事实源是 param_ctrl（像素域）；display_mode 与边缘门限档位
    // 经 mode_sync 在相机帧首提交到 CSI 域，避免切换时把一帧切成两种算法。
    wire [3:0]  S_display_mode;
    wire [3:0]  S_game_mode;
    wire [3:0]  S_edge_th_sel;
    wire [10:0] S_edge_th;
    wire [15:0] S_mode_word;
    wire [15:0] S_teach_cnt;
    wire [15:0] S_param_wr_cnt;
    wire [15:0] S_mode_commit_cnt;
    wire [7:0]  S_key4_evt;
    wire        S_teach_req;
    wire        S_key1_short;
    wire        S_key4_short;
    wire        S_key4_long;
    wire [25:0] S_mode_committed;     // CSI 域：相机帧首提交后的生效值
    wire [25:0] S_mode_echo;          // 像素域：提交回执
    wire        S_mode_echo_valid;
    // 提交字布局（26 位，见 mode_sync.v 头注释）：bit[3:0] edge_th_sel / bit[7:4] display_mode /
    // bit[11:8] game_mode / bit[15:12] recog_algo / bit[19:16] teach_cnt[3:0]。
    // 消费侧一律用这两个具名线网取位，别再手写下标——2026-09-14 就是把两段取反了。
    wire [3:0]  S_committed_display;
    wire [3:0]  S_committed_th_sel;
    wire [3:0]  S_committed_game;
    wire [3:0]  S_committed_algo;
    wire [3:0]  S_recog_algo;
    wire [25:0] S_mode_req;
    wire [15:0] S_mode_dbg;
    wire [7:0]  S_uart_byte;
    wire        S_uart_byte_valid;
    wire        S_cmd_we;
    wire [7:0]  S_cmd_addr;
    wire [15:0] S_cmd_data;

    // VIDEO_TAP 观测（CSI 域 → 像素域）：用 recog_top 的"每帧 toggle"做**整包捕获**，
    // 而不是逐位两级同步——数据在 toggle 之前就已经锁存稳定，捕获时一次搬整包
    //（tap 12 + 掩码 16 + 包围盒 14+12 + 追踪 11+10+1 + 手势字 40 = 116 位）；
    // 比逐位同步省几十个触发器，跨区走线也同比减少。
    wire [11:0] S_tap_px_shift;      // 每帧 tap 像素数 >>10（应为 900）
    wire [15:0] S_mask_cnt_shift;    // 掩码像素数 >>4
    wire [13:0] S_bbox_x;            // {x_min/16, x_max/16}
    wire [11:0] S_bbox_y;            // {y_min/16, y_max/16}
    wire        S_obs_toggle;
    reg  [1:0]  S_obs_sync;
    reg  [11:0] S_tap_px_hold;
    reg  [15:0] S_mask_cnt_hold;
    reg  [13:0] S_bbox_x_hold;
    reg  [11:0] S_bbox_y_hold;
    wire [10:0] S_trk_x;             // M1 追踪：平滑准星列（帧锁存）
    wire [9:0]  S_trk_y;             // M1 追踪：平滑准星行
    wire        S_trk_locked;        // M1 追踪：已锁定
    reg  [10:0] S_trk_x_hold;
    reg  [9:0]  S_trk_y_hold;
    reg         S_trk_locked_hold;
    wire [39:0] S_gest_word;          // M2.1 动态手势事件字（CSI 域，帧锁存）
    reg  [39:0] S_gest_word_hold;     // 像素域整包捕获值

    // CTRL_SYNC 插座：下行（像素域→CSI 域）与上行（CSI 域→像素域）
    wire [25:0] S_ctrl_down_rx_data;   // CSI 域
    wire        S_ctrl_down_rx_valid;
    wire [25:0] S_ctrl_up_tx_data;     // CSI 域
    wire        S_ctrl_up_tx_valid;
    wire [25:0] S_ctrl_up_rx_data;     // 像素域（回传结果）
    wire        S_ctrl_up_rx_valid;
    wire [15:0] S_ctrl_up_x;
    wire [15:0] S_ctrl_up_y;


    assign O_screen_pwm = 1'b1;
    assign S_video_out_vsync = ~S_hdmi_vsync;
	
	
    assign S_rst_n 		= S_pll_lock;
    assign S_hdmi_rst_n = S_pll_lock;

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n) begin
            S_video_out_vsync_ddr_1d <= 1'b0;
            S_video_out_vsync_ddr_2d <= 1'b0;
        end
        else begin
            S_video_out_vsync_ddr_1d <= S_video_out_vsync;
            S_video_out_vsync_ddr_2d <= S_video_out_vsync_ddr_1d;
        end
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_raw_seen <= 1'b0;
        else if(S_raw10_frame_start | S_axis_tvalid)
            S_dbg_raw_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_isp_seen <= 1'b0;
        else if(S_ISP_O_tuser | S_ISP_O_tvalid)
            S_dbg_isp_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_wr_seen <= 1'b0;
        else if(S_vi_ddr_wr_en)
            S_dbg_ddr_wr_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_rd_seen <= 1'b0;
        else if(S_ddr_user_rd_valid)
            S_dbg_ddr_rd_seen <= 1'b1;
    end

    always @(posedge S_24m_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_cam_cfg_seen <= 1'b0;
        else if(S_cam_cfg_done)
            S_dbg_cam_cfg_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_hs_seen <= 1'b0;
        else if(S_hs_rx_valid)
            S_dbg_hs_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_csi_seen <= 1'b0;
        else if(S_csi_frame_start | S_csi_valid)
            S_dbg_csi_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_raw10_seen <= 1'b0;
        else if(S_raw10_frame_start | S_raw10_valid)
            S_dbg_raw10_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_isp_fs_seen <= 1'b0;
        else if(S_ISP_O_tuser)
            S_dbg_isp_fs_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_isp_valid_seen <= 1'b0;
        else if(S_ISP_O_tvalid)
            S_dbg_isp_valid_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_req_seen <= 1'b0;
        else if(S_vi_ddr_wr_en)
            S_dbg_ddr_req_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_ddr_ready_seen <= 1'b0;
        else if(S_ddr_user_ready)
            S_dbg_ddr_ready_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_video_out_rst_n) begin
        if(!S_video_out_rst_n)
            S_dbg_rd_req_seen <= 1'b0;
        else if(S_video_out_vsync_ddr_2d)
            S_dbg_rd_req_seen <= 1'b0;
        else if(S_vo_ddr_rd_en)
            S_dbg_rd_req_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_video_out_rst_n) begin
        if(!S_video_out_rst_n)
            S_dbg_rd_valid_seen <= 1'b0;
        else if(S_video_out_vsync_ddr_2d)
            S_dbg_rd_valid_seen <= 1'b0;
        else if(S_ddr_user_rd_valid)
            S_dbg_rd_valid_seen <= 1'b1;
    end

    always @(posedge S_hdmi_pixel_clk or negedge S_video_out_rst_n) begin
        if(!S_video_out_rst_n)
            S_dbg_rd_nonzero_seen <= 1'b0;
        else if(S_video_out_vsync)
            S_dbg_rd_nonzero_seen <= 1'b0;
        else if(S_hdmi_window_rd_en && (S_video_rd_data != 24'd0))
            S_dbg_rd_nonzero_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_init_seen <= 1'b0;
        else if(S_init_calib_complete)
            S_dbg_mc_init_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_app_rdy_seen <= 1'b0;
        else if(S_mc_dbg_app_rdy)
            S_dbg_mc_app_rdy_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_wdf_rdy_seen <= 1'b0;
        else if(S_mc_dbg_wdf_rdy)
            S_dbg_mc_wdf_rdy_seen <= 1'b1;
    end

    always @(posedge S_ddr_clk or negedge S_rst_n) begin
        if(!S_rst_n)
            S_dbg_mc_cmd_pop_seen <= 1'b0;
        else if(S_mc_dbg_cmd_pop)
            S_dbg_mc_cmd_pop_seen <= 1'b1;
    end

    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n) begin
            S_dbg_edge_valid_seen <= 1'b0;
            S_dbg_edge_nonzero_seen <= 1'b0;
        end
        else begin
            if(S_edge_dbg_valid)
                S_dbg_edge_valid_seen <= 1'b1;
            if(S_edge_dbg_nonzero)
                S_dbg_edge_nonzero_seen <= 1'b1;
        end
    end

    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_dbg_cam_cfg_seen_sync <= 2'b00;
            S_dbg_hs_seen_sync      <= 2'b00;
            S_dbg_csi_seen_sync     <= 2'b00;
            S_dbg_raw10_seen_sync   <= 2'b00;
            S_dbg_raw_seen_sync    <= 2'b00;
            S_dbg_isp_seen_sync    <= 2'b00;
            S_dbg_ddr_wr_seen_sync <= 2'b00;
            S_dbg_ddr_rd_seen_sync <= 2'b00;
            S_dbg_isp_fs_seen_sync  <= 2'b00;
            S_dbg_isp_valid_seen_sync <= 2'b00;
            S_dbg_ddr_req_seen_sync <= 2'b00;
            S_dbg_ddr_ready_seen_sync <= 2'b00;
            S_dbg_video_nonzero_seen <= 1'b0;
            S_dbg_rd_req_seen_sync <= 2'b00;
            S_dbg_rd_valid_seen_sync <= 2'b00;
            S_dbg_rd_nonzero_seen_sync <= 2'b00;
            S_dbg_mc_init_seen_sync <= 2'b00;
            S_dbg_mc_app_rdy_seen_sync <= 2'b00;
            S_dbg_mc_wdf_rdy_seen_sync <= 2'b00;
            S_dbg_mc_cmd_pop_seen_sync <= 2'b00;
            S_dbg_alg_prev <= 1'b0;
            S_dbg_edge_valid_seen_sync <= 2'b00;
            S_dbg_edge_nonzero_seen_sync <= 2'b00;
        end
        else begin
            // 算法状态位用**已提交**值，与屏幕上实际在放的那一路一致
            S_dbg_alg_prev <= S_committed_display[0];
            if(S_committed_display[0] != S_dbg_alg_prev)
                S_dbg_video_nonzero_seen <= 1'b0;
            S_dbg_cam_cfg_seen_sync <= {S_dbg_cam_cfg_seen_sync[0], S_dbg_cam_cfg_seen};
            S_dbg_hs_seen_sync      <= {S_dbg_hs_seen_sync[0],      S_dbg_hs_seen};
            S_dbg_csi_seen_sync     <= {S_dbg_csi_seen_sync[0],     S_dbg_csi_seen};
            S_dbg_raw10_seen_sync   <= {S_dbg_raw10_seen_sync[0],   S_dbg_raw10_seen};
            S_dbg_raw_seen_sync    <= {S_dbg_raw_seen_sync[0],    S_dbg_raw_seen};
            S_dbg_isp_seen_sync    <= {S_dbg_isp_seen_sync[0],    S_dbg_isp_seen};
            S_dbg_ddr_wr_seen_sync <= {S_dbg_ddr_wr_seen_sync[0], S_dbg_ddr_wr_seen};
            S_dbg_ddr_rd_seen_sync <= {S_dbg_ddr_rd_seen_sync[0], S_dbg_ddr_rd_seen};
            S_dbg_isp_fs_seen_sync  <= {S_dbg_isp_fs_seen_sync[0],  S_dbg_isp_fs_seen};
            S_dbg_isp_valid_seen_sync <= {S_dbg_isp_valid_seen_sync[0], S_dbg_isp_valid_seen};
            S_dbg_ddr_req_seen_sync <= {S_dbg_ddr_req_seen_sync[0], S_dbg_ddr_req_seen};
            S_dbg_ddr_ready_seen_sync <= {S_dbg_ddr_ready_seen_sync[0], S_dbg_ddr_ready_seen};
            S_dbg_rd_req_seen_sync <= {S_dbg_rd_req_seen_sync[0], S_dbg_rd_req_seen};
            S_dbg_rd_valid_seen_sync <= {S_dbg_rd_valid_seen_sync[0], S_dbg_rd_valid_seen};
            S_dbg_rd_nonzero_seen_sync <= {S_dbg_rd_nonzero_seen_sync[0], S_dbg_rd_nonzero_seen};
            S_dbg_mc_init_seen_sync <= {S_dbg_mc_init_seen_sync[0], S_dbg_mc_init_seen};
            S_dbg_mc_app_rdy_seen_sync <= {S_dbg_mc_app_rdy_seen_sync[0], S_dbg_mc_app_rdy_seen};
            S_dbg_mc_wdf_rdy_seen_sync <= {S_dbg_mc_wdf_rdy_seen_sync[0], S_dbg_mc_wdf_rdy_seen};
            S_dbg_mc_cmd_pop_seen_sync <= {S_dbg_mc_cmd_pop_seen_sync[0], S_dbg_mc_cmd_pop_seen};
            S_dbg_edge_valid_seen_sync <= {S_dbg_edge_valid_seen_sync[0], S_dbg_edge_valid_seen};
            S_dbg_edge_nonzero_seen_sync <= {S_dbg_edge_nonzero_seen_sync[0], S_dbg_edge_nonzero_seen};
            if(S_hdmi_window_rd_en && (S_video_rd_data != 24'd0))
                S_dbg_video_nonzero_seen <= 1'b1;
        end
    end

    // M0 起算法选择由模式寄存器决定（见 mode_sync 的帧首提交），不再从 24M 域的
    // 按键电平直接过采样过来。这里只把 VIDEO_TAP 的帧锁存观测"整包捕获"到像素域。
    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_obs_sync      <= 2'b00;
            S_tap_px_hold   <= 12'd0;
            S_mask_cnt_hold <= 16'd0;
            S_bbox_x_hold   <= 14'd0;
            S_bbox_y_hold   <= 12'd0;
            S_trk_x_hold    <= 11'd0;
            S_trk_y_hold    <= 10'd0;
            S_trk_locked_hold <= 1'b0;
            S_gest_word_hold <= 40'd0;
        end
        else begin
            // 两级同步 + 边沿检测：toggle 稳定后再一次性把整包数据搬进 hold
            S_obs_sync <= {S_obs_sync[0], S_obs_toggle};
            if(S_obs_sync[0] ^ S_obs_sync[1]) begin
                S_tap_px_hold   <= S_tap_px_shift;
                S_mask_cnt_hold <= S_mask_cnt_shift;
                S_bbox_x_hold   <= S_bbox_x;
                S_bbox_y_hold   <= S_bbox_y;
                S_trk_x_hold    <= S_trk_x;
                S_trk_y_hold    <= S_trk_y;
                S_trk_locked_hold <= S_trk_locked;
                S_gest_word_hold <= S_gest_word;
            end
        end
    end

    // A/G（曝光/增益）来自 24 MHz 域，先在像素域打一拍再送 logger：
    //   ① 24m→像素域那条 set_max_delay 5.000 是**真实生效**的约束（这两个时钟在 SDC 里
    //      属于同一个异步组，组内路径照常算），如果不打这一拍，路径会一直穿到 logger 的
    //      模板组合逻辑里——M0 把行模板从 96 字节加长到 152 字节后，这条路径实测 4.668 ns，
    //      slack 只剩 0.268 ns，成了全设计最差 setup；
    //   ② 打一拍后这条跨域路径只剩 FF→FF，模板逻辑落到像素域自己的 13.3 ns 预算里。
    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_ae_px <= 16'd0;
            S_ag_px <= 16'd0;
        end
        else begin
            S_ae_px <= S_ae;
            S_ag_px <= S_ag;
        end
    end

    assign S_lane_error_any = |S_lane_error;

    assign S_vo_dbg_fifo_rst = 1'b0;
    assign S_vo_dbg_ddr_rd_valid = 1'b0;
    assign S_vo_dbg_fifo_rd_en = 1'b0;
    assign S_vo_dbg_fifo_empty = 1'b0;
    assign S_mc_dbg_fifo_afull = ~S_ddr_user_ready;
    assign S_mc_dbg_app_rdy = S_mc_app_rdy;
    assign S_mc_dbg_wdf_rdy = S_mc_app_wdf_rdy;
    assign S_mc_dbg_cmd_pop = S_mc_app_en;

    // mixer 的 I_debug_status：bit0 = **已提交的** display_mode（0=RAW, 1=EDGE），
    // bit1 = **已提交的** game_mode（显示 GES）。用提交值而不是请求值，理由同上。
    // 屏幕上真正在放的那一路——2026-09-14 位序取反那次，字样变了画面没变，正是这两者
    // 不一致造成的误导。
    assign S_hdmi_debug_status = {2'b00, S_committed_game[0], S_committed_display[0]};

    assign S_debug_status_bus = {
        S_dbg_mc_init_seen_sync[1],
        S_dbg_mc_app_rdy_seen_sync[1],
        S_dbg_mc_wdf_rdy_seen_sync[1],
        S_dbg_mc_cmd_pop_seen_sync[1],
        S_dbg_ddr_rd_seen_sync[1],
        S_dbg_ddr_wr_seen_sync[1],
        S_dbg_ddr_ready_seen_sync[1],
        S_dbg_ddr_req_seen_sync[1],
        S_dbg_isp_valid_seen_sync[1],
        S_dbg_isp_fs_seen_sync[1],
        S_dbg_isp_seen_sync[1],
        S_dbg_raw_seen_sync[1],
        S_dbg_raw10_seen_sync[1],
        S_dbg_csi_seen_sync[1],
        S_dbg_hs_seen_sync[1],
        S_dbg_cam_cfg_seen_sync[1],
        S_dbg_edge_valid_seen_sync[1],
        S_dbg_edge_nonzero_seen_sync[1],
        S_dbg_rd_nonzero_seen_sync[1],
        S_dbg_video_nonzero_seen,
        S_committed_display[0],
        S_hdmi_out_de,
        S_hdmi_de,
        S_hdmi_window_rd_en
    };

    assign S_video_max_ch =
        (S_video_rd_data[23:16] > S_video_rd_data[15:8]) ?
            ((S_video_rd_data[23:16] > S_video_rd_data[7:0]) ?
                S_video_rd_data[23:16] : S_video_rd_data[7:0]) :
            ((S_video_rd_data[15:8] > S_video_rd_data[7:0]) ?
                S_video_rd_data[15:8] : S_video_rd_data[7:0]);

    wire [9:0] S_raw_max_01 =
        (S_raw_tdata[9:0] > S_raw_tdata[19:10]) ?
            S_raw_tdata[9:0] : S_raw_tdata[19:10];
    wire [9:0] S_raw_max_23 =
        (S_raw_tdata[29:20] > S_raw_tdata[39:30]) ?
            S_raw_tdata[29:20] : S_raw_tdata[39:30];
    wire [9:0] S_raw_max =
        (S_raw_max_01 > S_raw_max_23) ? S_raw_max_01 : S_raw_max_23;
    always @(posedge S_csi_rx_clk or negedge S_rst_n) begin
        if(!S_rst_n) begin
            S_dbg_raw_max_px   <= 10'd0;
            S_dbg_raw_max_hold <= 10'd0;
        end
        else if(S_raw_tuser) begin
            // 相机帧首：先把上一完整帧的峰值搬进 hold，再清零重算
            S_dbg_raw_max_hold <= S_dbg_raw_max_px;
            S_dbg_raw_max_px   <= 10'd0;
        end
        else if(S_raw_tvalid && (S_raw_max > S_dbg_raw_max_px))
            S_dbg_raw_max_px <= S_raw_max;
    end

    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_dbg_raw_max_sync1 <= 10'd0;
            S_dbg_raw_max_sync2 <= 10'd0;
        end
        else begin
            S_dbg_raw_max_sync1 <= S_dbg_raw_max_hold;
            S_dbg_raw_max_sync2 <= S_dbg_raw_max_sync1;
        end
    end

    // FIFO 拥塞观测：两级同步 → 帧内峰值 → 帧首换帧（丢写次数取 16 位差值，跨回绕安全）
    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_fifo_in_drop_s1    <= 16'd0;  S_fifo_in_drop_s2    <= 16'd0;
            S_fifo_out_drop_s1   <= 16'd0;  S_fifo_out_drop_s2   <= 16'd0;
            S_fifo_in_used_s1    <= 9'd0;   S_fifo_in_used_s2    <= 9'd0;
            S_fifo_out_used_s1   <= 9'd0;   S_fifo_out_used_s2   <= 9'd0;
            S_fifo_in_drop_prev  <= 16'd0;  S_fifo_out_drop_prev <= 16'd0;
            S_dbg_fifo_in_drop   <= 16'd0;  S_dbg_fifo_out_drop  <= 16'd0;
            S_dbg_fifo_in_used   <= 9'd0;   S_dbg_fifo_out_used  <= 9'd0;
            S_fifo_in_used_max   <= 9'd0;   S_fifo_out_used_max  <= 9'd0;
        end
        else begin
            S_fifo_in_drop_s1    <= S_fifo_in_drop_raw;
            S_fifo_in_drop_s2    <= S_fifo_in_drop_s1;
            S_fifo_out_drop_s1   <= S_fifo_out_drop_raw;
            S_fifo_out_drop_s2   <= S_fifo_out_drop_s1;
            S_fifo_in_used_s1    <= S_fifo_in_used_raw;
            S_fifo_in_used_s2    <= S_fifo_in_used_s1;
            S_fifo_out_used_s1   <= S_fifo_out_used_raw;
            S_fifo_out_used_s2   <= S_fifo_out_used_s1;

            if(S_fifo_in_used_s2 > S_fifo_in_used_max)
                S_fifo_in_used_max <= S_fifo_in_used_s2;
            if(S_fifo_out_used_s2 > S_fifo_out_used_max)
                S_fifo_out_used_max <= S_fifo_out_used_s2;

            if(S_hdmi_user && !S_hdmi_user_1d) begin
                S_dbg_fifo_in_drop   <= S_fifo_in_drop_s2  - S_fifo_in_drop_prev;
                S_dbg_fifo_out_drop  <= S_fifo_out_drop_s2 - S_fifo_out_drop_prev;
                S_fifo_in_drop_prev  <= S_fifo_in_drop_s2;
                S_fifo_out_drop_prev <= S_fifo_out_drop_s2;
                S_dbg_fifo_in_used   <= S_fifo_in_used_max;
                S_dbg_fifo_out_used  <= S_fifo_out_used_max;
                S_fifo_in_used_max   <= S_fifo_in_used_s2;
                S_fifo_out_used_max  <= S_fifo_out_used_s2;
            end
        end
    end

    always @(posedge S_hdmi_pixel_clk or negedge S_hdmi_rst_n) begin
        if(!S_hdmi_rst_n) begin
            S_hdmi_user_1d <= 1'b0;
            S_frame_cnt_dbg <= 16'd0;
            S_dbg_nonzero_px <= 20'd0;
            S_dbg_bright_px <= 20'd0;
            S_dbg_very_px <= 20'd0;
            S_dbg_max_px <= 8'd0;
            S_dbg_nonzero_hold <= 20'd0;
            S_dbg_bright_hold <= 20'd0;
            S_dbg_very_hold <= 20'd0;
            S_dbg_max_hold <= 8'd0;
        end
        else begin
            S_hdmi_user_1d <= S_hdmi_user;
            if(S_hdmi_user && !S_hdmi_user_1d) begin
                S_frame_cnt_dbg <= S_frame_cnt_dbg + 1'b1;
                // 帧首：计数器里是上一帧的完整统计，先锁存再清零
                S_dbg_nonzero_hold <= S_dbg_nonzero_px;
                S_dbg_bright_hold  <= S_dbg_bright_px;
                S_dbg_very_hold    <= S_dbg_very_px;
                S_dbg_max_hold     <= S_dbg_max_px;
            end
            if(S_hdmi_user) begin
                S_dbg_nonzero_px <= 20'd0;
                S_dbg_bright_px <= 20'd0;
                S_dbg_very_px <= 20'd0;
                S_dbg_max_px <= 8'd0;
            end
            else if(S_hdmi_window_rd_en) begin
                if(S_video_rd_data != 24'd0)
                    S_dbg_nonzero_px <= S_dbg_nonzero_px + 1'b1;
                if(S_video_max_ch >= 8'd64)
                    S_dbg_bright_px <= S_dbg_bright_px + 1'b1;
                if(S_video_max_ch >= 8'd128)
                    S_dbg_very_px <= S_dbg_very_px + 1'b1;
                if(S_video_max_ch > S_dbg_max_px)
                    S_dbg_max_px <= S_video_max_ch;
            end
        end
    end
	
	assign O_cam_rst 	= 1'b1;
    assign O_cam_24m 	= S_24m_clk;
	
	
	
	
    PLL u_PLL(
        .refclk      ( I_sys_clk         ),
        .reset    	 ( ~I_rst_n          ),
        
        .clk0_out    ( S_100m_clk        ),
        .clk1_out    ( S_24m_clk         ),

        .clk4_out    ( S_hdmi_pixel_clk  ),
        .clk5_out    ( S_hdmi_serial_clk ),

        .lock        ( S_pll_lock        )

    );


	

  
  ae_set u_ae_set (
      .I_clk(S_24m_clk),
      .I_rst(~S_rst_n),
      // 曝光调节：KEY2(A9) 降低曝光，KEY3(B9) 提高曝光
      .I_btn({2'b11, I_button[2], I_button[0]}),
      .I_cam_cfg_done(S_cam_cfg_done),
      .I_ae_cfg_done(S_ae_cfg_done),
      .O_ae_req(S_ae_req),
      .O_ae(S_ae),
      .O_ag(S_ag)
  );

  // ===========================================================================
  // 手势游戏 M0 基础设施：按键事件 → 参数寄存器 → 帧首提交 / 四个插座
  // ===========================================================================
  // KEY1（D5）：短按切 RAW/EDGE——M0 起也走模式寄存器，与 KEY4 同一条路，
  //   于是切换在相机帧首生效（README 第 5 节记的"切换瞬间短暂撕裂"随之消失）。
  // KEY4（C7）：短按开关游戏层，长按发一次一键示教请求。
  // KEY1 只需要短按：HAS_LONG=0 让长按计数器整块不生成（省 27 FF 与比较器）
  key_event #(.CLK_HZ(75000000), .DEBOUNCE_MS(20), .LONG_MS(1000), .HAS_LONG(0)) u_key1_event (
      .I_clk  ( S_hdmi_pixel_clk ),
      .I_rst_n( S_hdmi_rst_n     ),
      .I_key  ( I_button[1]      ),
      .O_short( S_key1_short     ),
      .O_long (                  ),
      .O_level(                  )
  );

  key_event #(.CLK_HZ(75000000), .DEBOUNCE_MS(20), .LONG_MS(1000)) u_key4_event (
      .I_clk  ( S_hdmi_pixel_clk ),
      .I_rst_n( S_hdmi_rst_n     ),
      .I_key  ( I_button[3]      ),
      .O_short( S_key4_short     ),
      .O_long ( S_key4_long      ),
      .O_level(                  )
  );

  // 显示帧同步脉冲（帧首 1 拍）：LED 的心跳与事件闪烁都从它派生，
  // 比另开 25 位分频计数器省 30 多个触发器。
  wire S_frame_strobe = S_hdmi_user & ~S_hdmi_user_1d;

  // PARAM_BUS：UART 命令 + 按键事件 + 拨码开关 → 参数寄存器（像素域唯一写口）
  uart_rx #(.CLK_HZ(75000000), .BAUD(115200)) u_uart_rx (
      .I_clk  ( S_hdmi_pixel_clk ),
      .I_rst_n( S_hdmi_rst_n     ),
      .I_rx   ( I_uart_rx        ),
      .O_data ( S_uart_byte      ),
      .O_valid( S_uart_byte_valid)
  );

  uart_cmd u_uart_cmd (
      .I_clk        ( S_hdmi_pixel_clk ),
      .I_rst_n      ( S_hdmi_rst_n     ),
      .I_byte       ( S_uart_byte      ),
      .I_byte_valid ( S_uart_byte_valid),
      .O_we         ( S_cmd_we         ),
      .O_addr       ( S_cmd_addr       ),
      .O_data       ( S_cmd_data       )
  );

  // B 段（0x80~0xBF）转发与回读（M4a 接通，C 集成）
  wire        S_param_b_we;
  wire [5:0]  S_param_b_addr;
  wire [15:0] S_param_b_wdata;
  wire [15:0] S_param_b_rd_data;
  wire [7:0]  S_param_rd_addr = 8'h00;   // 回读地址暂无消费者，保留通路

  param_ctrl #(.CLK_HZ(75000000), .SW_DEBOUNCE_MS(20)) u_param_ctrl (
      .I_clk           ( S_hdmi_pixel_clk ),
      .I_rst_n         ( S_hdmi_rst_n     ),
      .I_key1_short    ( S_key1_short     ),
      .I_key4_short    ( S_key4_short     ),
      .I_key4_long     ( S_key4_long      ),
      .I_frame_strobe  ( S_frame_strobe   ),
      .I_sw_raw        ( I_switch         ),
      .I_ext_we        ( S_cmd_we         ),
      .I_ext_addr      ( S_cmd_addr       ),
      .I_ext_data      ( S_cmd_data       ),
      .I_commit_pulse  ( S_mode_echo_valid),
      .I_rd_addr       ( S_param_rd_addr  ),
      .O_rd_data       (                  ),
      .O_display_mode  ( S_display_mode   ),
      .O_game_mode     ( S_game_mode      ),
      .O_recog_algo    ( S_recog_algo     ),
      .O_edge_th_sel   ( S_edge_th_sel    ),
      .O_edge_th       ( S_edge_th        ),
      .O_teach_cnt     ( S_teach_cnt      ),
      .O_param_wr_cnt  ( S_param_wr_cnt   ),
      .O_mode_commit_cnt( S_mode_commit_cnt),
      .O_key4_evt      ( S_key4_evt       ),
      .O_teach_req     ( S_teach_req      ),
      .O_mode_word     ( S_mode_word      ),
      .O_led           ( O_led            ),
      // B 段转发（写 0x80~0xBF → game_top；回读按段选通）
      .O_b_we          ( S_param_b_we     ),
      .O_b_addr        ( S_param_b_addr   ),
      .O_b_wdata       ( S_param_b_wdata  ),
      .I_b_rd_data     ( S_param_b_rd_data)
  );

  // 模式寄存器 → CSI 域：挂在相机帧首提交（I_frame_start = ISP 输出 tuser）
  mode_sync u_mode_sync (
      .I_req_clk    ( S_hdmi_pixel_clk        ),
      .I_req_rst_n  ( S_hdmi_rst_n            ),
      .I_req_data   ( S_mode_req             ),
      .O_echo_data  ( S_mode_echo             ),
      .O_echo_valid ( S_mode_echo_valid       ),
      .I_ack_clk    ( S_csi_rx_clk            ),
      .I_ack_rst_n  ( S_rst_n                 ),
      .I_frame_start( S_ISP_O_tuser           ),
      .O_committed  ( S_mode_committed        ),
      .O_commit_pulse(                        )
  );

  // 提交字拆位（布局见 mode_sync.v 头注释）：一律用具名线网，别手写下标——M0 踩过位序取反。
  // ⚠ 域归属（2026-09-17 修正 M0 的一处跨域隐患）：
  //   * CSI 域（isp_top 的 alg mux、边缘门限）用 **S_csi_*** —— 与 mode_sync 的提交寄存器同域，直接用；
  //   * 像素域（OSD 状态字、DBG 的 K、LED）必须用 **S_committed_*** —— 它们来自 mode_sync 的**回执**
  //     （CSI 域经 ctrl_sync 的 toggle 握手 + 两级同步送回来的），不能直接采 CSI 域的寄存器。
  wire [3:0] S_csi_display = S_mode_committed[7:4];
  wire [3:0] S_csi_th_sel  = S_mode_committed[3:0];
  assign S_committed_display = S_mode_echo[7:4];
  assign S_committed_th_sel  = S_mode_echo[3:0];
  assign S_committed_game    = S_mode_echo[11:8];
  assign S_committed_algo    = S_mode_echo[15:12];

  // 请求字（像素域 → CSI 域）：**算法类**字段走这一条，相机帧首一起提交；
  // 系数类（A 的肤色上下限/运动阈值/quiet_th）不跨域，由 CSI 域的示教逻辑自己产生并保存。
  assign S_mode_req = {6'b0, S_teach_cnt[3:0], S_recog_algo, S_game_mode, S_display_mode, S_edge_th_sel};

  // DBG 的 K 字段显示**已提交**值（由 CSI 域回执证明跨域成功），不是请求值
  assign S_mode_dbg = {4'h0, S_committed_algo, S_committed_game, S_committed_display};

  // CSI 域实际生效的边缘门限：TH = 16 + 4×档位
  wire [10:0] S_edge_th_csi = 11'd16 + ({7'b0, S_csi_th_sel} << 2);

  // CTRL_SYNC 插座：下行（像素域 → CSI 域）与上行（CSI 域 → 像素域）各一条。
  // M0 的下行由 game_top 每帧发测试常数、上行由 recog_top 原样回传，用来验证双向往返。
  wire [25:0] S_ctrl_down_data;
  wire        S_ctrl_down_valid;

  ctrl_sync u_ctrl_down (
      .I_tx_clk  ( S_hdmi_pixel_clk   ),
      .I_tx_rst_n( S_hdmi_rst_n       ),
      .I_tx_valid( S_ctrl_down_valid  ),
      .I_tx_data ( S_ctrl_down_data   ),
      .I_rx_clk  ( S_csi_rx_clk       ),
      .I_rx_rst_n( S_rst_n            ),
      .O_rx_data ( S_ctrl_down_rx_data),
      .O_rx_valid( S_ctrl_down_rx_valid)
  );

  ctrl_sync u_ctrl_up (
      .I_tx_clk  ( S_csi_rx_clk       ),
      .I_tx_rst_n( S_rst_n            ),
      .I_tx_valid( S_ctrl_up_tx_valid ),
      .I_tx_data ( S_ctrl_up_tx_data  ),
      .I_rx_clk  ( S_hdmi_pixel_clk   ),
      .I_rx_rst_n( S_hdmi_rst_n       ),
      .O_rx_data ( S_ctrl_up_rx_data  ),
      .O_rx_valid( S_ctrl_up_rx_valid )
  );

  assign S_ctrl_up_x = {5'b0, S_ctrl_up_rx_data[25:15]};
  assign S_ctrl_up_y = {5'b0, S_ctrl_up_rx_data[14:4]};

  // 蜂鸣器低电平响：M0 不发声（碰撞音效在 M4c 才用），保持高电平。
  assign O_buzzer = 1'b1;
  
    uicfgcs500 #(
      .CLK_DIV(24000000 / 100000 - 1)
  ) u_uicfgcs500 (
      .I_clk(S_24m_clk),  //系统时钟输入
      .I_rst_n(S_rst_n),  //系统复位输入
      .I_ae_req(S_ae_req),
      .I_ae(S_ae),
      .I_ag(S_ag),
      .O_cam_scl(O_cam_scl),  //I2C总线，SCL时钟
      .IO_cam_sda(IO_cam_sda),  //I2C总线，SDA数据
      .O_cfg_done(S_cam_cfg_done),  //摄像头寄存器初始化完成
      .O_ae_cfg_done(S_ae_cfg_done)  //AE配置完成
  );
	
    mipi_dphy_rx_ph1p_mipiio_wrapper#(
        .DPHY_RX_LOCATION      ( "DPHY0" ),
        .HS_EQUALIZER          ( "0dB"   ),//"0dB","1.5dB","3dB","4.5dB","6dB","7.5dB","9dB","10.5dB"
        .HS_VGA_GAIN           ( "8dB" ),//"-3dB","-1.5dB","0dB","1.5dB","3dB","4.5dB","6dB","7.5dB"
        .LANE_NUM              ( 2       ),
        .BYTE_NUM              ( 1       )
    )u_mipi_dphy_rx_ph1p_mipiio_wrapper(
        .I_lp_clk              ( S_100m_clk       ),
        .I_rst                 ( ~S_rst_n         ),

        .I_clk_lane_in_delay   ( 6'd0             ),
        .I_data_lane0_in_delay ( 6'd0             ),
        .I_data_lane1_in_delay ( 6'd0             ),
        .I_data_lane2_in_delay ( 6'd0             ),
        .I_data_lane3_in_delay ( 6'd0             ),

        .I_lane_invert         ( 4'b0000          ),
     
        .O_hs_rx_clk           ( S_csi_rx_clk     ),
        .O_hs_rx_valid         ( S_hs_rx_valid    ),
        .O_hs_rx_data          ( S_hs_rx_data     ),
      
        .O_lp_rx_lane0_p       (  ),
        .O_lp_rx_lane0_n       (  ),
      
        .I_lp_tx_en            ( 1'b0             ),
        .I_lp_tx_lane0_p       ( 1'b1             ),
        .I_lp_tx_lane0_n       ( 1'b1             ),
      
        .O_lane_match_error    (                  ),
        .O_lane_error          ( S_lane_error     ),
      
        .IO_rx_clk_pad_n       ( IO_rx_clk_pad_n  ),
        .IO_rx_clk_pad_p       ( IO_rx_clk_pad_p  ),
        .IO_rx_data_pad_n      ( IO_rx_data_pad_n ),
        .IO_rx_data_pad_p      ( IO_rx_data_pad_p )
    );
	
	
 //  cwc cwc_inst
 //(
 //    .probe0(S_hs_rx_valid),
 //    .probe1(S_hs_rx_data),
 //    .probe2(S_lane_error),
 //    .clk(S_csi_rx_clk)
 //);

 //csi 解码为RAW数据
csi_unpacket_2lane u_csi_unpacket(
.I_clk                 ( S_csi_rx_clk       ),
.I_rst_n               ( S_rst_n        	),
.I_hs_valid            ( S_hs_rx_valid     ),
.I_hs_data             ( S_hs_rx_data      ),

.O_csi_frame_start     ( S_csi_frame_start ),
.O_csi_frame_end       ( S_csi_frame_end   ),
.O_csi_valid           ( S_csi_valid       ),
.O_csi_data            ( S_csi_data        )
);


//解码为RAW8
raw10_unpacket_2lane u_raw10_unpacket (
.I_clk  (S_csi_rx_clk),
.I_rst_n(S_rst_n),

.I_csi_frame_start(S_csi_frame_start),
.I_csi_frame_end  (S_csi_frame_end),
.I_csi_valid      (S_csi_valid),
.I_csi_data       (S_csi_data),

.O_raw10_frame_start(S_raw10_frame_start),
.O_raw10_frame_end  (S_raw10_frame_end),
.O_raw10_valid      (S_raw10_valid),
.O_raw10_data       (S_raw10_data)
  );


//将数据转为stream流
uial2axis #(
.IMG_WIDTH(1280),
.IMG_HEIGHT(720),
.INPUT_DATA_WIDTH(40)
) 
u_uial2axis (
.I_native_clk(S_csi_rx_clk),
.I_rst_n     (S_rst_n),
.I_data      (S_raw10_data       ),
.I_data_valid(S_raw10_valid      ),
.I_data_start(S_raw10_frame_start),
.I_data_end  (S_raw10_frame_end  ),
.axis_tvalid (S_axis_tvalid),
.axis_tdata  (S_axis_tdata ),
.axis_tuser  (S_axis_tuser ),
.axis_tlast  (S_axis_tlast )
);
	

image_correction #(
    .DATA_WIDTH(40)
)(
    .I_clk   		(S_csi_rx_clk),
    .I_rst_n 		(S_rst_n),
					
    .I_raw_data 	(S_axis_tdata),
    .I_raw_frame_end 	(S_axis_tlast),
    .I_raw_valid	(S_axis_tvalid),
    .I_raw_frame_start 	(S_axis_tuser),
					
    .O_raw_tdata 	(S_raw_tdata ),
    .O_raw_tlast 	(S_raw_tlast ),
    .O_raw_tvalid	(S_raw_tvalid),
    .O_raw_tuser 	(S_raw_tuser )
);


//cwc1 cwc1_Inst
//  (
//      .probe0(S_axis_tuser),
//      .probe1(S_axis_tvalid),
//      .probe2(S_axis_tlast),
//      .probe3(S_axis_tdata),
//      .probe4(S_ISP_O_tuser),
//      .probe5(S_ISP_O_tvalid),
//      .probe6(S_ISP_O_tlast),
//      .probe7(S_ISP_O_tdata),
//      .probe8 (S_raw_tdata ),
//      .probe9 (S_raw_tlast ),
//      .probe10(S_raw_tvalid),
//      .probe11(S_raw_tuser ),
//      .clk(S_csi_rx_clk)
//  );


//ISP算法顶层模块
isp_top u_isp_top (
.axi4s_video_aclk(S_csi_rx_clk),
.I_rst_n         (S_rst_n),
.I_alg_sel       (S_csi_display[0]),
.I_edge_th       (S_edge_th_csi),
.I_mode_committed(S_mode_committed),
.I_tlast         (S_raw_tlast	),
.I_tuser         (S_raw_tuser	),
.I_tdata         (S_raw_tdata	),
.I_tvalid        (S_raw_tvalid	),
.I_tdest         (),
.O_tready        (S_ISP_O_tready),
.O_tdata         (S_ISP_O_tdata ),
.O_tlast         (S_ISP_O_tlast ),
.O_tuser         (S_ISP_O_tuser ),
.O_tvalid        (S_ISP_O_tvalid),
.I_tready        (),
.O_edge_dbg_valid (S_edge_dbg_valid),
.O_edge_dbg_nonzero (S_edge_dbg_nonzero),
.I_ctrl_rx_data  (S_ctrl_down_rx_data),
.I_ctrl_rx_valid (S_ctrl_down_rx_valid),
.O_ctrl_tx_data  (S_ctrl_up_tx_data),
.O_ctrl_tx_valid (S_ctrl_up_tx_valid),
.O_tap_px_shift  (S_tap_px_shift),
.O_mask_cnt_shift(S_mask_cnt_shift),
.O_bbox_x        (S_bbox_x),
.O_bbox_y        (S_bbox_y),
.O_status_toggle (S_obs_toggle),
.O_track_x       (S_trk_x),
.O_track_y       (S_trk_y),
.O_track_locked  (S_trk_locked),
.O_gest_word     (S_gest_word)
  );


    video_in u_video_in(
        .I_rst_n              (  S_rst_n             ),

        .I_camera_clk         ( S_csi_rx_clk          ),
        .I_camera_frame_start ( S_ISP_O_tuser  ),
        .I_camera_valid       ( S_ISP_O_tvalid ),
        .I_camera_data        ( S_ISP_O_tdata  ),
        .I_mipi_rx_error      ( 1'b0			      ),

        .I_ddr_clk            ( S_ddr_clk             ),
		.I_display_pause      ( 1'b0                  ),
        .I_video_out_rd_busy  ( S_video_out_rd_busy   ),
        .O_video_in_wr_busy   ( S_video_in_wr_busy    ),
        .O_video_out_rp       ( S_video_out_rp        ),

        .O_ddr_user_wr_en     ( S_vi_ddr_wr_en        ),
        .O_ddr_user_addr      ( S_vi_ddr_wr_addr      ),
        .O_ddr_user_wr_data   ( S_vi_ddr_wr_data      ),
        .I_ddr_user_ready     ( S_ddr_user_ready      ),
        .O_fifo_drop          ( S_fifo_in_drop_raw    ),
        .O_fifo_used          ( S_fifo_in_used_raw    )
    );



    assign S_ddr_user_wr_en    = S_vi_ddr_wr_en;

    assign S_ddr_user_rd_en    = S_vo_ddr_rd_en;

    assign S_ddr_user_addr     = S_vi_ddr_wr_en ? S_vi_ddr_wr_addr :
                                 S_vo_ddr_rd_en ? S_vo_ddr_rd_addr : 'd0;

    assign S_ddr_user_wr_data  = S_vi_ddr_wr_data;


    assign S_video_out_rst_n = S_hdmi_rst_n;

    video_out u_video_out(
        .I_rst_n             ( S_video_out_rst_n    ),
        .I_ddr_clk           ( S_ddr_clk            ),
 
        .O_video_out_rd_busy ( S_video_out_rd_busy  ),
        .I_video_in_wr_busy  ( S_video_in_wr_busy   ),
        .I_video_out_rp      ( S_video_out_rp       ),
 
        .O_ddr_user_rd_en    ( S_vo_ddr_rd_en       ),
        .O_ddr_user_addr     ( S_vo_ddr_rd_addr     ),
        .I_ddr_user_ready    ( S_ddr_user_ready     ),
        .I_ddr_user_rd_valid ( S_ddr_user_rd_valid  ),
        .I_ddr_user_rd_data  ( S_ddr_user_rd_data   ),

        .I_dsi_clk           ( S_hdmi_pixel_clk     ),
        .I_video_vsync       ( S_video_out_vsync    ),
        .I_video_rd_en       ( S_hdmi_window_rd_en  ),
        .O_vdieo_data        ( S_video_rd_data      ),
        .O_fifo_drop         ( S_fifo_out_drop_raw  ),
        .O_fifo_used         ( S_fifo_out_used_raw  )
    );



    mc_to_user_interface u_mc_to_user_interface(
        .I_clk                   ( S_ddr_clk               ),
        .I_rst_n                 ( S_rst_n                 ),

        .I_ddr_user_wr_en        ( S_ddr_user_wr_en        ),
        .I_ddr_user_rd_en        ( S_ddr_user_rd_en        ),
        .I_ddr_user_addr         ( S_ddr_user_addr         ),
        .I_ddr_user_wr_data      ( S_ddr_user_wr_data      ),
        .O_ddr_user_ready        ( S_ddr_user_ready        ),
        .O_ddr_user_rd_valid     ( S_ddr_user_rd_valid     ),
        .O_ddr_user_rd_data      ( S_ddr_user_rd_data      ),
            
        .O_mc_app_en             ( S_mc_app_en             ),
        .O_mc_app_addr           ( S_mc_app_addr           ),
        .O_mc_app_cmd            ( S_mc_app_cmd            ),
        .I_mc_app_rdy            ( S_mc_app_rdy            ),
        .O_mc_app_wdf_wren       ( S_mc_app_wdf_wren       ),
        .O_mc_app_wdf_data       ( S_mc_app_wdf_data       ),
        .O_mc_app_wdf_end        ( S_mc_app_wdf_end        ),
        .O_mc_app_wdf_mask       ( S_mc_app_wdf_mask       ),
        .I_mc_app_wdf_rdy        ( S_mc_app_wdf_rdy        ),
        .I_mc_app_rd_data        ( S_mc_app_rd_data        ),
        .I_mc_app_rd_data_end    ( S_mc_app_rd_data_end    ),
        .I_mc_app_rd_data_valid  ( S_mc_app_rd_data_valid  )
    );



    ph1p35_324_ddr_wrapper u_ph1p35_324_ddr_wrapper(
        .I_sys_clk              ( I_sys_clk              ),
        .I_sys_rst_n            ( S_rst_n                ),

        .O_ddr_clk              ( S_ddr_clk              ),
        .O_init_calib_complete  ( S_init_calib_complete  ),
        .I_mc_app_addr          ( S_mc_app_addr          ),
        .I_mc_app_cmd           ( S_mc_app_cmd           ),
        .I_mc_app_en            ( S_mc_app_en            ),
        .I_mc_app_wdf_data      ( S_mc_app_wdf_data      ),
        .I_mc_app_wdf_end       ( S_mc_app_wdf_end       ),
        .I_mc_app_wdf_mask      ( S_mc_app_wdf_mask      ),
        .I_mc_app_wdf_wren      ( S_mc_app_wdf_wren      ),
        .O_mc_app_rd_data       ( S_mc_app_rd_data       ),
        .O_mc_app_rd_data_end   ( S_mc_app_rd_data_end   ),
        .O_mc_app_rd_data_valid ( S_mc_app_rd_data_valid ),
        .O_mc_app_rdy           ( S_mc_app_rdy           ),
        .O_mc_app_wdf_rdy       ( S_mc_app_wdf_rdy       ),

        .ddr_addr               ( ddr_addr               ),
        .ddr_ba                 ( ddr_ba                 ),
        .ddr_cke                ( ddr_cke                ),
        .ddr_odt                ( ddr_odt                ),
        .ddr_cs_n               ( ddr_cs_n               ),
        .ddr_ras_n              ( ddr_ras_n              ),
        .ddr_cas_n              ( ddr_cas_n              ),
        .ddr_we_n               ( ddr_we_n               ),
        .ddr_ck_p               ( ddr_ck_p               ),
        .ddr_ck_n               ( ddr_ck_n               ),
        .ddr_dm                 ( ddr_dm                 ),
        .ddr_dq                 ( ddr_dq                 ),
        .ddr_dqs_p              ( ddr_dqs_p              ),
        .ddr_dqs_n              ( ddr_dqs_n              )
    );



    uivtc #(
        .H_ActiveSize ( 1280 ),
        .H_FrameSize  ( 1650 ),
        .H_SyncStart  ( 1390 ),
        .H_SyncEnd    ( 1430 ),
        .V_ActiveSize ( 720  ),
        .V_FrameSize  ( 750  ),
        .V_SyncStart  ( 725  ),
        .V_SyncEnd    ( 730  )
    )u_hdmi_vtc(
        .I_vtc_rstn    ( S_hdmi_rst_n    ),
        .I_vtc_clk     ( S_hdmi_pixel_clk ),
        .O_vtc_vs      ( S_hdmi_vsync     ),
        .O_vtc_hs      ( S_hdmi_hsync     ),
        .O_vtc_de_valid( S_hdmi_de        ),
        .O_vtc_user    ( S_hdmi_user      ),
        .O_vtc_last    ( S_hdmi_last      )
    );

    // ---- RENDER_SLOT：DDR 读回 → 游戏层 → OSD/Logo 层 → HDMI ------------------
    // 边界是 0 拍组合（见 game_top 头注释）：mixer 内部用 S_x_2d/S_y_2d 判 OSD 位置，
    // 这里若插一拍寄存器，OSD 就会相对画面错开一个像素。
    // M0 的 game_top 还是空壳（像素直通），旁路开关与 CTRL_SYNC 下行已经就位。
    wire [23:0] S_game_pixel_out;

    game_top u_game_top (
        .I_clk          ( S_hdmi_pixel_clk  ),
        .I_rst_n        ( S_hdmi_rst_n      ),
        .I_vsync        ( S_hdmi_vsync      ),
        .I_de           ( S_hdmi_de         ),
        .I_pixel_in     ( S_video_rd_data   ),
        .I_bypass       ( S_game_mode == 4'd0 ),
        .I_game_mode    ( S_game_mode       ),
        .I_display_mode ( S_display_mode    ),
        .O_pixel_out    ( S_game_pixel_out  ),
        .O_ctrl_tx_data ( S_ctrl_down_data  ),
        .O_ctrl_tx_valid( S_ctrl_down_valid ),
        // C 集成：B 段参数（param_ctrl 转发）与 A 的质心（VIDEO_TAP 扩展，帧锁存）
        .I_param_we     ( S_param_b_we      ),
        .I_param_addr   ( S_param_b_addr    ),
        .I_param_wdata  ( S_param_b_wdata   ),
        .I_param_rd_addr( S_param_rd_addr   ),
        .O_param_rd_data( S_param_b_rd_data ),
        .I_ctrl_x       ( S_trk_x_hold      ),
        .I_ctrl_y       ( {1'b0, S_trk_y_hold} ),
        .I_ctrl_valid   ( S_trk_locked_hold ),
        .I_gest_word    ( S_gest_word_hold  )
    );

    hdmi_mixer #(
        .H_OFFSET   ( 0    ),
        .V_OFFSET   ( 0    ),
        .IMG_WIDTH  ( 1280 ),
        .IMG_HEIGHT ( 720  ),
        .DEBUG_MODE ( 0    )
    )u_hdmi_mixer(
        .I_clk           ( S_hdmi_pixel_clk   ),
        .I_rst_n         ( S_hdmi_rst_n       ),
        .I_video_vsync   ( S_hdmi_vsync       ),
        .I_video_hsync   ( S_hdmi_hsync       ),
        .I_video_de      ( S_hdmi_de          ),
        .I_video_user    ( S_hdmi_user        ),
        .I_video_last    ( S_hdmi_last        ),
        .I_debug_status  ( S_hdmi_debug_status),
        .O_video_rd_en   ( S_hdmi_window_rd_en),
        .I_video_rd_data ( S_game_pixel_out   ),
        .O_hdmi_vsync    ( S_hdmi_out_vsync   ),
        .O_hdmi_hsync    ( S_hdmi_out_hsync   ),
        .O_hdmi_de       ( S_hdmi_out_de      ),
        .O_hdmi_data     ( S_hdmi_out_data    )
    );

    hdmi_tx u_hdmi_tx(
        .I_pixel_clk        ( S_hdmi_pixel_clk  ),
        .I_serial_clk       ( S_hdmi_serial_clk ),
        .I_rst              ( ~S_hdmi_rst_n     ),
        .I_key_in           ( 1'b0              ),
        .I_edid_read_trig   ( 1'b0              ),
        .O_edid_read_valid  (                   ),
        .O_edid_read_data   (                   ),
        .I_video_rgb_enable ( 1'b1              ),
        .I_video_in_vs      ( S_hdmi_out_vsync  ),
        .I_video_in_de      ( S_hdmi_out_de     ),
        .I_video_in_user    ( 1'b0              ),
        .I_video_in_valid   ( 1'b0              ),
        .I_video_in_last    ( 1'b0              ),
        .O_video_in_ready   (                   ),
        .I_video_in_data    ( S_hdmi_out_data   ),
        .I_audio_valid      ( 1'b0              ),
        .I_audio_left_data  ( 24'd0             ),
        .I_audio_right_data ( 24'd0             ),
        .I_i2s_BCLK         ( 1'b0              ),
        .I_i2s_LRCK         ( 1'b0              ),
        .I_i2s_DOUT         ( 1'b0              ),
        .O_ddc_scl          (                   ),
        .O_hdmi_clk_p       (                   ),
        .O_hdmi_tx_p        (                   ),
        .O_tmds_ch0_p       ( O_tmds_ch0_p      ),
        .O_tmds_ch1_p       ( O_tmds_ch1_p      ),
        .O_tmds_ch2_p       ( O_tmds_ch2_p      ),
        .O_tmds_clk_p       ( O_tmds_clk_p      )
    );

    debug_uart_logger #(
        .CLK_HZ         ( 75000000 ),
        .BAUD           ( 115200   ),
        .LOG_PERIOD_MS  ( 1000     )
    ) u_debug_uart_logger (
        .I_clk          ( S_hdmi_pixel_clk   ),
        .I_rst_n        ( S_hdmi_rst_n       ),
        .I_status       ( S_debug_status_bus ),
        .I_ae           ( S_ae_px            ),
        .I_ag           ( S_ag_px            ),
        .I_frame_cnt    ( S_frame_cnt_dbg    ),
        .I_nonzero_cnt  ( S_dbg_nonzero_hold ),
        .I_bright_cnt   ( S_dbg_bright_hold  ),
        .I_very_cnt     ( S_dbg_very_hold    ),
        .I_max_px       ( S_dbg_raw_max_sync2),
        .I_disp_max_px  ( S_dbg_max_hold     ),
        .I_fifo_in_drop  ( S_dbg_fifo_in_drop  ),
        .I_fifo_out_drop ( S_dbg_fifo_out_drop ),
        .I_fifo_in_used  ( S_dbg_fifo_in_used  ),
        .I_fifo_out_used ( S_dbg_fifo_out_used ),
        // M0 追加的 8 个字段（见 debug_uart_logger.v 头部注释）
        .I_mode_word     ( S_mode_dbg         ),
        .I_edge_th       ( {5'b0, S_edge_th_csi} ),
        .I_mask_cnt      ( S_mask_cnt_hold     ),
        .I_bbox_x        ( {2'b0, S_bbox_x_hold} ),
        .I_bbox_y        ( {4'b0, S_bbox_y_hold} ),
        .I_tap_px        ( {4'b0, S_tap_px_hold} ),
        .I_ctrl_x        ( S_ctrl_up_x         ),
        .I_ctrl_y        ( S_ctrl_up_y         ),
        .O_tx           ( O_debug_tx         )
    );


    
endmodule
