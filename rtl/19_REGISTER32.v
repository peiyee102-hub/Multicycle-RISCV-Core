`timescale 1ns/1ps
`default_nettype none
module REGISTER32 #(parameter RESET_VALUE = 32'b0)(
    input wire clk_i, rst_i, enable_i,
    input wire [31:0] data_i, output reg [31:0] data_o
);
    always @(posedge clk_i) begin
        if (rst_i) data_o <= RESET_VALUE;
        else if (enable_i) data_o <= data_i;
    end
endmodule
`default_nettype wire
