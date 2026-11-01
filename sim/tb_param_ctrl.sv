`timescale 1ns/1ps

module tb_param_ctrl;
    reg clk;
    reg rst_n;
    reg key1_short;
    reg key4_short;
    reg key4_long;
    reg frame_strobe;
    reg [3:0] sw_raw;
    reg ext_we;
    reg [7:0] ext_addr;
    reg [15:0] ext_data;
    reg commit_pulse;
    reg [7:0] rd_addr;

    wire [15:0] rd_data;
    wire [3:0] display_mode;
    wire [3:0] game_mode;
    wire [3:0] recog_algo;
    wire [3:0] edge_th_sel;
    wire [10:0] edge_th;
    wire [15:0] teach_cnt;
    wire [15:0] param_wr_cnt;
    wire [15:0] mode_commit_cnt;
    wire [7:0] key4_evt;
    wire teach_req;
    wire [15:0] mode_word;
    wire [3:0] led;
    wire b_we;
    wire [5:0] b_addr;
    wire [15:0] b_wdata;

    integer errors;

    param_ctrl #(
        .CLK_HZ(10000),
        .SW_DEBOUNCE_MS(1)
    ) dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_key1_short(key1_short),
        .I_key4_short(key4_short),
        .I_key4_long(key4_long),
        .I_frame_strobe(frame_strobe),
        .I_sw_raw(sw_raw),
        .I_ext_we(ext_we),
        .I_ext_addr(ext_addr),
        .I_ext_data(ext_data),
        .I_commit_pulse(commit_pulse),
        .I_rd_addr(rd_addr),
        .O_rd_data(rd_data),
        .O_display_mode(display_mode),
        .O_game_mode(game_mode),
        .O_recog_algo(recog_algo),
        .O_edge_th_sel(edge_th_sel),
        .O_edge_th(edge_th),
        .O_teach_cnt(teach_cnt),
        .O_param_wr_cnt(param_wr_cnt),
        .O_mode_commit_cnt(mode_commit_cnt),
        .O_key4_evt(key4_evt),
        .O_teach_req(teach_req),
        .O_mode_word(mode_word),
        .O_led(led),
        .O_b_we(b_we),
        .O_b_addr(b_addr),
        .O_b_wdata(b_wdata),
        .I_b_rd_data(16'h1234)
    );

    always #5 clk = ~clk;

    task pulse_key4;
        begin
            @(negedge clk);
            key4_short = 1'b1;
            @(negedge clk);
            key4_short = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task expect_mode(input [3:0] mode, input [3:0] algo,
                     input [255:0] name);
        begin
            if(game_mode !== mode || recog_algo !== algo) begin
                errors = errors + 1;
                $display("FAIL %0s game=%0d algo=%0d expected=%0d/%0d",
                         name, game_mode, recog_algo, mode, algo);
            end
            if(led[1] !== (mode != 0)) begin
                errors = errors + 1;
                $display("FAIL %0s active LED=%b", name, led[1]);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        key1_short = 1'b0;
        key4_short = 1'b0;
        key4_long = 1'b0;
        frame_strobe = 1'b1;
        sw_raw = 4'd0;
        ext_we = 1'b0;
        ext_addr = 8'h00;
        ext_data = 16'h0000;
        commit_pulse = 1'b0;
        rd_addr = 8'h01;
        errors = 0;

        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        expect_mode(4'd0, 4'd0, "boot");

        pulse_key4;
        expect_mode(4'd1, 4'd1, "cut fruit");

        pulse_key4;
        expect_mode(4'd2, 4'd1, "fruit catcher");

        pulse_key4;
        expect_mode(4'd0, 4'd0, "exit games");

        if(key4_evt[3:0] !== 4'd3) begin
            errors = errors + 1;
            $display("FAIL KEY4 short count=%0d", key4_evt[3:0]);
        end

        // UART can still select a game directly; the next KEY4 advances from it.
        @(negedge clk);
        ext_we = 1'b1;
        ext_addr = 8'h01;
        ext_data = 16'h0002;
        @(posedge clk);
        #1;
        ext_we = 1'b0;
        expect_mode(4'd2, 4'd0, "UART direct select");
        pulse_key4;
        expect_mode(4'd0, 4'd0, "advance from UART select");

        // Long press must not change the game cycle.
        @(negedge clk);
        key4_long = 1'b1;
        @(posedge clk);
        #1;
        key4_long = 1'b0;
        expect_mode(4'd0, 4'd0, "long press stays off");
        if(key4_evt[7:4] !== 4'd1) begin
            errors = errors + 1;
            $display("FAIL KEY4 long count=%0d", key4_evt[7:4]);
        end

        rd_addr = 8'h80;
        #1;
        if(rd_data !== 16'h1234) begin
            errors = errors + 1;
            $display("FAIL B-segment readback=%h", rd_data);
        end

        if(errors == 0)
            $display("PASS: KEY4 cycles off/fruit/catcher and keeps recognition active");
        else
            $display("FAIL: param_ctrl errors=%0d", errors);
        $finish;
    end
endmodule
