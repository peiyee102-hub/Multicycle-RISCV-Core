`timescale 1ns/1ps
`default_nettype none
module BRANCH_COMPARATOR(input wire [31:0] rs1_i,rs2_i,
    input wire [2:0] funct3_i, output reg taken_o);
    always @* case(funct3_i)
        0: taken_o=(rs1_i==rs2_i);
        1: taken_o=(rs1_i!=rs2_i);
        4: taken_o=($signed(rs1_i)<$signed(rs2_i));
        5: taken_o=($signed(rs1_i)>=$signed(rs2_i));
        6: taken_o=(rs1_i<rs2_i);
        7: taken_o=(rs1_i>=rs2_i);
        default: taken_o=0;
    endcase
endmodule
`default_nettype wire
