`timescale 1ns/1ps

module tb_game_render;
    reg clk;
    reg rst_n;
    reg de;
    reg [11:0] x_nxt;
    reg [11:0] y_nxt;
    reg [3:0] display_mode;
    reg [287:0] obj;
    reg [11:0] tip_x;
    reg [11:0] tip_y;
    reg [287:0] trail_off;
    reg [15:0] trail_en;
    reg [11:0] burst_x;
    reg [11:0] burst_y;
    reg [143:0] part_off;
    reg [7:0] part_en;
    reg part_bomb;
    reg [8:0] score;
    reg [3:0] state;
    reg marker_en;
    reg [7:0] spr_px;

    wire [12:0] spr_addr;
    wire hit;
    wire [23:0] color;
    integer errors;
    integer pi;

    game_render dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_de(de),
        .I_x_nxt(x_nxt),
        .I_y_nxt(y_nxt),
        .I_display_mode(display_mode),
        .I_obj(obj),
        .I_tip_x(tip_x),
        .I_tip_y(tip_y),
        .I_trail_off(trail_off),
        .I_trail_en(trail_en),
        .I_burst_x(burst_x),
        .I_burst_y(burst_y),
        .I_part_off(part_off),
        .I_part_en(part_en),
        .I_part_bomb(part_bomb),
        .I_score(score),
        .I_state(state),
        .I_marker_en(marker_en),
        .O_spr_addr(spr_addr),
        .I_spr_px(spr_px),
        .O_hit(hit),
        .O_color(color)
    );

    always #5 clk = ~clk;

    task set_idle_objects;
        integer i;
        begin
            for(i = 0; i < 6; i = i + 1)
                obj[i*48 +: 48] = {2'd2, 12'd2000, 12'd0,
                                   5'd0, 5'd0, 8'd0, 4'd0};
        end
    endtask

    task check_pixel(input expect_hit, input [255:0] name);
        begin
            @(posedge clk);
            @(negedge clk);
            #1;
            if(hit !== expect_hit) begin
                errors = errors + 1;
                $display("FAIL pixel %0s: hit=%b expected=%b score_raw=%b flat_d=%b spr_d=%b obj=%b part=%b",
                         name, hit, expect_hit, dut.S_hit_score,
                         dut.S_win_flat_d, dut.S_win_spr_d, dut.S_hit_obj, dut.S_hit_part);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        de = 1;
        x_nxt = 0;
        y_nxt = 0;
        display_mode = 0;
        tip_x = 0;
        tip_y = 0;
        trail_off = 0;
        trail_en = 0;
        burst_x = 0;
        burst_y = 0;
        part_off = 0;
        part_en = 0;
        part_bomb = 0;
        score = 0;
        state = 1;
        marker_en = 0;
        spr_px = 8'h20;
        errors = 0;
        set_idle_objects;

        repeat(2) @(posedge clk);
        rst_n = 1;

        // 负号只在负分时出现。
        score = {1'b1, 8'h00};
        x_nxt = 12'd525;
        y_nxt = 12'd177;
        #1;
        if(dut.S_hit_score !== 1'b1)
            $display("DEBUG minus in_y=%b in_minus=%b minus_px=%b score_neg=%b hit_score=%b",
                     dut.S_in_score_y, dut.S_in_minus, dut.S_minus_px,
                     score[8], dut.S_hit_score);
        check_pixel(1'b1, "negative score minus");
        score[8] = 1'b0;
        check_pixel(1'b0, "positive score no minus");

        // 删除生命后，原生命块位置不再产生任何像素。
        x_nxt = 12'd80;
        y_nxt = 12'd216;
        check_pixel(1'b0, "life blocks removed");

        // 普通水果粒子仍是 6×6。
        part_en = 8'h01;
        burst_x = 12'd100;
        burst_y = 12'd100;
        part_off = 0;
        part_bomb = 0;
        x_nxt = 12'd105;
        y_nxt = 12'd105;
        check_pixel(1'b1, "fruit particle inside 6x6");
        x_nxt = 12'd110;
        check_pixel(1'b0, "fruit particle outside 6x6");

        // 炸弹粒子使用 12×12 橙红块。
        part_bomb = 1;
        x_nxt = 12'd111;
        y_nxt = 12'd111;
        check_pixel(1'b1, "bomb particle inside 12x12");
        if(color != 24'hFF5000) begin
            errors = errors + 1;
            $display("FAIL bomb particle color=%h", color);
        end
        x_nxt = 12'd113;
        check_pixel(1'b0, "bomb particle outside 12x12");

        // 初始 -6 偏移时，12×12 印章应恰好以爆点为中心。
        part_off = 0;
        for(pi = 0; pi < 8; pi = pi + 1) begin
            part_off[pi*18 +: 9] = -9'sd6;
            part_off[pi*18 + 9 +: 9] = -9'sd6;
        end
        x_nxt = 12'd94;
        y_nxt = 12'd94;
        check_pixel(1'b1, "centered bomb particle first pixel");
        x_nxt = 12'd93;
        check_pixel(1'b0, "centered bomb particle left of anchor");
        part_en = 0;
        part_bomb = 0;

        // 炸弹对象必须走 sprite=4 的 13 位地址。
        obj[0 +: 48] = {2'd2, 12'd100, 12'd100, 5'd31, 5'd31, 8'd0, 4'b1000};
        x_nxt = 12'd100;
        y_nxt = 12'd100;
        #1;
        if(spr_addr !== 13'h1000) begin
            errors = errors + 1;
            $display("FAIL bomb sprite address=%h expected=1000", spr_addr);
        end

        // 普通水果仍走 sprite=0..3。
        obj[0 +: 48] = {2'd2, 12'd100, 12'd100, 5'd31, 5'd31, 8'd0, 4'b0010};
        #1;
        if(spr_addr !== 13'h0800) begin
            errors = errors + 1;
            $display("FAIL fruit sprite address=%h expected=0800", spr_addr);
        end

        if(errors == 0)
            $display("PASS: render score sign, removed lives, particle sizes/color, sprite addressing");
        else
            $display("FAIL: render errors=%0d", errors);
        $finish;
    end
endmodule
