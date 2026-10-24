`timescale 1ns/1ps
`default_nettype none
module JALR_TARGET(
  	input wire [31:0] result_i,
  	input wire jalr_i,
    output wire [31:0] target_o
);
  
    assign target_o = jalr_i ? {result_i[31:1],1'b0} : result_i;
endmodule
`default_nettype wire
