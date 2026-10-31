`timescale 1ns/1ps

// ModelSim behavior model for the PH1P ERAM wrapper used by simulation.
module eram_spram #(
    parameter integer DATA_WIDTH = 48,
    parameter integer ADDR_WIDTH = 9
) (
    input  wire                    I_clk,
    input  wire                    I_we,
    input  wire [ADDR_WIDTH-1:0]   I_addr,
    input  wire [DATA_WIDTH-1:0]   I_wdata,
    output wire [DATA_WIDTH-1:0]   O_rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] rdata;
    integer i;

    initial begin
        for (i = 0; i < (1 << ADDR_WIDTH); i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
        rdata = {DATA_WIDTH{1'b0}};
    end

    always @(posedge I_clk) begin
        if (I_we)
            mem[I_addr] <= I_wdata;
        rdata <= mem[I_addr];
    end

    assign O_rdata = rdata;

endmodule
