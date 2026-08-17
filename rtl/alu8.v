`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module alu8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] alu_op,
    output reg  [7:0] result,
    output reg        carry_out
);

    always @(*) begin
        result    = 8'h00;
        carry_out = 1'b0;

        case (alu_op)
            `ALU_OP_PASS_B: begin
                result = b;
            end

            `ALU_OP_ADD: begin
                {carry_out, result} = {1'b0, a} + {1'b0, b};
            end

            `ALU_OP_SUB: begin
                result    = a - b;
                carry_out = (a >= b);
            end

            `ALU_OP_AND: begin
                result = a & b;
            end

            `ALU_OP_OR: begin
                result = a | b;
            end

            `ALU_OP_XOR: begin
                result = a ^ b;
            end

            `ALU_OP_SHL: begin
                result    = {a[6:0], 1'b0};
                carry_out = a[7];
            end

            `ALU_OP_SHR: begin
                result    = {1'b0, a[7:1]};
                carry_out = a[0];
            end

            default: begin
                // Keep the safe default outputs.
            end
        endcase
    end

endmodule

`default_nettype wire
