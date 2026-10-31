// ============================================================================
// occ_gate_32 —— 32x32 块级掩码占比门
//
// 每块采样 4 行（每 8 行采 1 行），共 128 个采样点。当前帧按块行累计，
// 块行结束时把 bit7 标志写入当前 Bank；下一帧从另一 Bank 读取该标志。
// OCC_MIN=16 为 12.5%，OCC_MIN=32 为 25%。
// ============================================================================
module occ_gate_32 #(
    parameter [6:0] OCC_MIN = 7'd16,
    parameter integer BLOCK_COLS = 40,
    parameter integer BLOCK_ROWS = 23,
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

    localparam [9:0] ADDR_LAST = BLOCK_COLS * BLOCK_ROWS - 1;
    localparam integer LAST_IMG_ROW = IMG_H - 1;
    localparam [5:0] COL_LAST = BLOCK_COLS - 1;

    wire [2:0] beat = I_x_grp[2:0];
    wire [5:0] col  = I_x_grp[7:3];
    wire [4:0] row  = I_y_pos[9:5];
    wire [9:0] base = row * BLOCK_COLS;
    wire [9:0] cur  = base + {4'b0, col};
    wire sample_row = (I_y_pos[2:0] == 3'd0);
    wire bbox_row_start = (I_y_pos[4:0] == 5'd0);
    wire block_last = (I_y_pos[4:0] == 5'd31) || (I_y_pos == LAST_IMG_ROW);

    // The scan is row-major on video lines while the flag memory is row-major
    // on 32-line block rows. Prefetch column 0 of the same block row at every
    // video-row boundary and advance to the next block row after y=31.
    wire [9:0] next_addr = block_last
                           ? ((cur == ADDR_LAST) ? 10'd0 : (cur + 10'd1))
                           : ((col == COL_LAST) ? base : (cur + 10'd1));
    wire [9:0] read_addr = (beat == 3'd7) ? next_addr : cur;

    reg [2:0] frame_count;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            frame_count <= 3'd0;
        else if(I_tuser && !(&frame_count))
            frame_count <= frame_count + 3'd1;
    end

    // frame_count[0] selects the write bank for this frame. The other bank
    // holds the previous frame's accepted-block flags.
    wire bank_sel = frame_count[0];
    wire [9:0] write_addr = cur;
    wire write_enable = I_tvalid && block_last && (beat == 3'd7);
    wire [9:0] bank0_addr = (write_enable && !bank_sel) ? write_addr : read_addr;
    wire [9:0] bank1_addr = (write_enable &&  bank_sel) ? write_addr : read_addr;

    wire [7:0] bank0_rdata;
    wire [7:0] bank1_rdata;
    wire [7:0] bank0_wdata;
    wire [7:0] bank1_wdata;

    wire [2:0] beat_count = {2'b0, I_mask[0]} + {2'b0, I_mask[1]} +
                            {2'b0, I_mask[2]} + {2'b0, I_mask[3]};
    reg [6:0] row_count;
    reg [7:0] block_count [0:BLOCK_COLS-1];
    integer i;
    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n) begin
            for (i = 0; i < BLOCK_COLS; i = i + 1)
                block_count[i] <= 8'd0;
        end
        else if(I_tvalid && sample_row) begin
            if(beat == 3'd7) begin
                if(bbox_row_start)
                    block_count[col] <= row_count + {4'b0, beat_count};
                else
                    block_count[col] <= block_count[col] + row_count +
                                        {4'b0, beat_count};
            end
        end
    end

    always @(posedge I_clk or negedge I_rst_n) begin
        if(!I_rst_n)
            row_count <= 7'd0;
        else if(I_tvalid && sample_row) begin
            if(beat == 3'd0)
                row_count <= {4'b0, beat_count};
            else
                row_count <= row_count + {4'b0, beat_count};
        end
    end

    wire block_passed = (block_count[col] >= OCC_MIN);
    assign bank0_wdata = {block_passed, 7'd0};
    assign bank1_wdata = {block_passed, 7'd0};

    eram_spram #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(10)
    ) u_prev_bank0 (
        .I_clk  (I_clk),
        .I_we   (write_enable && !bank_sel),
        .I_addr (bank0_addr),
        .I_wdata(bank0_wdata),
        .O_rdata(bank0_rdata)
    );

    eram_spram #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(10)
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
        else if(I_tvalid && (beat == 3'd0))
            block_byte <= prev_rdata;
    end

    assign O_keep = (&frame_count) && block_byte[7];

endmodule
