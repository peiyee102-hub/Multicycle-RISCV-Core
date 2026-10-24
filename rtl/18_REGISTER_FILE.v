`timescale 1ns/1ps
`default_nettype none
module REGISTER_FILE (
    input wire clk_i, rst_i, write_enable_i,
    input wire [4:0] rs1_address_i, rs2_address_i, rd_address_i,
    input wire [31:0] write_data_i,
    output wire [31:0] rs1_data_o, rs2_data_o
);
    reg [31:0] registers [0:31];
    integer i;
    assign rs1_data_o = (rs1_address_i == 0) ? 32'b0 : registers[rs1_address_i];
    assign rs2_data_o = (rs2_address_i == 0) ? 32'b0 : registers[rs2_address_i];
    always @(posedge clk_i) begin
        if (rst_i) begin
            for (i=0; i<32; i=i+1) registers[i] <= 32'b0;
        end else if (write_enable_i && rd_address_i != 0)
            registers[rd_address_i] <= write_data_i;
    end
endmodule
`default_nettype wire
