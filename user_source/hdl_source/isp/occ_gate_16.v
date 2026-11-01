// ============================================================================
// occ_gate_16 —— 16x16 块级掩码占比门
//
// 每块统计完整 16×16 区域，共 256 个像素。当前帧按块行累计，
// 块行结束时把 bit7 标志写入当前 Bank；下一帧从另一 Bank 读取该标志。
// OCC_MIN=64 为 25%。
// ============================================================================
module occ_gate_16 #(
    parameter [8:0] OCC_MIN = 9'd64,
    parameter integer IMG_H = 720
)(
    input  wire        I_clk,
    input  wire        I_rst_n,
    input  wire [3:0]  I_mask,
    input  wire [10:0] I_x_grp,
    input  wire [9:0]  I_y_pos,
    input  wire        I_tvalid,
    input  wire        I_tuser,
    output wire        O_keep
);

    localparam integer BLOCK_COLS = 80;
    localparam integer BLOCK_ROWS = 45;
    localparam integer ADDR_WIDTH = 12;
    localparam [ADDR_WIDTH-1:0] ADDR_LAST = BLOCK_COLS * BLOCK_ROWS - 1;
    localparam integer LAST_IMG_ROW = IMG_H - 1;
    localparam [6:0] COL_LAST = BLOCK_COLS - 1;
    localparam integer LAST_BLOCK_H = (IMG_H % 16 == 0) ? 16 : (IMG_H % 16);
    localparam [8:0] LAST_OCC_MIN =
        (OCC_MIN * LAST_BLOCK_H + 15) / 16;

    wire [1:0] beat = I_x_grp[1:0];
    // 1280 px = 80 blocks of 16 px. Each block spans four 4-pixel groups.
    wire [6:0] col  = I_x_grp[8:2];
    wire [5:0] row  = I_y_pos[9:4];
    // 80 = 64 + 16. Use explicit shifts so TD does not infer a multiplier/DSP.
    wire [ADDR_WIDTH-1:0] base = {row, 6'b0} + {row, 4'b0};
    wire [ADDR_WIDTH-1:0] cur  = base + {5'b0, col};
    wire block_row_start = (I_y_pos[3:0] == 4'd0);
    wire block_last = (I_y_pos[3:0] == 4'd15) || (I_y_pos == LAST_IMG_ROW);

    // The scan is row-major on video lines while the flag memory is row-major
    // on 16-line block rows. Prefetch column 0 of the same block row at every
    // video-row boundary and advance to the next block row after y=15.
    wire [ADDR_WIDTH-1:0] next_addr = block_last
                           ? ((cur == ADDR_LAST) ? {ADDR_WIDTH{1'b0}} : (cur + 1'b1))
                           : ((col == COL_LAST) ? base : (cur + 1'b1));
    wire [ADDR_WIDTH-1:0] read_addr = (beat == 2'd3) ? next_addr : cur;

    reg [2:0] frame_count;
    reg       bank_sel;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            frame_count <= 3'd0;
            bank_sel    <= 1'b0;
        end
        else if(I_tuser) begin
            if(!(&frame_count))
                frame_count <= frame_count + 3'd1;
            bank_sel <= ~bank_sel;
        end
    end

    // bank_sel must keep toggling after frame_count saturates. The write bank
    // holds this frame's flags while the other bank retains the previous frame.
    wire [ADDR_WIDTH-1:0] write_addr = cur;
    wire write_enable = I_tvalid && block_last && (beat == 2'd3);
    wire [ADDR_WIDTH-1:0] bank0_addr = (write_enable && !bank_sel) ? write_addr : read_addr;
    wire [ADDR_WIDTH-1:0] bank1_addr = (write_enable &&  bank_sel) ? write_addr : read_addr;

    wire [7:0] bank0_rdata;
    wire [7:0] bank1_rdata;
    wire [7:0] bank0_wdata;
    wire [7:0] bank1_wdata;

    wire [2:0] beat_count = {2'b0, I_mask[0]} + {2'b0, I_mask[1]} +
                            {2'b0, I_mask[2]} + {2'b0, I_mask[3]};
    reg [4:0] row_count;
    reg [8:0] block_count [0:BLOCK_COLS-1];
    integer i;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            for (i = 0; i < BLOCK_COLS; i = i + 1)
                block_count[i] <= 9'd0;
        end
        else if(I_tvalid && (beat == 2'd3)) begin
            if(block_row_start)
                block_count[col] <= row_count + {6'b0, beat_count};
            else
                block_count[col] <= block_count[col] + row_count +
                                    {6'b0, beat_count};
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            row_count <= 5'd0;
        else if(I_tvalid) begin
            if(beat == 2'd0)
                row_count <= {2'b0, beat_count};
            else
                row_count <= row_count + {2'b0, beat_count};
        end
    end

    wire [8:0] block_total = block_count[col] + row_count + {6'b0, beat_count};
    wire [8:0] required = (row == BLOCK_ROWS - 1) ? LAST_OCC_MIN : OCC_MIN;
    wire block_passed = (block_total >= required);
    assign bank0_wdata = {block_passed, 7'd0};
    assign bank1_wdata = {block_passed, 7'd0};

    eram_spram #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_prev_bank0 (
        .I_clk  (I_clk),
        .I_we   (write_enable && !bank_sel),
        .I_addr (bank0_addr),
        .I_wdata(bank0_wdata),
        .O_rdata(bank0_rdata)
    );

    eram_spram #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_prev_bank1 (
        .I_clk  (I_clk),
        .I_we   (write_enable && bank_sel),
        .I_addr (bank1_addr),
        .I_wdata(bank1_wdata),
        .O_rdata(bank1_rdata)
    );

    wire [7:0] prev_rdata = bank_sel ? bank0_rdata : bank1_rdata;
    reg [7:0] block_byte;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            block_byte <= 8'd0;
        else if(I_tvalid && (beat == 2'd0))
            block_byte <= prev_rdata;
    end

    assign O_keep = (&frame_count) && block_byte[7];

endmodule
