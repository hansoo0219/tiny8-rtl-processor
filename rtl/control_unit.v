`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module control_unit (
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] opcode,
    input  wire       zero_flag,
    output reg        ir_we,
    output reg        pc_inc,
    output reg        pc_load,
    output reg  [2:0] alu_op,
    output reg        operand_sel,
    output reg        acc_we,
    output reg        z_we,
    output reg        c_we,
    output reg        data_we,
    output reg        out_we,
    output wire [1:0] state,
    output reg        halted
);

    reg [1:0] state_reg;
    reg [1:0] next_state;

    wire [2:0] decoded_alu_op;
    wire       decoded_operand_sel;
    wire       decoded_acc_we;
    wire       decoded_z_we;
    wire       decoded_c_we;
    wire       decoded_data_we;
    wire       decoded_out_we;
    wire       decoded_jump;
    wire       decoded_jump_zero;
    wire       decoded_halt;
    wire       decoded_reserved;

    instruction_decoder decoder_inst (
        .opcode      (opcode),
        .alu_op      (decoded_alu_op),
        .operand_sel (decoded_operand_sel),
        .acc_we      (decoded_acc_we),
        .z_we        (decoded_z_we),
        .c_we        (decoded_c_we),
        .data_we     (decoded_data_we),
        .out_we      (decoded_out_we),
        .jump        (decoded_jump),
        .jump_zero   (decoded_jump_zero),
        .halt        (decoded_halt),
        .reserved    (decoded_reserved)
    );

    assign state = state_reg;

    always @(posedge clk) begin
        if (reset) begin
            state_reg <= `STATE_FETCH;
        end else begin
            state_reg <= next_state;
        end
    end

    always @(*) begin
        next_state = `STATE_FETCH;
        ir_we       = 1'b0;
        pc_inc      = 1'b0;
        pc_load     = 1'b0;
        alu_op      = `ALU_OP_PASS_B;
        operand_sel = `OPERAND_SEL_IMMEDIATE;
        acc_we      = 1'b0;
        z_we        = 1'b0;
        c_we        = 1'b0;
        data_we     = 1'b0;
        out_we      = 1'b0;
        halted      = 1'b0;

        case (state_reg)
            `STATE_FETCH: begin
                next_state = `STATE_EXECUTE;
                ir_we       = 1'b1;
                pc_inc      = 1'b1;
            end

            `STATE_EXECUTE: begin
                alu_op      = decoded_alu_op;
                operand_sel = decoded_operand_sel;
                acc_we      = decoded_acc_we;
                z_we        = decoded_z_we;
                c_we        = decoded_c_we;
                data_we     = decoded_data_we;
                out_we      = decoded_out_we;
                pc_load     = decoded_jump
                            | (decoded_jump_zero & zero_flag);

                if (decoded_halt) begin
                    next_state = `STATE_HALT;
                end else if (decoded_reserved) begin
                    next_state = `STATE_FETCH;
                end else begin
                    next_state = `STATE_FETCH;
                end
            end

            `STATE_HALT: begin
                next_state = `STATE_HALT;
                halted     = 1'b1;
            end

            default: begin
                next_state = `STATE_FETCH;
            end
        endcase

        if (reset) begin
            next_state = `STATE_FETCH;
            ir_we       = 1'b0;
            pc_inc      = 1'b0;
            pc_load     = 1'b0;
            alu_op      = `ALU_OP_PASS_B;
            operand_sel = `OPERAND_SEL_IMMEDIATE;
            acc_we      = 1'b0;
            z_we        = 1'b0;
            c_we        = 1'b0;
            data_we     = 1'b0;
            out_we      = 1'b0;
        end
    end

endmodule

`default_nettype wire
