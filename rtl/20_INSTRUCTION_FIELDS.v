`timescale 1ns/1ps
`default_nettype none
module INSTRUCTION_FIELDS (
    input wire [31:0] instruction_i,
    output wire [4:0] rs1_o, rs2_o, rd_o,
    output wire [2:0] funct3_o
);
    assign rs1_o = instruction_i[19:15];
    assign rs2_o = instruction_i[24:20];
    assign rd_o = instruction_i[11:7];
    assign funct3_o = instruction_i[14:12];
endmodule
`default_nettype wire
