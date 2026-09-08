module edge_detect_96 #(
    parameter IMG_WIDTH  = 1024,
    parameter IMG_HEIGHT = 600,
    parameter EDGE_TH    = 11'd132
)(
    input               I_clk,
    input               I_rst_n,
    input               I_tlast,
    input               I_tuser,
    input      [95:0]   I_tdata,
    input               I_tvalid,
    input               I_tready,
    output reg          O_tlast,
    output reg          O_tuser,
    output reg [95:0]   O_tdata,
    output reg          O_tvalid,
    output              O_tready
);

assign O_tready = I_tready;

localparam IMG_WIDTH_GRP = (IMG_WIDTH >> 2);

(* ram_style = "block" *) reg [7:0] line1_mem [0:IMG_WIDTH_GRP-1];
(* ram_style = "block" *) reg [7:0] line2_mem [0:IMG_WIDTH_GRP-1];

// Stage 0: register the AXI-Stream input and keep the group address.
reg [95:0] in_data_r;
reg        in_valid_r;
reg        in_user_r;
reg        in_last_r;
reg        fs_armed;
reg [10:0] x_cur;
reg [10:0] y_cur;

integer i;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        in_data_r  <= 96'd0;
        in_valid_r <= 1'b0;
        in_user_r  <= 1'b0;
        in_last_r  <= 1'b0;
        fs_armed   <= 1'b0;
        x_cur      <= 11'd0;
        y_cur      <= 11'd0;
    end
    else begin
        in_data_r  <= I_tdata;
        in_valid_r <= I_tvalid;
        in_last_r  <= I_tlast;

        // The AWB output data is delayed by its divider pipeline while I_tuser
        // belongs to the original stream. Keep one frame-start flag, then emit
        // it together with the first registered valid sample.
        if (I_tuser) begin
            in_user_r <= 1'b1;
            fs_armed  <= ~I_tvalid;
        end
        else if (fs_armed && I_tvalid) begin
            in_user_r <= 1'b1;
            fs_armed  <= 1'b0;
        end
        else begin
            in_user_r <= 1'b0;
        end

        if (I_tuser || (fs_armed && I_tvalid)) begin
            x_cur <= 11'd0;
            y_cur <= 11'd0;
        end
        else if (I_tvalid) begin
            if (x_cur == IMG_WIDTH_GRP - 1) begin
                x_cur <= 11'd0;
                if (y_cur == IMG_HEIGHT - 1)
                    y_cur <= 11'd0;
                else
                    y_cur <= y_cur + 1'b1;
            end
            else begin
                x_cur <= x_cur + 1'b1;
            end
        end
    end
end

// Stage 1: convert the four RGB pixels to one group gray value.
wire [23:0] pix0 = in_data_r[95:72];
wire [23:0] pix1 = in_data_r[71:48];
wire [23:0] pix2 = in_data_r[47:24];
wire [23:0] pix3 = in_data_r[23:0];

wire [7:0] gray0 = (pix0[23:16] + pix0[15:8] + pix0[7:0]) / 8'd3;
wire [7:0] gray1 = (pix1[23:16] + pix1[15:8] + pix1[7:0]) / 8'd3;
wire [7:0] gray2 = (pix2[23:16] + pix2[15:8] + pix2[7:0]) / 8'd3;
wire [7:0] gray3 = (pix3[23:16] + pix3[15:8] + pix3[7:0]) / 8'd3;

reg [7:0]  grp_gray_r;
reg        g_valid_r;
reg        g_user_r;
reg        g_last_r;
reg [10:0] x1;
reg [10:0] y1;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        grp_gray_r <= 8'd0;
        g_valid_r  <= 1'b0;
        g_user_r   <= 1'b0;
        g_last_r   <= 1'b0;
        x1         <= 11'd0;
        y1         <= 11'd0;
    end
    else begin
        grp_gray_r <= (gray0 + gray1 + gray2 + gray3) >> 2;
        g_valid_r  <= in_valid_r;
        g_user_r   <= in_user_r;
        g_last_r   <= in_last_r;
        x1         <= x_cur;
        y1         <= y_cur;
    end
end

