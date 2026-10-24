`timescale 1ns/1ps
`default_nettype none
module EXECUTION_UNIT(
    input wire [31:0] rs1_i,rs2_i,pc_i,old_pc_i,immediate_i,
    input wire [1:0] a_select_i,b_select_i,unit_select_i,
    input wire [3:0] alu_operation_i,
    input wire [1:0] extension_operation_i,
    output wire [31:0] result_o
);
    wire [31:0] a,b,alu_result,multiply_result,crc_result;
    MUX4_32 a_mux(.a_i(rs1_i),.b_i(pc_i),.c_i(old_pc_i),.d_i(32'b0),
        .select_i(a_select_i),.data_o(a));
    MUX4_32 b_mux(.a_i(rs2_i),.b_i(immediate_i),.c_i(32'd4),.d_i(32'b0),
        .select_i(b_select_i),.data_o(b));
    ALU alu_inst(.a_i(a),.b_i(b),.operation_i(alu_operation_i),.result_o(alu_result));
    MULTIPLIER multiplier_inst(.a_i(rs1_i),.b_i(rs2_i),
        .operation_i(extension_operation_i),.result_o(multiply_result));
    CRC crc_inst(.data_i(rs1_i),.seed_i(rs2_i),
        .operation_i(extension_operation_i),.result_o(crc_result));
    MUX4_32 result_mux(.a_i(alu_result),.b_i(multiply_result),.c_i(crc_result),
        .d_i(32'b0),.select_i(unit_select_i),.data_o(result_o));
endmodule
`default_nettype wire
