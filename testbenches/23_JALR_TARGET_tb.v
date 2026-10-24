`timescale 1ns/1ps
module tb_JALR_TARGET;
reg [31:0] result_i;
reg jalr_i;
wire [31:0] target_o;
JALR_TARGET dut(.result_i(result_i),.jalr_i(jalr_i),.target_o(target_o));
integer errors=0, checks=0;
task check;
input [31:0] actual, expected;
input [255:0] label;
begin
 checks=checks+1;
 if(actual !== expected) begin errors=errors+1; $display("FAIL %s actual=%h expected=%h",label,actual,expected); end
end
endtask
initial begin
$dumpfile("waves/23_JALR_TARGET_tb.vcd"); $dumpvars(0,tb_JALR_TARGET);
result_i = 32'h00000000;
jalr_i = 32'h00000000;
result_i = 32'h00000000;
jalr_i = 32'h00000000;
#2;
check(target_o,32'h00000000,"target_o case 1");
result_i = 32'h00000000;
jalr_i = 32'h00000001;
#2;
check(target_o,32'h00000000,"target_o case 2");
result_i = 32'h00000001;
jalr_i = 32'h00000000;
#2;
check(target_o,32'h00000001,"target_o case 3");
result_i = 32'h00000001;
jalr_i = 32'h00000001;
#2;
check(target_o,32'h00000000,"target_o case 4");
result_i = 32'h00000002;
jalr_i = 32'h00000000;
#2;
check(target_o,32'h00000002,"target_o case 5");
result_i = 32'h00000002;
jalr_i = 32'h00000001;
#2;
check(target_o,32'h00000002,"target_o case 6");
result_i = 32'h00000003;
jalr_i = 32'h00000000;
#2;
check(target_o,32'h00000003,"target_o case 7");
result_i = 32'h00000003;
jalr_i = 32'h00000001;
#2;
check(target_o,32'h00000002,"target_o case 8");
result_i = 32'hffffffff;
jalr_i = 32'h00000000;
#2;
check(target_o,32'hffffffff,"target_o case 9");
result_i = 32'hffffffff;
jalr_i = 32'h00000001;
#2;
check(target_o,32'hfffffffe,"target_o case 10");
result_i = 32'h80000001;
jalr_i = 32'h00000000;
#2;
check(target_o,32'h80000001,"target_o case 11");
result_i = 32'h80000001;
jalr_i = 32'h00000001;
#2;
check(target_o,32'h80000000,"target_o case 12");
if(errors==0) $display("PASS JALR_TARGET: %0d checks",checks); else $display("FAIL JALR_TARGET: %0d errors",errors);
$finish;
end
initial begin #1000000; $display("FAIL timeout"); $finish; end
endmodule
