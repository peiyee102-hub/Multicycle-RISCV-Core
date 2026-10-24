`timescale 1ns/1ps
`default_nettype none
module ALU(input wire [31:0] a_i, b_i, input wire [3:0] operation_i,
           output reg [31:0] result_o);
    always @* case(operation_i)
        4'h0: result_o=b_i;
        4'h1: result_o=a_i+b_i;
        4'h2: result_o=a_i-b_i;
        4'h3: result_o=a_i&b_i;
        4'h4: result_o=a_i|b_i;
        4'h5: result_o=a_i^b_i;
        4'h6: result_o=a_i<<b_i[4:0];
        4'h7: result_o=a_i>>b_i[4:0];
        4'h8: result_o=$signed(a_i)>>>b_i[4:0];
        4'h9: result_o={31'b0,($signed(a_i)<$signed(b_i))};
        4'ha: result_o={31'b0,(a_i<b_i)};
        default: result_o=0;
    endcase
endmodule
`default_nettype wire
