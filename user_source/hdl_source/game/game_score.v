// ============================================================================
// game_score —— 切水果单帧分数结算
//
// 输入都是同一帧内的事件：
//   * 每个切中的水果 +1；
//   * 每个切中的炸弹 -5；
//   * 每个漏掉的水果 -1（炸弹漏掉不扣分）。
//
// 分数使用 9 位符号-数值 BCD：{负号, 十位[3:0], 个位[3:0]}。
// 范围饱和到 -99..+99，供现有两位数字 OSD 直接显示。
// 本模块是纯组合逻辑，便于对全部分数边界做穷举仿真。
// ============================================================================
module game_score (
    input  wire [8:0] I_score,          // {negative, bcd_tens, bcd_ones}
    input  wire [1:0] I_miss_num,       // 本帧新漏掉的水果数
    input  wire [2:0] I_fruit_hit_mask, // 本帧切中的水果槽
    input  wire [2:0] I_bomb_hit_mask,  // 本帧切中的炸弹槽
    output wire [8:0] O_score
);

    function [6:0] F_bcd_to_bin;
        input [7:0] I_bcd;
        reg [7:0] tens;
        begin
            tens = {4'b0, I_bcd[7:4]};
            F_bcd_to_bin = (tens << 3) + (tens << 1) + {3'b0, I_bcd[3:0]};
        end
    endfunction

    // 对 0..99 的整数求十进制十位/个位。最多做 10 次减 10，
    // 不使用乘法器；该结果每帧最多更新一次，长组合路径的时序余量足够。
    function [7:0] F_bin_to_bcd;
        input [6:0] I_v;
        reg [6:0] rem;
        reg [3:0] tens;
        integer i;
        begin
            rem  = I_v;
            tens = 4'd0;
            for(i = 0; i < 10; i = i + 1) begin
                if(rem >= 7'd10) begin
                    rem  = rem - 7'd10;
                    tens = tens + 4'd1;
                end
            end
            F_bin_to_bcd = {tens, rem[3:0]};
        end
    endfunction

    function [6:0] F_abs9;
        input signed [9:0] I_v;
        begin
            F_abs9 = I_v[9] ? -$signed(I_v[6:0]) : I_v[6:0];
        end
    endfunction

    reg [3:0] W_fruit_num;
    reg [3:0] W_bomb_num;
    reg [4:0] W_bomb_penalty;
    reg signed [6:0] W_delta;
    reg signed [8:0] W_cur;
    reg signed [9:0] W_sum;
    reg signed [9:0] W_limited;
    reg              W_negative;
    reg [6:0]        W_abs;

    always @* begin
        W_fruit_num = {3'b0, I_fruit_hit_mask[0]} +
                      {3'b0, I_fruit_hit_mask[1]} +
                      {3'b0, I_fruit_hit_mask[2]};
        W_bomb_num  = {3'b0, I_bomb_hit_mask[0]} +
                      {3'b0, I_bomb_hit_mask[1]} +
                      {3'b0, I_bomb_hit_mask[2]};
        W_bomb_penalty = (W_bomb_num << 2) + W_bomb_num; // ×5
        W_delta = $signed({3'b0, W_fruit_num}) -
                  $signed({2'b0, W_bomb_penalty}) -
                  $signed({5'b0, I_miss_num});

        W_cur = I_score[8] ? -$signed({2'b0, F_bcd_to_bin(I_score[7:0])})
                           :  $signed({2'b0, F_bcd_to_bin(I_score[7:0])});
        W_sum = $signed({W_cur[8], W_cur}) +
                $signed({{3{W_delta[6]}}, W_delta});

        if(W_sum > 10'sd99)
            W_limited = 10'sd99;
        else if(W_sum < -10'sd99)
            W_limited = -10'sd99;
        else
            W_limited = W_sum;

        W_negative = W_limited[9];
        W_abs      = F_abs9(W_limited);
    end

    assign O_score = {W_negative, F_bin_to_bcd(W_abs)};

endmodule
