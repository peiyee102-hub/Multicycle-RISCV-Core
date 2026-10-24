`timescale 1ns/1ps
`default_nettype none
module MEMORY (
    input wire clk_i, rst_i, read_enable_i, write_enable_i,
    input wire [31:0] address_i, write_data_i,
    input wire [3:0] byte_write_i,
    output wire [31:0] read_data_o
);
    wire [29:0] word_address;
    wire imem_read, dmem_read, dmem_write;
    wire [1:0] select_memory;
    wire [3:0] byte_write;
    wire [31:0] imem_data, dmem_data;

    ADDRESS_DECODER decoder_inst(
        .rst_i(rst_i), .address_i(address_i),
        .read_enable_i(read_enable_i), .write_enable_i(write_enable_i),
        .byte_write_i(byte_write_i), .word_address_o(word_address),
        .imem_read_o(imem_read), .dmem_read_o(dmem_read),
        .dmem_write_o(dmem_write), .byte_write_o(byte_write),
        .select_o(select_memory)
    );
    INSTRUCTION_MEMORY imem_inst(
        .word_address_i(word_address), .read_enable_i(imem_read),
        .read_data_o(imem_data)
    );
    DATA_MEMORY dmem_inst(
        .clk_i(clk_i), .word_address_i(word_address),
        .read_enable_i(dmem_read), .write_enable_i(dmem_write),
        .byte_write_i(byte_write), .write_data_i(write_data_i),
        .read_data_o(dmem_data)
    );
    mux4_32 read_mux(
        .a_i(32'b0), .b_i(imem_data), .c_i(dmem_data), .d_i(32'b0),
        .select_i(select_memory), .data_o(read_data_o)
    );
endmodule
`default_nettype wire
