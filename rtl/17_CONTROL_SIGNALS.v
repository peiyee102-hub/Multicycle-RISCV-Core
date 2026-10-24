`timescale 1ns/1ps
`default_nettype none
module CONTROL_SIGNALS(
    input wire rst_i,register_write_i,branch_taken_i,
    input wire [3:0] state_i,decoded_alu_i,
    input wire [2:0] kind_i,
    input wire [1:0] decoded_a_i,decoded_b_i,decoded_unit_i,
    output wire fetch_o,operand_write_o,result_write_o,mdr_write_o,pc_write_o,
    output wire register_write_o,read_enable_o,write_enable_o,jalr_o,
    output wire [1:0] a_select_o,b_select_o,unit_select_o,writeback_select_o,
    output wire [3:0] alu_operation_o
);
    wire fetching,executing,jumping;
    assign fetching=(state_i==0);
    assign executing=(state_i==2);
    assign jumping=(kind_i==4 || kind_i==5 || (kind_i==3 && branch_taken_i));
    assign fetch_o=fetching && !rst_i;
    assign operand_write_o=(state_i==1) && !rst_i;
    assign result_write_o=executing && !rst_i;
    assign mdr_write_o=(state_i==4) && !rst_i;
    assign pc_write_o=!rst_i && (fetching || (executing && jumping));
    assign register_write_o=(state_i==5) && register_write_i && !rst_i;
    assign read_enable_o=!rst_i && (fetching || ((state_i==3 || state_i==4) && kind_i==1));
    assign write_enable_o=!rst_i && (state_i==3 && kind_i==2);
    assign jalr_o=(kind_i==5) && !fetching;
    assign a_select_o=fetching ? 2'd1 : decoded_a_i;
    assign b_select_o=fetching ? 2'd2 : decoded_b_i;
    assign unit_select_o=fetching ? 2'd0 : decoded_unit_i;
    assign alu_operation_o=fetching ? 4'd1 : decoded_alu_i;
    assign writeback_select_o=(kind_i==1) ? 2'd1 : ((kind_i==4 || kind_i==5) ? 2'd2 : 2'd0);
endmodule
`default_nettype wire
