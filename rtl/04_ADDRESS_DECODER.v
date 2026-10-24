`timescale 1ns/1ps
`default_nettype none
module ADDRESS_DECODER (
    input wire rst_i, read_enable_i, write_enable_i,
    input wire [31:0] address_i,
    input wire [3:0] byte_write_i,
    output wire [29:0] word_address_o,
    output wire imem_read_o, dmem_read_o, dmem_write_o,
    output wire [3:0] byte_write_o,
    output wire [1:0] select_o
);
    // End addresses are exclusive. Preserve the supplied IMEM window.
    localparam [31:0] IMEM_BASE = 32'h00400000, IMEM_END = 32'h00800000;
    // Seven words cover test_ram and dest_data through byte 0x1001001B.
    localparam [31:0] DMEM_BASE = 32'h10010000, DMEM_END = 32'h1001001C;
    wire imem_selected, dmem_selected;
    assign word_address_o = address_i[31:2];
    assign imem_selected = (address_i >= IMEM_BASE) && (address_i < IMEM_END);
    assign dmem_selected = (address_i >= DMEM_BASE) && (address_i < DMEM_END);
    assign select_o = rst_i ? 2'd0 : imem_selected ? 2'd1 : dmem_selected ? 2'd2 : 2'd0;
    assign imem_read_o = imem_selected && read_enable_i && !rst_i;
    assign dmem_read_o = dmem_selected && read_enable_i && !rst_i;
    assign dmem_write_o = dmem_selected && write_enable_i && !rst_i;
    assign byte_write_o = dmem_write_o ? byte_write_i : 4'b0;
endmodule
`default_nettype wire
