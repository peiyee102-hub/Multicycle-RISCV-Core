`timescale 1ns/1ps
`default_nettype none
module CRC_BYTE (
    input  wire [7:0]  data_i,
    input  wire [15:0] crc_i,

    output reg  [15:0] crc_o
);

    reg [15:0] crc;
    integer i;

    always @(*) begin

        crc = crc_i;

        for (i = 7; i >= 0; i = i - 1) begin

            if (crc[15] ^ data_i[i])

                crc = {crc[14:0], 1'b0}
                    ^ 16'h1021;

            else

                crc = {crc[14:0], 1'b0};

        end

        crc_o = crc;

    end

endmodule
`default_nettype wire
