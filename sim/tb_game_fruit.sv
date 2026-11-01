`timescale 1ns/1ps

module tb_game_fruit;
    localparam [2:0] PH_PHYS = 3'd1;
    localparam [2:0] PH_ACT  = 3'd4;

    reg clk;
    reg rst_n;
    reg vsync;
    reg [7:0] spawn_interval;
    reg [15:0] grav;
    reg [15:0] v0;
    reg [15:0] trail_cfg;
    reg [15:0] part_cfg;
    reg [11:0] field_y1;
    reg restart;
    reg standby;
    reg pause;
    reg [11:0] blade_x;
    reg [11:0] blade_y;
    reg blade_valid;
    reg track_locked;
    reg cut_src_ok;

    wire [287:0] obj;
    wire [11:0] tip_x;
    wire [11:0] tip_y;
    wire [287:0] trail_off;
    wire [15:0] trail_en;
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
    wire [15:0] blade_pos;

    integer errors;
    integer i;
    integer expected_x [0:7];
    integer expected_y [0:7];

    game_fruit dut (
        .I_clk(clk),
        .I_rst_n(rst_n),
        .I_vsync(vsync),
        .I_spawn_interval(spawn_interval),
        .I_grav(grav),
        .I_v0(v0),
        .I_trail_cfg(trail_cfg),
        .I_part_cfg(part_cfg),
        .I_field_y1(field_y1),
        .I_restart(restart),
        .I_standby(standby),
        .I_pause(pause),
        .I_blade_x(blade_x),
        .I_blade_y(blade_y),
        .I_blade_valid(blade_valid),
        .I_track_locked(track_locked),
        .I_cut_src_ok(cut_src_ok),
        .O_obj(obj),
        .O_tip_x(tip_x),
        .O_tip_y(tip_y),
        .O_trail_off(trail_off),
        .O_trail_en(trail_en),
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
        .O_blade_pos(blade_pos)
    );

    always #5 clk = ~clk;

    task run_phase(input [2:0] phase);
        begin
            @(negedge clk);
            dut.S_ph = phase;
            @(posedge clk);
            #1;
        end
    endtask

    task clear_frame_events;
        begin
            @(negedge clk);
            dut.S_hit_f = 3'd0;
            dut.S_miss_score = 2'd0;
            dut.S_ph = 3'd0;
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

    task check_particle_offsets(input [255:0] name);
        begin
            for(i = 0; i < 8; i = i + 1) begin
                if($signed(dut.S_pox[i]) !== expected_x[i] ||
                   $signed(dut.S_poy[i]) !== expected_y[i]) begin
                    errors = errors + 1;
                    $display("FAIL %0s particle[%0d]=(%0d,%0d) expected=(%0d,%0d)",
                             name, i, $signed(dut.S_pox[i]), $signed(dut.S_poy[i]),
                             expected_x[i], expected_y[i]);
                end
            end
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        vsync = 0;
        spawn_interval = 8'd48;
        grav = 16'h0040;
        v0 = 16'h0900;
        trail_cfg = 16'h080A;
        part_cfg = 16'h0814;
        field_y1 = 12'd704;
        restart = 0;
        standby = 0;
        pause = 0;
        blade_x = 640;
        blade_y = 400;
        blade_valid = 0;
        track_locked = 0;
        cut_src_ok = 1;
        errors = 0;

        repeat(3) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // 普通水果 +1，生成两半并打开黄色粒子。
        @(negedge clk);
        dut.S_score = 8'h00;
        dut.S_score_neg = 0;
        dut.S_typ[0] = 2'd2;
        dut.S_bomb[0] = 0;
        dut.S_px[0] = 16'd640 << 4;
        dut.S_py[0] = 16'd300 << 4;
        dut.S_vx[0] = 0;
        dut.S_vy[0] = 0;
        dut.S_hit_f = 3'b001;
        run_phase(PH_ACT);
        expect_score(0, 8'h01, "fruit +1");
        if(dut.S_typ[0] !== 2'd3 || part_en !== 8'hFF || part_bomb !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL fruit effect type=%0d part_en=%h bomb=%b",
                     dut.S_typ[0], part_en, part_bomb);
        end
        for(i = 0; i < 8; i = i + 1) begin
            expected_x[i] = -3;
            expected_y[i] = -3;
        end
        check_particle_offsets("fruit initial centered");

        // 炸弹 -5，不产生半片，触发橙红色爆炸。
        clear_frame_events;
        @(negedge clk);
        dut.S_score = 8'h00;
        dut.S_score_neg = 0;
        dut.S_typ[0] = 2'd2;
        dut.S_bomb[0] = 1;
        dut.S_px[0] = 16'd640 << 4;
        dut.S_py[0] = 16'd300 << 4;
        dut.S_hit_f = 3'b001;
        run_phase(PH_ACT);
        expect_score(1, 8'h05, "bomb -5");
        if(dut.S_typ[0] !== 2'd0 || dut.S_bomb[0] !== 1'b0 ||
           part_en !== 8'hFF || part_bomb !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL bomb effect type=%0d bomb=%b part_en=%h part_bomb=%b",
                     dut.S_typ[0], dut.S_bomb[0], part_en, part_bomb);
        end
        for(i = 0; i < 8; i = i + 1) begin
            expected_x[i] = -6;
            expected_y[i] = -6;
        end
        check_particle_offsets("bomb initial centered");

        // 第一次物理更新必须保持八个方向向外扩散，不能把负坐标当正数。
        run_phase(PH_PHYS);
        expected_x[0] = -2; expected_y[0] = -10;
        expected_x[1] =  0; expected_y[1] =  -6;
        expected_x[2] = -2; expected_y[2] =  -2;
        expected_x[3] = -6; expected_y[3] =   0;
        expected_x[4] =-10; expected_y[4] =  -2;
        expected_x[5] =-12; expected_y[5] =  -6;
        expected_x[6] =-10; expected_y[6] = -10;
        expected_x[7] = -6; expected_y[7] = -12;
        check_particle_offsets("bomb first radial step");

        // 第二次更新继续向外；修复前这里会出现 +255 的符号扩展错误。
        run_phase(PH_PHYS);
        expected_x[0] =  2; expected_y[0] = -14;
        expected_x[1] =  6; expected_y[1] =  -6;
        expected_x[2] =  2; expected_y[2] =   2;
        expected_x[3] = -6; expected_y[3] =   6;
        expected_x[4] =-14; expected_y[4] =   2;
        expected_x[5] =-18; expected_y[5] =  -6;
        expected_x[6] =-14; expected_y[6] = -14;
        expected_x[7] = -6; expected_y[7] = -18;
        check_particle_offsets("bomb second radial step");

        // 同帧水果 + 炸弹：+1-5 = -4；水果成片，炸弹删除，爆炸优先。
        clear_frame_events;
        @(negedge clk);
        dut.S_score = 8'h00;
        dut.S_score_neg = 0;
        dut.S_typ[0] = 2'd2;
        dut.S_typ[1] = 2'd2;
        dut.S_typ[2] = 2'd0;
        dut.S_bomb[0] = 0;
        dut.S_bomb[1] = 1;
        dut.S_px[0] = 16'd400 << 4;
        dut.S_px[1] = 16'd700 << 4;
        dut.S_py[0] = 16'd300 << 4;
        dut.S_py[1] = 16'd320 << 4;
        dut.S_hit_f = 3'b011;
        run_phase(PH_ACT);
        expect_score(1, 8'h04, "fruit and bomb net -4");
        if(dut.S_typ[0] !== 2'd3 || dut.S_typ[1] !== 2'd0 || part_bomb !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL combined effect fruit=%0d bomb=%0d part_bomb=%b",
                     dut.S_typ[0], dut.S_typ[1], part_bomb);
        end

        // 漏掉普通水果 -1；先 PHYS 记录事件，再 ACT 统一结算。
        clear_frame_events;
        @(negedge clk);
        dut.S_score = 8'h00;
        dut.S_score_neg = 0;
        dut.S_typ[0] = 2'd2;
        dut.S_bomb[0] = 0;
        dut.S_py[0] = 16'd710 << 4;
        dut.S_vy[0] = 16'd16;
        dut.S_missed[0] = 0;
        run_phase(PH_PHYS);
        if(dut.S_miss_score !== 2'd1) begin
            errors = errors + 1;
            $display("FAIL fruit miss event=%0d", dut.S_miss_score);
        end
        run_phase(PH_ACT);
        expect_score(1, 8'h01, "missed fruit -1");

        // 漏掉炸弹不扣分。
        clear_frame_events;
        @(negedge clk);
        dut.S_score = 8'h00;
        dut.S_score_neg = 0;
        dut.S_typ[1] = 2'd2;
        dut.S_bomb[1] = 1;
        dut.S_py[1] = 16'd710 << 4;
        dut.S_vy[1] = 16'd16;
        dut.S_missed[1] = 0;
        run_phase(PH_PHYS);
        if(dut.S_miss_score !== 2'd0) begin
            errors = errors + 1;
            $display("FAIL missed bomb was charged=%0d", dut.S_miss_score);
        end
        run_phase(PH_ACT);
        expect_score(0, 8'h00, "missed bomb no penalty");

        // 负分可跨过零点回到正分。
        @(negedge clk);
        dut.S_score = 8'h04;
        dut.S_score_neg = 1;
        dut.S_typ[2] = 2'd2;
        dut.S_bomb[2] = 0;
        dut.S_hit_f = 3'b100;
        run_phase(PH_ACT);
        expect_score(1, 8'h03, "negative score remains -3 after +1");

        // 炸弹生成概率与同屏上限。
        @(negedge clk);
        dut.S_typ[0] = 2'd0;
        dut.S_typ[1] = 2'd0;
        dut.S_typ[2] = 2'd0;
        dut.S_lfsr[3:0] = 4'd0;
        #1;
        if(dut.S_spawn_bomb !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL low LFSR did not select bomb");
        end
        dut.S_typ[0] = 2'd2;
        dut.S_bomb[0] = 1;
        #1;
        if(dut.S_spawn_bomb !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL second bomb allowed while one is active");
        end
        dut.S_lfsr[3:0] = 4'd15;
        dut.S_typ[0] = 2'd0;
        #1;
        if(dut.S_spawn_bomb !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL high LFSR selected bomb");
        end

        // 漏切和炸弹都不会进入结束态；状态字保留 4 位生命区但固定为 0。
        if(state !== 4'd1 || state_word[11:9] !== 3'b000) begin
            errors = errors + 1;
            $display("FAIL game state=%0d state_word=%h", state, state_word);
        end

        if(errors == 0)
            $display("PASS: fruit/bomb score, miss, centered radial particles, spawn limit, no-life state");
        else
            $display("FAIL: fruit integration errors=%0d", errors);
        $finish;
    end
endmodule
