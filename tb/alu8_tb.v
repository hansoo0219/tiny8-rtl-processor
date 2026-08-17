`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module alu8_tb;

    reg  [7:0] a;
    reg  [7:0] b;
    reg  [2:0] alu_op;
    wire [7:0] result;
    wire       carry_out;

    integer cases_run;
    integer failures;
    integer test_number;
    integer failures_before_group;
    integer a_index;
    integer b_index;

    alu8 dut (
        .a         (a),
        .b         (b),
        .alu_op    (alu_op),
        .result    (result),
        .carry_out (carry_out)
    );

    function [8:0] reference_alu;
        input [2:0] operation;
        input [7:0] operand_a;
        input [7:0] operand_b;

        begin
            reference_alu = 9'h000;

            case (operation)
                `ALU_OP_PASS_B: reference_alu = {1'b0, operand_b};
                `ALU_OP_ADD:    reference_alu = {1'b0, operand_a}
                                             + {1'b0, operand_b};

                `ALU_OP_SUB: begin
                    reference_alu[7:0] = operand_a - operand_b;
                    reference_alu[8]   = (operand_a >= operand_b);
                end

                `ALU_OP_AND: reference_alu = {1'b0,
                                              operand_a & operand_b};
                `ALU_OP_OR:  reference_alu = {1'b0,
                                              operand_a | operand_b};
                `ALU_OP_XOR: reference_alu = {1'b0,
                                              operand_a ^ operand_b};
                `ALU_OP_SHL: reference_alu = {operand_a[7],
                                              operand_a[6:0], 1'b0};
                `ALU_OP_SHR: reference_alu = {operand_a[0], 1'b0,
                                              operand_a[7:1]};

                default: reference_alu = 9'h000;
            endcase
        end
    endfunction

    task check_case;
        input [2:0] operation;
        input [7:0] operand_a;
        input [7:0] operand_b;
        input [7:0] expected_result;
        input       expected_carry;

        begin
            cases_run = cases_run + 1;
            alu_op    = operation;
            a         = operand_a;
            b         = operand_b;

            #1;

            if ((result !== expected_result)
                    || (carry_out !== expected_carry)) begin
                failures = failures + 1;
                $display(
                    "  CASE %0d FAIL: op=%03b a=%02h b=%02h expected=%02h/%b actual=%02h/%b",
                    cases_run,
                    operation,
                    operand_a,
                    operand_b,
                    expected_result,
                    expected_carry,
                    result,
                    carry_out
                );
            end
        end
    endtask

    task check_reference;
        input [2:0] operation;
        input [7:0] operand_a;
        input [7:0] operand_b;
        reg   [8:0] expected;

        begin
            expected = reference_alu(operation, operand_a, operand_b);
            check_case(
                operation,
                operand_a,
                operand_b,
                expected[7:0],
                expected[8]
            );
        end
    endtask

    task start_group;
        begin
            failures_before_group = failures;
        end
    endtask

    task finish_group;
        input [8*32-1:0] group_name;

        begin
            test_number = test_number + 1;

            if (failures == failures_before_group) begin
                $display("TEST %02d %-24s PASS", test_number, group_name);
            end else begin
                $display("TEST %02d %-24s FAIL", test_number, group_name);
            end
        end
    endtask

    initial begin
        $dumpfile("build/alu8_tb.vcd");
        $dumpvars(0, alu8_tb);

        a                     = 8'h00;
        b                     = 8'h00;
        alu_op                = `ALU_OP_PASS_B;
        cases_run             = 0;
        failures              = 0;
        test_number           = 0;
        failures_before_group = 0;

        start_group;
        check_case(`ALU_OP_PASS_B, 8'h00, 8'h00, 8'h00, 1'b0);
        check_case(`ALU_OP_PASS_B, 8'h00, 8'hFF, 8'hFF, 1'b0);
        check_case(`ALU_OP_PASS_B, 8'hA5, 8'h3C, 8'h3C, 1'b0);
        finish_group("PASS_B");

        start_group;
        check_case(`ALU_OP_ADD, 8'h00, 8'h00, 8'h00, 1'b0);
        check_case(`ALU_OP_ADD, 8'h05, 8'h03, 8'h08, 1'b0);
        check_case(`ALU_OP_ADD, 8'h7F, 8'h01, 8'h80, 1'b0);
        check_case(`ALU_OP_ADD, 8'hFF, 8'h01, 8'h00, 1'b1);
        check_case(`ALU_OP_ADD, 8'hFF, 8'hFF, 8'hFE, 1'b1);
        finish_group("ADD");

        start_group;
        check_case(`ALU_OP_SUB, 8'h05, 8'h03, 8'h02, 1'b1);
        check_case(`ALU_OP_SUB, 8'h03, 8'h05, 8'hFE, 1'b0);
        check_case(`ALU_OP_SUB, 8'h05, 8'h05, 8'h00, 1'b1);
        check_case(`ALU_OP_SUB, 8'h00, 8'h01, 8'hFF, 1'b0);
        check_case(`ALU_OP_SUB, 8'hFF, 8'h00, 8'hFF, 1'b1);
        finish_group("SUB");

        start_group;
        check_case(`ALU_OP_AND, 8'h55, 8'hAA, 8'h00, 1'b0);
        check_case(`ALU_OP_AND, 8'hFF, 8'hA5, 8'hA5, 1'b0);
        finish_group("AND");

        start_group;
        check_case(`ALU_OP_OR, 8'h55, 8'hAA, 8'hFF, 1'b0);
        check_case(`ALU_OP_OR, 8'h00, 8'hA5, 8'hA5, 1'b0);
        finish_group("OR");

        start_group;
        check_case(`ALU_OP_XOR, 8'h55, 8'hAA, 8'hFF, 1'b0);
        check_case(`ALU_OP_XOR, 8'hFF, 8'hFF, 8'h00, 1'b0);
        check_case(`ALU_OP_XOR, 8'hA5, 8'h5A, 8'hFF, 1'b0);
        finish_group("XOR");

        start_group;
        check_case(`ALU_OP_SHL, 8'h00, 8'hA5, 8'h00, 1'b0);
        check_case(`ALU_OP_SHL, 8'h01, 8'hA5, 8'h02, 1'b0);
        check_case(`ALU_OP_SHL, 8'h80, 8'hA5, 8'h00, 1'b1);
        check_case(`ALU_OP_SHL, 8'hFF, 8'hA5, 8'hFE, 1'b1);
        finish_group("SHL");

        start_group;
        check_case(`ALU_OP_SHR, 8'h00, 8'h5A, 8'h00, 1'b0);
        check_case(`ALU_OP_SHR, 8'h02, 8'h5A, 8'h01, 1'b0);
        check_case(`ALU_OP_SHR, 8'h01, 8'h5A, 8'h00, 1'b1);
        check_case(`ALU_OP_SHR, 8'hFF, 8'h5A, 8'h7F, 1'b1);
        finish_group("SHR");

        start_group;
        for (a_index = 0; a_index < 256; a_index = a_index + 17) begin
            for (b_index = 0; b_index < 256; b_index = b_index + 51) begin
                check_reference(`ALU_OP_PASS_B, a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_ADD,    a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_SUB,    a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_AND,    a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_OR,     a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_XOR,    a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_SHL,    a_index[7:0], b_index[7:0]);
                check_reference(`ALU_OP_SHR,    a_index[7:0], b_index[7:0]);
            end
        end
        finish_group("REFERENCE SWEEP");

        if (failures == 0) begin
            $display(
                "ALL TESTS PASSED: %0d groups, %0d cases",
                test_number,
                cases_run
            );
            $finish;
        end else begin
            $fatal(
                1,
                "TESTS FAILED: %0d of %0d cases failed",
                failures,
                cases_run
            );
        end
    end

endmodule

`default_nettype wire
