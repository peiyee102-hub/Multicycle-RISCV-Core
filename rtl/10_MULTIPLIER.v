`timescale 1ns/1ps
`default_nettype none
module MULTIPLIER(input wire [31:0] a_i,b_i, input wire [1:0] operation_i,
                  output wire [31:0] result_o);
    // One unsigned product; modulo-2^32 corrections produce signed high halves.
    wire [63:0] product;
    wire [31:0] high_result;
    assign product = a_i * b_i;
    assign high_result = product[63:32]
        - (((operation_i==1 || operation_i==2) && a_i[31]) ? b_i : 32'b0)
        - ((operation_i==1 && b_i[31]) ? a_i : 32'b0);
    assign result_o = (operation_i==0) ? product[31:0] : high_result;
endmodule
`default_nettype wire
