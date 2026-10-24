`timescale 1ns/1ps
`default_nettype none
module MAIN_FSM(
    input wire clk_i,rst_i,legal_i,
    input wire [2:0] kind_i,
    output reg [3:0] state_o
);
    localparam FETCH=0,DECODE=1,EXECUTE=2,MEM_REQUEST=3,
               MEM_CAPTURE=4,WRITEBACK=5,HALT=6;
    reg [3:0] next_state;
    always @* begin
        next_state=HALT;
        case(state_o)
            FETCH: next_state=DECODE;
            DECODE: next_state=legal_i ? EXECUTE : HALT;
            EXECUTE: begin
                if(kind_i==7) next_state=HALT;
                else if(kind_i==1 || kind_i==2) next_state=MEM_REQUEST;
                else next_state=WRITEBACK;
            end
            MEM_REQUEST: begin
                next_state=(kind_i==1) ? MEM_CAPTURE : WRITEBACK;
            end
            MEM_CAPTURE: next_state=WRITEBACK;
            WRITEBACK: next_state=FETCH;
            HALT: next_state=HALT;
        endcase
    end
    always @(posedge clk_i) begin
        if(rst_i) state_o<=FETCH;
        else state_o<=next_state;
    end
endmodule
`default_nettype wire
