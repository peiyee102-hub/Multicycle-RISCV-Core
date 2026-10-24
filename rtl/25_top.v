`timescale 1ns/1ps
`default_nettype none
module top (

  input wire clk,
  input wire rst,
  output wire [31:0] pc_o

);

//Internal Wires
 wire w_1;
 wire [31:0] w_2;
 wire [31:0] w_3;
 wire [4:0] w_6;
 wire [4:0] w_7;
 wire [4:0] w_8;
 wire [2:0] w_9;
 wire w_11;
 wire [31:0] w_12;
 wire [31:0] w_13;
 wire [31:0] w_14;
 wire [31:0] w_15;
 wire [31:0] w_16;
 wire [31:0] w_17;
 wire w_18;
 wire [31:0] w_19;
 wire [31:0] w_20;
 wire [31:0] w_22;
 wire w_25;
 wire w_26;
 wire [31:0] w_27;
 wire [31:0] w_28;
 wire [31:0] w_29;
 wire [3:0] w_30;
 wire w_31;
 wire w_32;
 wire [31:0] w_34;
 wire [31:0] w_35;
 wire [1:0] w_36;
 wire w_37;
 wire [31:0] w_38;
 wire [31:0] w_45;
 wire w_46;
 wire w_50;
 wire [31:0] w_51;
 wire w_52;
 wire w_55;
 wire [1:0] w_56;
 wire [1:0] w_57;
 wire [1:0] w_58;
 wire [1:0] w_59;
 wire [3:0] w_60;

//Interface Assigns
assign pc_o [31:0] = w_20;

//Instances of Modules
REGISTER32 blk4029_3 (
         .clk_i (clk),
         .rst_i (rst),
         .enable_i (w_1),
         .data_i (w_2),
         .data_o (w_3)
     );

INSTRUCTION_FIELDS blk4030_4 (
         .instruction_i (w_3),
         .rs1_o (w_6),
         .rs2_o (w_7),
         .rd_o (w_8),
         .funct3_o (w_9)
     );

REGISTER_FILE blk4028_5 (
         .clk_i (clk),
         .rst_i (rst),
         .rs1_address_i (w_6),
         .rs2_address_i (w_7),
         .rd_address_i (w_8),
         .write_enable_i (w_11),
         .write_data_i (w_12),
         .rs1_data_o (w_13),
         .rs2_data_o (w_14)
     );

IMMEDIATE_EXTENSION blk4031_12 (
         .instruction_i (w_3),
         .immediate_o (w_15)
     );

BRANCH_COMPARATOR blk4032_14 (
         .funct3_i (w_9),
         .rs1_i (w_16),
         .rs2_i (w_17),
         .taken_o (w_18)
     );

MUX2_32 blk4002_17 (
         .a_i (w_19),
         .b_i (w_20),
         .select_i (w_1),
         .data_o (w_22)
     );

LSU blk4034_19 (
         .funct3_i (w_9),
         .address_i (w_22),
         .store_data_i (w_17),
         .memory_data_i (w_2),
         .read_enable_i (w_25),
         .write_enable_i (w_26),
         .address_o (w_27),
         .write_data_o (w_28),
         .load_data_o (w_29),
         .byte_write_o (w_30),
         .read_enable_o (w_31),
         .write_enable_o (w_32)
     );

MUX4_32 blk4001_21 (
         .d_i (32'd0),
         .data_o (w_12),
         .a_i (w_19),
         .b_i (w_34),
         .c_i (w_35),
         .select_i (w_36)
     );

REGISTER32 #(.RESET_VALUE(32'h00400000)) blk4029_57 (
         .clk_i (clk),
         .rst_i (rst),
         .data_o (w_20),
         .enable_i (w_37),
         .data_i (w_38)
     );

REGISTER32 #(.RESET_VALUE(32'b0)) blk4029_58 (
         .clk_i (clk),
         .rst_i (rst),
         .data_i (w_20),
         .enable_i (w_1),
         .data_o (w_45)
     );

REGISTER32 #(.RESET_VALUE(32'b0)) blk4029_60 (
         .clk_i (clk),
         .rst_i (rst),
         .data_i (w_13),
         .data_o (w_16),
         .enable_i (w_46)
     );

REGISTER32 #(.RESET_VALUE(32'b0)) blk4029_62 (
         .clk_i (clk),
         .rst_i (rst),
         .data_i (w_14),
         .data_o (w_17),
         .enable_i (w_46)
     );

REGISTER32 #(.RESET_VALUE(32'b0)) blk4029_64 (
         .clk_i (clk),
         .rst_i (rst),
         .data_o (w_19),
         .enable_i (w_50),
         .data_i (w_51)
     );

REGISTER32 #(.RESET_VALUE(32'b0)) blk4029_66 (
         .clk_i (clk),
         .rst_i (rst),
         .data_i (w_29),
         .data_o (w_34),
         .enable_i (w_52)
     );

REGISTER32 #(.RESET_VALUE(32'b0)) blk4029_68 (
         .clk_i (clk),
         .rst_i (rst),
         .data_o (w_35),
         .enable_i (w_1),
         .data_i (w_51)
     );

CONTROL_UNIT blk4026_79 (
         .clk_i (clk),
         .rst_i (rst),
         .fetch_o (w_1),
         .instruction_i (w_3),
         .register_write_o (w_11),
         .branch_taken_i (w_18),
         .read_enable_o (w_25),
         .write_enable_o (w_26),
         .writeback_select_o (w_36),
         .pc_write_o (w_37),
         .operand_write_o (w_46),
         .result_write_o (w_50),
         .mdr_write_o (w_52),
         .jalr_o (w_55),
         .a_select_o (w_56),
         .b_select_o (w_57),
         .unit_select_o (w_58),
         .extension_operation_o (w_59),
         .alu_operation_o (w_60)
     );

EXECUTION_UNIT blk4020_87 (
         .immediate_i (w_15),
         .pc_i (w_20),
         .old_pc_i (w_45),
         .rs1_i (w_16),
         .rs2_i (w_17),
         .result_o (w_51),
         .a_select_i (w_56),
         .b_select_i (w_57),
         .unit_select_i (w_58),
         .extension_operation_i (w_59),
         .alu_operation_i (w_60)
     );

JALR_TARGET blk4033_91 (
         .target_o (w_38),
         .jalr_i (w_55),
         .result_i (w_51)
     );

MEMORY blk4016_92 (
         .clk_i (clk),
         .rst_i (rst),
         .read_data_o (w_2),
         .address_i (w_27),
         .write_data_i (w_28),
         .byte_write_i (w_30),
         .read_enable_i (w_31),
         .write_enable_i (w_32)
     );


endmodule
`default_nettype wire
