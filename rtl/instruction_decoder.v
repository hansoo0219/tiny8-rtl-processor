`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module instruction_decoder (
    input  wire [3:0] opcode,
    output reg  [2:0] alu_op,
    output reg        operand_sel,
    output reg        acc_we,
    output reg        z_we,
    output reg        c_we,
    output reg        data_we,
    output reg        out_we,
    output reg        jump,
    output reg        jump_zero,
    output reg        halt,
    output reg        reserved
);

    always @(*) begin
        alu_op      = `ALU_OP_PASS_B;
        operand_sel = `OPERAND_SEL_IMMEDIATE;
        acc_we      = 1'b0;
        z_we        = 1'b0;
        c_we        = 1'b0;
        data_we     = 1'b0;
        out_we      = 1'b0;
        jump        = 1'b0;
        jump_zero   = 1'b0;
        halt        = 1'b0;
        reserved    = 1'b0;

        case (opcode)
            `OPCODE_NOP: begin
            end

            `OPCODE_LDI: begin
                alu_op      = `ALU_OP_PASS_B;
                operand_sel = `OPERAND_SEL_IMMEDIATE;
                acc_we      = 1'b1;
                z_we        = 1'b1;
            end

            `OPCODE_LDA: begin
                alu_op      = `ALU_OP_PASS_B;
                operand_sel = `OPERAND_SEL_MEMORY;
                acc_we      = 1'b1;
                z_we        = 1'b1;
            end

            `OPCODE_STA: begin
                data_we = 1'b1;
            end

            `OPCODE_ADD: begin
                alu_op      = `ALU_OP_ADD;
                operand_sel = `OPERAND_SEL_MEMORY;
                acc_we      = 1'b1;
                z_we        = 1'b1;
                c_we        = 1'b1;
            end

            `OPCODE_SUB: begin
                alu_op      = `ALU_OP_SUB;
                operand_sel = `OPERAND_SEL_MEMORY;
                acc_we      = 1'b1;
                z_we        = 1'b1;
                c_we        = 1'b1;
            end

            `OPCODE_AND: begin
                alu_op      = `ALU_OP_AND;
                operand_sel = `OPERAND_SEL_MEMORY;
                acc_we      = 1'b1;
                z_we        = 1'b1;
            end

            `OPCODE_OR: begin
                alu_op      = `ALU_OP_OR;
                operand_sel = `OPERAND_SEL_MEMORY;
                acc_we      = 1'b1;
                z_we        = 1'b1;
            end

            `OPCODE_XOR: begin
                alu_op      = `ALU_OP_XOR;
                operand_sel = `OPERAND_SEL_MEMORY;
                acc_we      = 1'b1;
                z_we        = 1'b1;
            end

            `OPCODE_JMP: begin
                jump = 1'b1;
            end

            `OPCODE_JZ: begin
                jump_zero = 1'b1;
            end

            `OPCODE_OUT: begin
                out_we = 1'b1;
            end

            `OPCODE_SHL: begin
                alu_op = `ALU_OP_SHL;
                acc_we = 1'b1;
                z_we   = 1'b1;
                c_we   = 1'b1;
            end

            `OPCODE_SHR: begin
                alu_op = `ALU_OP_SHR;
                acc_we = 1'b1;
                z_we   = 1'b1;
                c_we   = 1'b1;
            end

            `OPCODE_RESERVED: begin
                reserved = 1'b1;
            end

            `OPCODE_HLT: begin
                halt = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule

`default_nettype wire
