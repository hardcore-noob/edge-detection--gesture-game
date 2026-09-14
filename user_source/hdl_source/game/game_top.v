// ============================================================================
// game_top —— RENDER_SLOT 插座（像素域，DDR 读回与 OSD 之间）
//
// 位置：video_out.O_vdieo_data → game_top → hdmi_mixer.I_video_rd_data。
// 边界必须 **0 拍组合**：hdmi_mixer 内部用 S_x_2d/S_y_2d 画 OSD，如果这里插一拍
// 寄存器，OSD 就会相对画面错开一个像素——M3 加精灵流水线时也要保持"对外 0 拍"，
// 内部要打拍就把 x/y 一起打拍。
//
// M0 内容：游戏层还是空壳（直通），旁路 mux 已经就位（I_bypass 选它），并且每帧
// 在第一个 DE 周期发一个 CTRL_SYNC 下行测试字 {x=0x0A5, y=0x0D3, state}，
// 用来验证 CTRL_SYNC 双向往返。M3 在同一模块内加逐像素判属渲染。
//
// 延迟：0 拍（组合直通）。
// 时钟域：像素域单时钟，不跨域。
// 资源：M0 约 20 FF + 30 LUT，无 ERAM / DSP。
// ============================================================================
module game_top (
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire        I_vsync,
    input  wire        I_de,
    input  wire [23:0] I_pixel_in,
    input  wire        I_bypass,       // 1 = 游戏层整体旁路（M3 起真正起作用）
    input  wire [3:0]  I_game_mode,
    input  wire [3:0]  I_display_mode,
    output wire [23:0] O_pixel_out,
    output wire [25:0] O_ctrl_tx_data, // {x[10:0], y[10:0], state[3:0]}
    output wire        O_ctrl_tx_valid
);

    // M0 的游戏层是空壳：像素直通（M3 在这里换成逐像素判属的渲染结果）。
    wire [23:0] S_layer_out = I_pixel_in;

    assign O_pixel_out = I_bypass ? I_pixel_in : S_layer_out;

    // ---- 每帧第一个 DE：发下行测试字 ----------------------------------------
    reg S_vsync_d;
    reg S_frame_pulse_pending;

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            S_vsync_d            <= 1'b0;
            S_frame_pulse_pending <= 1'b0;
        end
        else begin
            S_vsync_d <= I_vsync;
            if(I_vsync & ~S_vsync_d)
                S_frame_pulse_pending <= 1'b1;
            else if(I_de & S_frame_pulse_pending)
                S_frame_pulse_pending <= 1'b0;
        end
    end

    // 测试常数：x=0x0A5(=165)、y=0x0D3(=211)，state 带上当前模式，
    // 上板后用 DBG 行的 X/Y 字段核对往返。
    assign O_ctrl_tx_valid = I_de & S_frame_pulse_pending;
    assign O_ctrl_tx_data  = {11'h0A5, 11'h0D3, I_display_mode};

endmodule
