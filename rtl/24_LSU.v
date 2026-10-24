`timescale 1ns/1ps
`default_nettype none
module LSU(
    input wire [31:0] address_i,store_data_i,memory_data_i,
    input wire [2:0] funct3_i,
    input wire read_enable_i,write_enable_i,
    output wire [31:0] address_o,write_data_o,
    output reg [31:0] load_data_o,
    output reg [3:0] byte_write_o,
    output wire read_enable_o,write_enable_o
);
    wire [31:0] shifted_data;
    assign address_o=address_i;
    assign write_data_o=store_data_i << {address_i[1:0],3'b0};
    assign shifted_data=memory_data_i >> {address_i[1:0],3'b0};
    assign read_enable_o=read_enable_i;
    assign write_enable_o=write_enable_i;
    always @* begin
        byte_write_o=0;
        case(funct3_i)
            0,4: byte_write_o=4'b0001<<address_i[1:0];
            1,5: begin byte_write_o=4'b0011<<address_i[1:0]; end
            2: begin byte_write_o=4'b1111; end
            default: byte_write_o=0;
        endcase
        if(!write_enable_i) byte_write_o=0;
        case(funct3_i)
            0: load_data_o={{24{shifted_data[7]}},shifted_data[7:0]};
            1: load_data_o={{16{shifted_data[15]}},shifted_data[15:0]};
            2: load_data_o=shifted_data;
            4: load_data_o={24'b0,shifted_data[7:0]};
            5: load_data_o={16'b0,shifted_data[15:0]};
            default: load_data_o=0;
        endcase
    end
endmodule
`default_nettype wire
