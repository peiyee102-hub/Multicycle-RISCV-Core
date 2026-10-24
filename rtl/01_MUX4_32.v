`timescale 1ns/1ps
`default_nettype none
module MUX4_32 (
    input wire [31:0] a_i, b_i, c_i, d_i, input wire [1:0] select_i,
    output reg [31:0] data_o
);
    always @* case(select_i)
        0: data_o=a_i; 1: data_o=b_i;
        2: data_o=c_i; 3: data_o=d_i;
        default: data_o=0;
    endcase
endmodule
`default_nettype wire
