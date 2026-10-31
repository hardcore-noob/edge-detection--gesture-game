`timescale 1ns/1ps

module tb_occ_gate_32;
    localparam integer FRAME_W = 64;
    localparam integer FRAME_H = 64;
    localparam integer X_GROUPS = FRAME_W / 4;

    reg clk;
    reg rst_n;
    reg [3:0] mask;
    reg [10:0] x_grp;
    reg [9:0] y_pos;
    reg tvalid;
    reg tuser;
    wire occ_keep;

    integer frame;
    integer y;
    integer gx;
    reg dense_keep;
    reg boundary_keep;
    reg sparse_keep;
    reg row_start_keep;
    reg late_row_keep;

    occ_gate_32 #(
        .OCC_MIN(7'd16),
        .BLOCK_COLS(2),
        .BLOCK_ROWS(2),
        .IMG_H(64)
    ) dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_mask(mask),
        .I_x_grp(x_grp),
        .I_y_pos(y_pos),
        .I_tvalid(tvalid),
        .I_tuser(tuser),
        .O_keep(occ_keep)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic drive_pixel_group;
        input integer yy;
        input integer xx_group;
        input integer current_frame;
        begin
            @(negedge clk);
            x_grp  = xx_group;
            y_pos  = yy;
            tvalid = 1'b1;
            tuser  = (yy == 0) && (xx_group == 0);
            mask   = 4'b0000;

            // 32x32 block (0,0): 128/128 sampled pixels, must pass.
            if (((yy % 8) == 0) && (yy < 32) && (xx_group < 8))
                mask = 4'b1111;

            // 32x32 block (1,0): exactly 16/128 sampled pixels (12.5%), must pass.
            if (((yy % 8) == 0) && (yy < 32) && (xx_group == 8))
                mask = 4'b1111;

            // 32x32 block (0,1): 8/128 sampled pixels (6.25%), must drop.
            if (((yy % 8) == 0) && (yy >= 32) && (xx_group == 0))
                mask = 4'b0011;

            // 32x32 block (1,1): dense, used to catch stale flags after a
            // settlement-row write has shifted the read address.
            if (((yy % 8) == 0) && (yy >= 32) &&
                (xx_group >= 8) && (xx_group < 16))
                mask = 4'b1111;

            // Last block in row 0: dense. Its flag must not leak into the
            // first block of row 1 after the y=31 settlement write.
            if (((yy % 8) == 0) && (yy < 32) && (xx_group >= 72))
                mask = 4'b1111;

            // Wait until the following rising edge has consumed this group.
            @(posedge clk);
            #1;

            if (current_frame == 7) begin
                // Four-pixel groups are prefetched one block ahead. Observe each
                // 32-pixel block at its beat0, where block_byte has settled.
                if ((yy == 1) && (xx_group == 1)) dense_keep = occ_keep;
                if ((yy == 1) && (xx_group == 9)) boundary_keep = occ_keep;
                if ((yy == 33) && (xx_group == 1)) sparse_keep = occ_keep;
                if ((yy == 32) && (xx_group == 1)) row_start_keep = occ_keep;
                if ((yy == 63) && (xx_group == 9)) late_row_keep = occ_keep;
            end
        end
    endtask

    initial begin
        rst_n = 1'b0;
        mask = 4'b0000;
        x_grp = 11'd0;
        y_pos = 10'd0;
        tvalid = 1'b0;
        tuser = 1'b0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // Four power-up frames are forced open; later frames use stored flags.
        for (frame = 0; frame < 8; frame = frame + 1) begin
            for (y = 0; y < FRAME_H; y = y + 1) begin
                for (gx = 0; gx < X_GROUPS; gx = gx + 1)
                    drive_pixel_group(y, gx, frame);
            end
        end

        @(negedge clk);
        tvalid = 1'b0;
        tuser = 1'b0;

        if (!dense_keep)
            $fatal(1, "dense block was incorrectly dropped");
        if (!boundary_keep)
            $fatal(1, "12.5%% boundary block was incorrectly dropped");
        if (sparse_keep)
            $fatal(1, "6.25%% sparse block was incorrectly kept");
        if (row_start_keep)
            $fatal(1, "row-start block inherited the previous row's last flag");
        if (!late_row_keep)
            $fatal(1, "settlement-row write shifted a later block's read flag");
        $display("PASS: occ_gate_32 keeps 12.5%%, drops 6.25%%, and preserves row-boundary flags");
        $finish;
    end
endmodule
