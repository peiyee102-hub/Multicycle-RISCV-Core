`timescale 1ns/1ps
`default_nettype none
module INSTRUCTION_DECODER(input wire [31:0] instruction_i,
    output reg legal_o,register_write_o,
    output reg [2:0] kind_o,
    output reg [1:0] a_select_o,b_select_o,unit_select_o,
    output reg [3:0] alu_operation_o,
    output wire [1:0] extension_operation_o);
    wire [6:0] opcode,funct7;
    wire [2:0] funct3;
    assign opcode=instruction_i[6:0];
    assign funct7=instruction_i[31:25];
    assign funct3=instruction_i[14:12];
    assign extension_operation_o=funct3[1:0];
    always @* begin
        legal_o=0; register_write_o=0; kind_o=0;
        a_select_o=0; b_select_o=0; unit_select_o=0; alu_operation_o=1;
        case(opcode)
            7'h33,7'h13: begin
                register_write_o=1;
                b_select_o=(opcode==7'h13) ? 1 : 0;
                if(opcode==7'h33 && funct7==7'h01) begin
                    unit_select_o=1; legal_o=(funct3<=3);
                end else if(opcode==7'h33 && funct7==7'h40) begin
                    unit_select_o=2; legal_o=(funct3<=2);
                end else begin
                    case(funct3)
                        0: begin
                            alu_operation_o=(opcode==7'h33 && funct7==7'h20)?2:1;
                            legal_o=(opcode==7'h13 || funct7==0 || funct7==7'h20);
                        end
                        1: begin alu_operation_o=6; legal_o=(funct7==0); end
                        2: begin alu_operation_o=9; legal_o=(opcode==7'h13 || funct7==0); end
                        3: begin alu_operation_o=10;legal_o=(opcode==7'h13 || funct7==0); end
                        4: begin alu_operation_o=5; legal_o=(opcode==7'h13 || funct7==0); end
                        5: begin alu_operation_o=(funct7==7'h20)?8:7;legal_o=(funct7==0 || funct7==7'h20); end
                        6: begin alu_operation_o=4; legal_o=(opcode==7'h13 || funct7==0); end
                        7: begin alu_operation_o=3; legal_o=(opcode==7'h13 || funct7==0); end
                    endcase
                end
            end
            7'h03: begin kind_o=1; b_select_o=1;register_write_o=1;
                legal_o=(funct3==0 || funct3==1 || funct3==2 || funct3==4 || funct3==5); end
            7'h23: begin kind_o=2;b_select_o=1;legal_o=(funct3<=2);end
            7'h63: begin kind_o=3;a_select_o=2;b_select_o=1;
                legal_o=(funct3==0 || funct3==1 || funct3>=4);end
            7'h6f: begin kind_o=4;a_select_o=2;b_select_o=1;register_write_o=1;legal_o=1;end
            7'h67: begin kind_o=5;b_select_o=1;register_write_o=1;legal_o=(funct3==0);end
            7'h37: begin a_select_o=3;b_select_o=1;alu_operation_o=0;register_write_o=1;legal_o=1;end
            7'h17: begin a_select_o=2;b_select_o=1;register_write_o=1;legal_o=1;end
            // Base FENCE: all memory operations complete before the next fetch.
            // Reserved fm/rs1/rd fields ignored as required for a base implementation.
            7'h0f: begin kind_o=6;legal_o=(funct3==0);end
            7'h73: begin kind_o=7;
                legal_o=(instruction_i==32'h00000073 || instruction_i==32'h00100073);end
        endcase
    end
endmodule
`default_nettype wire
