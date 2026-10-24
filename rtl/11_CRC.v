`timescale 1ns/1ps
`default_nettype none
module CRC (
    input  wire [31:0] data_i,
    input  wire [31:0] seed_i,
    input  wire [1:0]  operation_i,

    output reg  [31:0] result_o
);

    wire [15:0] seed;

    wire [7:0] stage1_data;
    wire [7:0] stage2_data;
    wire [7:0] stage3_data;
    wire [7:0] stage4_data;

    wire [15:0] crc_stage1;
    wire [15:0] crc_stage2;
    wire [15:0] crc_stage3;
    wire [15:0] crc_stage4;


    assign seed = seed_i[15:0];


    // --------------------------------------------------------
    // Select the first byte according to operation.
    //
    // CRCB:
    //     data[7:0]
    //
    // CRCH:
    //     data[15:8] -> data[7:0]
    //
    // CRCW:
    //     data[31:24] -> data[23:16]
    //     -> data[15:8] -> data[7:0]
    // --------------------------------------------------------

    assign stage1_data =
        (operation_i == 2'd0) ? data_i[7:0]   :
        (operation_i == 2'd1) ? data_i[15:8]  :
        (operation_i == 2'd2) ? data_i[31:24] :
                                8'b0;


    assign stage2_data =
        (operation_i == 2'd1) ? data_i[7:0]   :
        (operation_i == 2'd2) ? data_i[23:16] :
                                8'b0;


    assign stage3_data =
        (operation_i == 2'd2) ? data_i[15:8] :
                                8'b0;


    assign stage4_data =
        (operation_i == 2'd2) ? data_i[7:0] :
                                8'b0;


    // --------------------------------------------------------
    // Shared CRC chain
    // --------------------------------------------------------

    CRC_BYTE crc_byte_1 (
        .data_i (stage1_data),
        .crc_i  (seed),
        .crc_o  (crc_stage1)
    );


    CRC_BYTE crc_byte_2 (
        .data_i (stage2_data),
        .crc_i  (crc_stage1),
        .crc_o  (crc_stage2)
    );


    CRC_BYTE crc_byte_3 (
        .data_i (stage3_data),
        .crc_i  (crc_stage2),
        .crc_o  (crc_stage3)
    );


    CRC_BYTE crc_byte_4 (
        .data_i (stage4_data),
        .crc_i  (crc_stage3),
        .crc_o  (crc_stage4)
    );


    // --------------------------------------------------------
    // Result selection
    // --------------------------------------------------------

    always @(*) begin

        case (operation_i)

            2'd0:
                result_o = {16'b0, crc_stage1};

            2'd1:
                result_o = {16'b0, crc_stage2};

            2'd2:
                result_o = {16'b0, crc_stage4};

            default:
                result_o = 32'b0;

        endcase

    end

endmodule
`default_nettype wire
