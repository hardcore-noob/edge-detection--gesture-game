`timescale 1ns/1ps

module tb_game_score;
    reg  [8:0] score;
    reg  [1:0] miss_num;
    reg  [2:0] fruit_mask;
    reg  [2:0] bomb_mask;
    wire [8:0] next_score;

    integer tens;
    integer ones;
    integer neg;
    integer m;
    integer f;
    integer b;
    integer cur;
    integer expected_value;
    integer fruit_num;
    integer bomb_num;
    integer abs_value;
    integer errors;

    game_score dut (
        .I_score          (score),
        .I_miss_num       (miss_num),
        .I_fruit_hit_mask (fruit_mask),
        .I_bomb_hit_mask  (bomb_mask),
        .O_score          (next_score)
    );

    function integer count_bits;
        input [2:0] value;
        integer i;
        begin
            count_bits = 0;
            for(i = 0; i < 3; i = i + 1)
                if(value[i]) count_bits = count_bits + 1;
        end
    endfunction

    initial begin
        errors = 0;
        for(tens = 0; tens < 10; tens = tens + 1) begin
            for(ones = 0; ones < 10; ones = ones + 1) begin
                for(neg = 0; neg < 2; neg = neg + 1) begin
                    for(m = 0; m < 4; m = m + 1) begin
                        for(f = 0; f < 8; f = f + 1) begin
                            for(b = 0; b < 8; b = b + 1) begin
                                score     = {neg[0], tens[3:0], ones[3:0]};
                                miss_num  = m[1:0];
                                fruit_mask= f[2:0];
                                bomb_mask = b[2:0];
                                #1;

                                cur = (neg ? -1 : 1) * (tens * 10 + ones);
                                fruit_num = count_bits(fruit_mask);
                                bomb_num  = count_bits(bomb_mask);
                                expected_value = cur + fruit_num - 5 * bomb_num - m;
                                if(expected_value > 99)  expected_value = 99;
                                if(expected_value < -99) expected_value = -99;

                                if(next_score[8] !== (expected_value < 0))
                                    errors = errors + 1;
                                abs_value = expected_value < 0 ? -expected_value : expected_value;
                                if(next_score[7:0] !==
                                   (((abs_value / 10) << 4) + (abs_value % 10))) begin
                                    errors = errors + 1;
                                    if(errors < 8)
                                        $display("BAD score=%b t=%0d o=%0d neg=%0d m=%0d f=%0d b=%0d got=%b exp=%0d lim=%0d abs=%0d",
                                                 score, tens, ones, neg, m, f, b,
                                                 next_score[7:0], expected_value,
                                                 dut.W_limited, dut.W_abs);
                                end
                            end
                        end
                    end
                end
            end
        end

        if(errors == 0)
            $display("PASS: exhaustive signed-BCD score checks=51200");
        else
            $display("FAIL: signed-BCD score errors=%0d", errors);
        $finish;
    end
endmodule
