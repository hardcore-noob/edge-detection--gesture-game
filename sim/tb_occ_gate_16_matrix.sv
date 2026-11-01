`timescale 1ns/1ps

module tb_occ_gate_16_matrix;
    localparam integer FRAME_W = 1280;
    localparam integer FRAME_H = 720;
    localparam integer X_GROUPS = FRAME_W / 4;
    localparam integer BLOCK_COLS = FRAME_W / 16;
    localparam integer BLOCK_ROWS = FRAME_H / 16;

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
    integer errors;
    integer checks;
    integer write_errors;
    integer write_checks;
    integer block_col;
    integer block_row;
    reg expected;
    reg actual_flags [0:BLOCK_ROWS-1][0:BLOCK_COLS-1];
    reg mismatch_flags [0:BLOCK_ROWS-1][0:BLOCK_COLS-1];

    occ_gate_16 #(
        .OCC_MIN(9'd64),
        .IMG_H(FRAME_H)
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

    function automatic expected_block;
        input integer col;
        input integer row;
        input integer pattern_frame;
        begin
            if ((row == 0) && (col <= 1))
                expected_block = 1'b1;
            else if ((row == 0) && (col <= 3))
                expected_block = 1'b0;
            else
                expected_block =
                    (((col * 13 + row * 17 + pattern_frame * 7) % 11) < 5);
        end
    endfunction

    function automatic [3:0] group_mask;
        input integer col;
        input integer row;
        input integer pattern_frame;
        input integer yy;
        input integer xx_group;
        integer block_y;
        integer block_x;
        begin
            block_y = yy % 16;
            block_x = xx_group % 4;
            group_mask = 4'b0000;
            if ((row == 0) && (col == 0))
                group_mask = 4'b1111;                 // dense
            else if ((row == 0) && (col == 1))
                group_mask = (block_y <= 3) ?
                             4'b1111 : 4'b0000;        // exactly 64/256
            else if ((row == 0) && (col == 2))
                group_mask = ((block_y <= 2) ||
                              ((block_y == 3) && (block_x < 3))) ?
                             4'b1111 : 4'b0000;        // 60/256, must drop
            else if ((row == 0) && (col == 3))
                group_mask = (((block_y >= 1) && (block_y <= 3)) ||
                              ((block_y == 4) && (block_x < 2))) ?
                             4'b1111 : 4'b0000;        // 56/256 = 21.875%
            else if (expected_block(col, row, pattern_frame))
                group_mask = 4'b1111;
        end
    endfunction

    task automatic pulse_tuser;
        begin
            @(negedge clk);
            tvalid = 1'b0;
            tuser  = 1'b1;
            x_grp  = 11'd0;
            y_pos  = 10'd0;
            mask   = 4'b0000;
            @(posedge clk);
            #1;
            @(negedge clk);
            tuser = 1'b0;
        end
    endtask

    task automatic drive_pixel_group;
        input integer yy;
        input integer xx_group;
        input integer current_frame;
        integer col;
        integer row;
        begin
            @(negedge clk);
            x_grp  = xx_group;
            y_pos  = yy;
            tvalid = 1'b1;
            tuser  = 1'b0;

            col = xx_group / 4;
            row = yy / 16;
            mask = group_mask(col, row, current_frame, yy, xx_group);

            #1;

            if ((current_frame == 6) && dut.write_enable) begin
                write_checks = write_checks + 1;
                expected = expected_block(dut.col, dut.row, current_frame);
                if (dut.block_passed !== expected) begin
                    write_errors = write_errors + 1;
                    if (write_errors <= 24)
                        $display("WRITE-MISMATCH row=%0d col=%0d expected=%0d pass=%0d total=%0d required=%0d",
                                 dut.row, dut.col, expected, dut.block_passed,
                                 dut.block_total, dut.required);
                end
            end

            @(posedge clk);
            #1;

            if ((current_frame == 7) && ((yy % 16) == 0) &&
                ((xx_group % 4) == 1)) begin
                checks = checks + 1;
                expected = expected_block(col, row, 6);
                actual_flags[row][col] = occ_keep;
                mismatch_flags[row][col] = (occ_keep !== expected);
                if (occ_keep !== expected) begin
                    errors = errors + 1;
                    if (errors <= 24)
                        $display("MISMATCH row=%0d col=%0d expected=%0d keep=%0d",
                                 row, col, expected, occ_keep);
                end
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
        errors = 0;
        checks = 0;
        write_errors = 0;
        write_checks = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        for (frame = 0; frame < 8; frame = frame + 1) begin
            pulse_tuser();
            for (y = 0; y < FRAME_H; y = y + 1) begin
                for (gx = 0; gx < X_GROUPS; gx = gx + 1)
                    drive_pixel_group(y, gx, frame);
            end
        end

        @(negedge clk);
        tvalid = 1'b0;
        tuser = 1'b0;

        $display("MATRIX: read_checks=%0d read_errors=%0d write_checks=%0d write_errors=%0d",
                 checks, errors, write_checks, write_errors);
        if (errors != 0) begin
            for (block_row = 0; block_row < 5; block_row = block_row + 1) begin
                $write("ACTUAL row %0d:", block_row);
                for (block_col = 0; block_col < BLOCK_COLS; block_col = block_col + 1)
                    $write("%0d", actual_flags[block_row][block_col]);
                $write("\n");
            end
            for (block_row = 0; block_row < BLOCK_ROWS; block_row = block_row + 1) begin
                expected = 1'b0;
                for (block_col = 0; block_col < BLOCK_COLS; block_col = block_col + 1)
                    if (mismatch_flags[block_row][block_col])
                        expected = 1'b1;
                if (expected) begin
                    $write("ROW %0d:", block_row);
                    for (block_col = 0; block_col < BLOCK_COLS; block_col = block_col + 1)
                        if (mismatch_flags[block_row][block_col])
                            $write(" c%0d=%0d/%0d", block_col,
                                   expected_block(block_col, block_row, 6),
                                   actual_flags[block_row][block_col]);
                    $write("\n");
                end
            end
        end
        if (checks != BLOCK_COLS * BLOCK_ROWS)
            $fatal(1, "did not observe every 16x16 block flag");
        if (write_checks != BLOCK_COLS * BLOCK_ROWS)
            $fatal(1, "did not observe every 16x16 block write");
        if (write_errors != 0)
            $fatal(1, "full-size 16x16 block-write matrix mismatch");
        if (errors != 0)
            $fatal(1, "full-size 16x16 block-flag matrix mismatch");
        $display("PASS: all 80x45 16x16 block flags match the previous-frame pattern");
        $finish;
    end
endmodule
