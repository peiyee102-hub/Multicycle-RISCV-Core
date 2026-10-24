`timescale 1ns/1ps
`default_nettype none
module MUX2_32 (
    input wire [31:0] a_i, b_i, input wire select_i,
    output wire [31:0] data_o
);
    assign data_o = select_i ? b_i : a_i;
endmodule
`default_nettype wire
