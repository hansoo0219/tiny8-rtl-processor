`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module instruction_decoder_tb;

    reg  [3:0] opcode;
    wire [2:0] alu_op;
    wire       operand_sel;
    wire       acc_we;
    wire       z_we;
    wire       c_we;
    wire       data_we;
    wire       out_we;
    wire       jump;
    wire       jump_zero;
    wire       halt;
    wire       reserved;

    integer tests_run;
    integer failures;

    instruction_decoder dut (
        .opcode      (opcode),
        .alu_op      (alu_op),
        .operand_sel (operand_sel),
        .acc_we      (acc_we),
        .z_we        (z_we),
        .c_we        (c_we),
        .data_we     (data_we),
        .out_we      (out_we),
        .jump        (jump),
        .jump_zero   (jump_zero),
        .halt        (halt),
        .reserved    (reserved)
    );

    task check_opcode;
        input [8*12-1:0] test_name;
        input [3:0]      test_opcode;
        input [2:0]      expected_alu_op;
        input            expected_operand_sel;
        input            expected_acc_we;
        input            expected_z_we;
        input            expected_c_we;
        input            expected_data_we;
        input            expected_out_we;
        input            expected_jump;
        input            expected_jump_zero;
        input            expected_halt;
        input            expected_reserved;

        begin
            tests_run = tests_run + 1;
            opcode    = test_opcode;

            #1;

            if ((alu_op      !== expected_alu_op)
                    || (operand_sel !== expected_operand_sel)
                    || (acc_we      !== expected_acc_we)
                    || (z_we        !== expected_z_we)
                    || (c_we        !== expected_c_we)
                    || (data_we     !== expected_data_we)
                    || (out_we      !== expected_out_we)
                    || (jump        !== expected_jump)
                    || (jump_zero   !== expected_jump_zero)
                    || (halt        !== expected_halt)
                    || (reserved    !== expected_reserved)) begin
                failures = failures + 1;
                $display("TEST %02d %-12s FAIL", tests_run, test_name);
                $display(
                    "  opcode=%h alu=%03b operand=%b acc=%b z=%b c=%b data=%b out=%b jump=%b jz=%b halt=%b reserved=%b",
                    opcode,
                    alu_op,
                    operand_sel,
                    acc_we,
                    z_we,
                    c_we,
                    data_we,
                    out_we,
                    jump,
                    jump_zero,
                    halt,
                    reserved
                );
                $display(
                    "  expect   alu=%03b operand=%b acc=%b z=%b c=%b data=%b out=%b jump=%b jz=%b halt=%b reserved=%b",
                    expected_alu_op,
                    expected_operand_sel,
                    expected_acc_we,
                    expected_z_we,
                    expected_c_we,
                    expected_data_we,
                    expected_out_we,
                    expected_jump,
                    expected_jump_zero,
                    expected_halt,
                    expected_reserved
                );
            end else begin
                $display("TEST %02d %-12s PASS", tests_run, test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("build/instruction_decoder_tb.vcd");
        $dumpvars(
            0,
            opcode,
            alu_op,
            operand_sel,
            acc_we,
            z_we,
            c_we,
            data_we,
            out_we,
            jump,
            jump_zero,
            halt,
            reserved
        );

        opcode    = `OPCODE_NOP;
        tests_run = 0;
        failures  = 0;

        check_opcode("NOP", `OPCODE_NOP,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("LDI", `OPCODE_LDI,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("LDA", `OPCODE_LDA,
            `ALU_OP_PASS_B, `OPERAND_SEL_MEMORY,
            1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("STA", `OPCODE_STA,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("ADD", `OPCODE_ADD,
            `ALU_OP_ADD, `OPERAND_SEL_MEMORY,
            1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("SUB", `OPCODE_SUB,
            `ALU_OP_SUB, `OPERAND_SEL_MEMORY,
            1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("AND", `OPCODE_AND,
            `ALU_OP_AND, `OPERAND_SEL_MEMORY,
            1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("OR", `OPCODE_OR,
            `ALU_OP_OR, `OPERAND_SEL_MEMORY,
            1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("XOR", `OPCODE_XOR,
            `ALU_OP_XOR, `OPERAND_SEL_MEMORY,
            1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("JMP", `OPCODE_JMP,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);

        check_opcode("JZ", `OPCODE_JZ,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);

        check_opcode("OUT", `OPCODE_OUT,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("SHL", `OPCODE_SHL,
            `ALU_OP_SHL, `OPERAND_SEL_IMMEDIATE,
            1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("SHR", `OPCODE_SHR,
            `ALU_OP_SHR, `OPERAND_SEL_IMMEDIATE,
            1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        check_opcode("RESERVED", `OPCODE_RESERVED,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        check_opcode("HLT", `OPCODE_HLT,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE,
            1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);

        if (failures == 0) begin
            $display("ALL TESTS PASSED: %0d opcodes", tests_run);
            $finish;
        end else begin
            $fatal(
                1,
                "TESTS FAILED: %0d of %0d opcodes failed",
                failures,
                tests_run
            );
        end
    end

endmodule

`default_nettype wire
