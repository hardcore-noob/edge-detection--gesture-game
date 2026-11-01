`timescale 1ns/1ps

module tb_game_catch;
    localparam [11:0] CATCH_Y = 610;
    localparam [11:0] BASKET_CENTER = 640;
    localparam [11:0] FRUIT_X_AT_CENTER = BASKET_CENTER - 64;

    reg clk;
    reg rst_n;
    reg vsync;
    reg [7:0] spawn_interval;
    reg [15:0] catch_cfg;
    reg restart;
    reg standby;
    reg pause;
    reg [11:0] blade_x;

    wire [287:0] obj;
    wire [11:0] burst_x;
    wire [11:0] burst_y;
    wire [143:0] part_off;
    wire [7:0] part_en;
    wire part_bomb;
    wire [8:0] score;
    wire [3:0] state;
    wire [15:0] hit_cnt;
    wire [15:0] miss_cnt;
    wire [11:0] fruit1_x;
    wire [11:0] fruit1_y;
    wire [15:0] state_word;
    wire [11:0] basket_center;
    wire [7:0] speed;

    integer errors;
    integer i;
    integer ox;
    integer oy;
    integer ow;
    integer oh;
    integer ot;

    game_catch dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_vsync(vsync),
        .I_spawn_interval(spawn_interval),
        .I_catch_cfg(catch_cfg),
        .I_restart(restart),
        .I_standby(standby),
        .I_pause(pause),
        .I_blade_x(blade_x),
        .O_obj(obj),
        .O_burst_x(burst_x),
        .O_burst_y(burst_y),
        .O_part_off(part_off),
        .O_part_en(part_en),
        .O_part_bomb(part_bomb),
        .O_score(score),
        .O_state(state),
        .O_hit_cnt(hit_cnt),
        .O_miss_cnt(miss_cnt),
        .O_fruit1_x(fruit1_x),
        .O_fruit1_y(fruit1_y),
        .O_state_word(state_word),
        .O_basket_center(basket_center),
        .O_speed(speed)
    );

    always #5 clk = ~clk;

    task frame_tick;
        begin
            @(negedge clk);
            vsync = 1'b1;
            @(posedge clk);
            #1;
            vsync = 1'b0;
            @(negedge clk);
            #1;
        end
    endtask

    task clear_objects;
        begin
            @(negedge clk);
            for(i = 0; i < 3; i = i + 1) begin
                dut.S_typ[i] = 2'd0;
                dut.S_bomb[i] = 1'b0;
                dut.S_resolved[i] = 1'b0;
                dut.S_py[i] = 12'd0;
            end
            dut.S_spawn_cnt = 8'd0;
        end
    endtask

    task restart_game;
        begin
            @(negedge clk);
            restart = 1'b1;
            @(posedge clk);
            #1;
            restart = 1'b0;
            @(negedge clk);
            #1;
        end
    endtask

    task force_crossing(input integer slot, input integer x, input bomb,
                        input [11:0] y);
        begin
            @(negedge clk);
            dut.S_typ[slot] = 2'd2;
            dut.S_bomb[slot] = bomb;
            dut.S_resolved[slot] = 1'b0;
            dut.S_px[slot] = x[11:0];
            dut.S_py[slot] = y;
        end
    endtask

    task expect_score(input neg, input [7:0] bcd, input [255:0] name);
        begin
            if(score !== {neg, bcd}) begin
                errors = errors + 1;
                $display("FAIL score %0s: got=%b expected=%b", name, score, {neg, bcd});
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        vsync = 1'b0;
        spawn_interval = 8'd255;
        catch_cfg = 16'h0332;
        restart = 1'b0;
        standby = 1'b0;
        pause = 1'b0;
        blade_x = BASKET_CENTER;
        errors = 0;

        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        repeat(2) @(posedge clk);

        @(negedge clk);
        blade_x = 12'd0;
        #1;
        if(basket_center !== 12'd130) begin
            errors = errors + 1;
            $display("FAIL left clamp center=%0d", basket_center);
        end
        blade_x = 12'd1279;
        #1;
        if(basket_center !== 12'd1149) begin
            errors = errors + 1;
            $display("FAIL right clamp center=%0d", basket_center);
        end
        blade_x = BASKET_CENTER;

        // 普通水果在开口内跨线：+1，并打开普通命中粒子。
        force_crossing(0, FRUIT_X_AT_CENTER, 1'b0,
                       CATCH_Y - 64 - 3);
        frame_tick;
        expect_score(0, 8'h01, "fruit catch +1");
        if(dut.S_typ[0] !== 2'd0 || part_en === 8'h00 || part_bomb !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL fruit catch removal/effect type=%0d en=%h bomb=%b",
                     dut.S_typ[0], part_en, part_bomb);
        end
        if(hit_cnt !== 16'd1 || miss_cnt !== 16'd0) begin
            errors = errors + 1;
            $display("FAIL fruit counters hit=%0d miss=%0d", hit_cnt, miss_cnt);
        end

        // 炸弹在开口内跨线：-5，并使用炸弹色爆散。
        restart_game;
        clear_objects;
        force_crossing(0, FRUIT_X_AT_CENTER, 1'b1,
                       CATCH_Y - 64 - 3);
        frame_tick;
        expect_score(1, 8'h05, "bomb catch -5");
        if(part_en === 8'h00 || part_bomb !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL bomb catch effect en=%h bomb=%b", part_en, part_bomb);
        end

        // 普通水果在开口外跨线：-1，对象继续下落。
        restart_game;
        clear_objects;
        force_crossing(0, 12'd60, 1'b0, CATCH_Y - 64 - 3);
        frame_tick;
        expect_score(1, 8'h01, "fruit miss -1");
        if(dut.S_typ[0] !== 2'd2 || dut.S_resolved[0] !== 1'b1 ||
           miss_cnt !== 16'd1) begin
            errors = errors + 1;
            $display("FAIL fruit miss type=%0d resolved=%b miss=%0d",
                     dut.S_typ[0], dut.S_resolved[0], miss_cnt);
        end

        // 已经漏掉的水果再次跨线时不重复扣分。
        @(negedge clk);
        dut.S_py[0] = 12'd539;
        frame_tick;
        expect_score(1, 8'h01, "fruit miss only once");

        // 炸弹漏掉不扣分。
        restart_game;
        clear_objects;
        force_crossing(0, 12'd60, 1'b1, CATCH_Y - 64 - 3);
        frame_tick;
        expect_score(0, 8'h00, "bomb miss no penalty");
        if(dut.S_typ[0] !== 2'd2 || dut.S_resolved[0] !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL bomb miss type=%0d resolved=%b",
                     dut.S_typ[0], dut.S_resolved[0]);
        end

        // 暂停时不结算、不移动。
        restart_game;
        clear_objects;
        pause = 1'b1;
        force_crossing(0, FRUIT_X_AT_CENTER, 1'b0, CATCH_Y - 64 - 3);
        frame_tick;
        expect_score(0, 8'h00, "paused no score");
        if(dut.S_py[0] !== CATCH_Y - 64 - 3) begin
            errors = errors + 1;
            $display("FAIL paused y=%0d", dut.S_py[0]);
        end
        pause = 1'b0;

        // 达到升级窗口后加速，封顶 9 px/帧。
        restart_game;
        @(negedge clk);
        dut.S_speed = 8'd3;
        dut.S_level_cnt = {8'b0, catch_cfg[7:0], 4'b0} - 16'd1;
        frame_tick;
        if(speed !== 8'd4) begin
            errors = errors + 1;
            $display("FAIL speed step got=%0d expected=4", speed);
        end
        @(negedge clk);
        dut.S_speed = 8'd9;
        dut.S_level_cnt = {8'b0, catch_cfg[7:0], 4'b0} - 16'd1;
        frame_tick;
        if(speed !== 8'd9) begin
            errors = errors + 1;
            $display("FAIL speed cap got=%0d", speed);
        end

        // 生成对象从 y=0 出现，type=2，并带合法水果种类。
        restart_game;
        clear_objects;
        spawn_interval = 8'd0;
        frame_tick;
        if(dut.S_typ[0] !== 2'd2 || dut.S_py[0] !== 12'd0 ||
           obj[47:46] !== 2'd2) begin
            errors = errors + 1;
            $display("FAIL spawn type=%0d y=%0d obj_type=%0d",
                     dut.S_typ[0], dut.S_py[0], obj[47:46]);
        end

        if(errors == 0)
            $display("PASS: catcher geometry, catch/miss scoring, pause, speed and spawn");
        else
            $display("FAIL: catcher errors=%0d", errors);
        $finish;
    end
endmodule