// Stage 2: horizontal smoothing, line memory access and current-row write.
reg [7:0]  smooth_r;
reg        s_valid_r;
reg        s_user_r;
reg        s_last_r;
reg [10:0] x2;
reg [10:0] y2;
reg [7:0]  prev_grp_gray_d1;
reg [7:0]  prev_grp_gray_d2;
reg [7:0]  top_row_r;
reg [7:0]  mid_row_r;

wire [7:0] smooth_next =
    (x1 == 11'd0) ? grp_gray_r :
    (x1 == 11'd1) ? ((grp_gray_r + prev_grp_gray_d1) >> 1) :
                    (({{2{1'b0}}, grp_gray_r} +
                      ({{2{1'b0}}, prev_grp_gray_d1} << 1) +
                      {{2{1'b0}}, prev_grp_gray_d2}) >> 2);

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        smooth_r            <= 8'd0;
        s_valid_r           <= 1'b0;
        s_user_r            <= 1'b0;
        s_last_r            <= 1'b0;
        x2                  <= 11'd0;
        y2                  <= 11'd0;
        prev_grp_gray_d1    <= 8'd0;
        prev_grp_gray_d2    <= 8'd0;
        top_row_r           <= 8'd0;
        mid_row_r           <= 8'd0;
        for (i = 0; i < IMG_WIDTH_GRP; i = i + 1) begin
            line1_mem[i] <= 8'd0;
            line2_mem[i] <= 8'd0;
        end
    end
    else begin
        smooth_r <= smooth_next;
        s_valid_r <= g_valid_r;
        s_user_r  <= g_user_r;
        s_last_r  <= g_last_r;
        x2        <= x1;
        y2        <= y1;

        prev_grp_gray_d2 <= prev_grp_gray_d1;
        prev_grp_gray_d1 <= grp_gray_r;

        if (g_valid_r) begin
            top_row_r <= line2_mem[x1];
            mid_row_r <= line1_mem[x1];
            line2_mem[x1] <= line1_mem[x1];
            line1_mem[x1] <= smooth_next;
        end
    end
end

// Stage 3: capture the 3x3 window and shift the running column registers.
reg [7:0]  top_c0, top_c1, top_c2;
reg [7:0]  mid_c0, mid_c1, mid_c2;
reg [7:0]  cur_c0, cur_c1, cur_c2;
reg [7:0]  win_top0, win_top1, win_top2;
reg [7:0]  win_mid0, win_mid1, win_mid2;
reg [7:0]  win_cur0, win_cur1, win_cur2;
reg        w_valid_r;
reg        w_user_r;
reg        w_last_r;
reg [10:0] x3;
reg [10:0] y3;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        top_c0 <= 8'd0; top_c1 <= 8'd0; top_c2 <= 8'd0;
        mid_c0 <= 8'd0; mid_c1 <= 8'd0; mid_c2 <= 8'd0;
        cur_c0 <= 8'd0; cur_c1 <= 8'd0; cur_c2 <= 8'd0;
        win_top0 <= 8'd0; win_top1 <= 8'd0; win_top2 <= 8'd0;
        win_mid0 <= 8'd0; win_mid1 <= 8'd0; win_mid2 <= 8'd0;
        win_cur0 <= 8'd0; win_cur1 <= 8'd0; win_cur2 <= 8'd0;
        w_valid_r <= 1'b0;
        w_user_r  <= 1'b0;
        w_last_r  <= 1'b0;
        x3        <= 11'd0;
        y3        <= 11'd0;
    end
    else begin
        if (s_valid_r) begin
            // Snapshot the window for the Sobel stage, then update/clear the
            // column registers.  The snapshot keeps the end-of-row values
            // available to stage 4 while zeroing the running registers.
            win_top0 <= top_c0;
            win_top1 <= top_c1;
            win_top2 <= top_row_r;
            win_mid0 <= mid_c0;
            win_mid1 <= mid_c1;
            win_mid2 <= mid_row_r;
            win_cur0 <= cur_c0;
            win_cur1 <= cur_c1;
            win_cur2 <= smooth_r;

            top_c0 <= top_c1;
            top_c1 <= top_c2;
            top_c2 <= top_row_r;
            mid_c0 <= mid_c1;
            mid_c1 <= mid_c2;
            mid_c2 <= mid_row_r;
            cur_c0 <= cur_c1;
            cur_c1 <= cur_c2;
            cur_c2 <= smooth_r;

            if (x2 == IMG_WIDTH_GRP - 1) begin
                top_c0 <= 8'd0; top_c1 <= 8'd0; top_c2 <= 8'd0;
                mid_c0 <= 8'd0; mid_c1 <= 8'd0; mid_c2 <= 8'd0;
                cur_c0 <= 8'd0; cur_c1 <= 8'd0; cur_c2 <= 8'd0;
            end
        end

        w_valid_r <= s_valid_r;
        w_user_r  <= s_user_r;
        w_last_r  <= s_last_r;
        x3        <= x2;
        y3        <= y2;
    end
end

// Stage 4: Sobel horizontal and vertical gradients.
reg signed [12:0] gx_r;
reg signed [12:0] gy_r;
reg        q_valid_r;
reg        q_user_r;
reg        q_last_r;
reg [10:0] x4;
reg [10:0] y4;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        gx_r       <= 13'sd0;
        gy_r       <= 13'sd0;
        q_valid_r  <= 1'b0;
        q_user_r   <= 1'b0;
        q_last_r   <= 1'b0;
        x4         <= 11'd0;
        y4         <= 11'd0;
    end
    else begin
        if (w_valid_r) begin
            gx_r <= -$signed({1'b0, win_top0}) + $signed({1'b0, win_top2})
                   - ($signed({1'b0, win_mid0}) <<< 1) + ($signed({1'b0, win_mid2}) <<< 1)
                   - $signed({1'b0, win_cur0}) + $signed({1'b0, win_cur2});

            gy_r <=  $signed({1'b0, win_top0}) + ($signed({1'b0, win_top1}) <<< 1) + $signed({1'b0, win_top2})
                   - $signed({1'b0, win_cur0}) - ($signed({1'b0, win_cur1}) <<< 1) - $signed({1'b0, win_cur2});
        end

        q_valid_r <= w_valid_r;
        q_user_r  <= w_user_r;
        q_last_r  <= w_last_r;
        x4        <= x3;
        y4        <= y3;
    end
end

// Stage 5: magnitude, threshold and window validity.
wire [12:0] abs_gx_next = gx_r[12] ? (~gx_r + 13'd1) : gx_r;
wire [12:0] abs_gy_next = gy_r[12] ? (~gy_r + 13'd1) : gy_r;
wire [13:0] mag_next    = {1'b0, abs_gx_next} + {1'b0, abs_gy_next};
wire        edge_next   = (x4 >= 11'd2) && (y4 >= 11'd2) &&
                          (mag_next >= {3'b000, EDGE_TH});

reg        edge_r;
reg        e_valid_r;
reg        e_user_r;
reg        e_last_r;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        edge_r     <= 1'b0;
        e_valid_r  <= 1'b0;
        e_user_r   <= 1'b0;
        e_last_r   <= 1'b0;
    end
    else begin
        edge_r     <= edge_next;
        e_valid_r  <= q_valid_r;
        e_user_r   <= q_user_r;
        e_last_r   <= q_last_r;
    end
end

// Stage 6: three-point majority filter and output register.
reg edge_hist_d1;
reg edge_hist_d2;

always @(posedge I_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        O_tdata      <= 96'd0;
        O_tvalid     <= 1'b0;
        O_tuser      <= 1'b0;
        O_tlast      <= 1'b0;
        edge_hist_d1 <= 1'b0;
        edge_hist_d2 <= 1'b0;
    end
    else begin
        if (e_valid_r) begin
            O_tdata  <= (edge_r & edge_hist_d1) |
                        (edge_r & edge_hist_d2) |
                        (edge_hist_d1 & edge_hist_d2)
                        ? {24'hFFFFFF, 24'hFFFFFF, 24'hFFFFFF, 24'hFFFFFF}
                        : 96'd0;
            O_tvalid <= 1'b1;
            O_tuser  <= e_user_r;
            O_tlast  <= e_last_r;

            if (e_user_r || e_last_r) begin
                edge_hist_d1 <= 1'b0;
                edge_hist_d2 <= 1'b0;
            end
            else begin
                edge_hist_d2 <= edge_hist_d1;
                edge_hist_d1 <= edge_r;
            end
        end
        else begin
            O_tdata   <= 96'd0;
            O_tvalid  <= 1'b0;
            O_tuser   <= 1'b0;
            O_tlast   <= 1'b0;
        end
    end
end

endmodule
