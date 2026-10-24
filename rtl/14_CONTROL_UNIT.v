`timescale 1ns/1ps
`default_nettype none
module CONTROL_UNIT(input wire clk_i,rst_i,
    input wire [31:0] instruction_i,
    input wire branch_taken_i,
    output wire fetch_o,operand_write_o,result_write_o,mdr_write_o,pc_write_o,
    output wire register_write_o,read_enable_o,write_enable_o,jalr_o,
    output wire [1:0] a_select_o,b_select_o,unit_select_o,writeback_select_o,extension_operation_o,
    output wire [3:0] alu_operation_o);
    wire legal,decoded_write;
    wire [2:0] kind;
    wire [3:0] state,decoded_alu;
    wire [1:0] decoded_a,decoded_b,decoded_unit;
    INSTRUCTION_DECODER decoder_inst(.instruction_i(instruction_i),.legal_o(legal),
        .register_write_o(decoded_write),.kind_o(kind),.a_select_o(decoded_a),
        .b_select_o(decoded_b),.unit_select_o(decoded_unit),.alu_operation_o(decoded_alu),
        .extension_operation_o(extension_operation_o));
    MAIN_FSM fsm_inst(.clk_i(clk_i),.rst_i(rst_i),.legal_i(legal),.kind_i(kind),
        .state_o(state));
    CONTROL_SIGNALS signals_inst(.rst_i(rst_i),.register_write_i(decoded_write),
        .branch_taken_i(branch_taken_i),
        .state_i(state),.kind_i(kind),.decoded_alu_i(decoded_alu),
        .decoded_a_i(decoded_a),.decoded_b_i(decoded_b),.decoded_unit_i(decoded_unit),
        .fetch_o(fetch_o),.operand_write_o(operand_write_o),.result_write_o(result_write_o),
        .mdr_write_o(mdr_write_o),.pc_write_o(pc_write_o),.register_write_o(register_write_o),
        .read_enable_o(read_enable_o),.write_enable_o(write_enable_o),.jalr_o(jalr_o),
        .a_select_o(a_select_o),.b_select_o(b_select_o),.unit_select_o(unit_select_o),
        .writeback_select_o(writeback_select_o),.alu_operation_o(alu_operation_o));
endmodule
`default_nettype wire
