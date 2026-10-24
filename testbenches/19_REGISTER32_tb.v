`timescale 1ns/1ps
module tb_REGISTER32;
reg clk_i;
reg rst_i;
reg enable_i;
reg [31:0] data_i;
wire [31:0] data_o;
REGISTER32 dut(.clk_i(clk_i),.rst_i(rst_i),.enable_i(enable_i),.data_i(data_i),.data_o(data_o));
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
$dumpfile("waves/19_REGISTER32_tb.vcd"); $dumpvars(0,tb_REGISTER32);
clk_i = 32'h00000000;
rst_i = 32'h00000000;
enable_i = 32'h00000000;
data_i = 32'h00000000;
rst_i = 32'h00000001;
data_i = 32'h0000007b;
enable_i = 32'h00000001;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h00000000,"data_o case 1");
rst_i = 32'h00000000;
enable_i = 32'h00000001;
data_i = 32'h00000000;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h00000000,"data_o case 2");
enable_i = 32'h00000000;
data_i = 32'hffffffff;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h00000000,"data_o case 3");
enable_i = 32'h00000001;
data_i = 32'hffffffff;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'hffffffff,"data_o case 4");
enable_i = 32'h00000000;
data_i = 32'h00000000;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'hffffffff,"data_o case 5");
enable_i = 32'h00000001;
data_i = 32'h12345678;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h12345678,"data_o case 6");
enable_i = 32'h00000000;
data_i = 32'hedcba987;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h12345678,"data_o case 7");
enable_i = 32'h00000001;
data_i = 32'h80000000;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h80000000,"data_o case 8");
enable_i = 32'h00000000;
data_i = 32'h7fffffff;
clk_i=0; #5; clk_i=1; #5; clk_i=0; #1;
#2;
check(data_o,32'h80000000,"data_o case 9");
if(errors==0) $display("PASS REGISTER32: %0d checks",checks); else $display("FAIL REGISTER32: %0d errors",errors);
$finish;
end
initial begin #1000000; $display("FAIL timeout"); $finish; end
endmodule
