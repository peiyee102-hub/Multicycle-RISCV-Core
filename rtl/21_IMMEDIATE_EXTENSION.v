`timescale 1ns/1ps
`default_nettype none
module IMMEDIATE_EXTENSION(input wire [31:0] instruction_i,
                           output reg [31:0] immediate_o);
    always @* case (instruction_i[6:0])
        7'h23: immediate_o={{20{instruction_i[31]}},instruction_i[31:25],instruction_i[11:7]};
        7'h63: immediate_o={{19{instruction_i[31]}},instruction_i[31],instruction_i[7],instruction_i[30:25],instruction_i[11:8],1'b0};
        7'h37,7'h17: immediate_o={instruction_i[31:12],12'b0};
        7'h6f: immediate_o={{11{instruction_i[31]}},instruction_i[31],instruction_i[19:12],instruction_i[20],instruction_i[30:21],1'b0};
        default: immediate_o={{20{instruction_i[31]}},instruction_i[31:20]};
    endcase
endmodule
`default_nettype wire
