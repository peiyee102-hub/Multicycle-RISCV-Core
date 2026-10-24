`timescale 1ns/1ps
`default_nettype none
module DATA_MEMORY (
    input wire clk_i, read_enable_i, write_enable_i,
    input wire [29:0] word_address_i,
    input wire [31:0] write_data_i,
    input wire [3:0] byte_write_i,
    output reg [31:0] read_data_o
);
    localparam [29:0] DMEM_BASE_WORD = 30'h04004000;
    reg [31:0] memory [0:6];
    wire [29:0] index = word_address_i - DMEM_BASE_WORD;
    integer i;
    always @(posedge clk_i) begin
        if (read_enable_i)
            read_data_o <= (index < 7) ? memory[index] : 32'b0;
        if (write_enable_i && index < 7)
            for (i = 0; i < 4; i = i + 1)
                if (byte_write_i[i]) memory[index][i*8 +: 8] <= write_data_i[i*8 +: 8];
    end
endmodule
`default_nettype wire
