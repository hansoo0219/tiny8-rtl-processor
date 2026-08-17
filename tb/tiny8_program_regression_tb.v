`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

/* verilator lint_off DECLFILENAME */
module tiny8_program_checker #(
    parameter [8*24-1:0] TEST_NAME = "UNNAMED",
    parameter PROGRAM_FILE = "programs/add_5_3.hex",
    parameter integer EXPECTED_OUTPUT_COUNT = 1,
    parameter [7:0] EXPECTED_OUT_0 = 8'h00,
    parameter [7:0] EXPECTED_OUT_1 = 8'h00,
    parameter [7:0] EXPECTED_OUT_2 = 8'h00,
    parameter EXPECTED_ZERO_0 = 1'b0,
    parameter EXPECTED_ZERO_1 = 1'b0,
    parameter EXPECTED_ZERO_2 = 1'b0,
    parameter EXPECTED_CARRY_0 = 1'b0,
    parameter EXPECTED_CARRY_1 = 1'b0,
    parameter EXPECTED_CARRY_2 = 1'b0,
    parameter [3:0] EXPECTED_FINAL_PC = 4'h0,
    parameter [7:0] EXPECTED_FINAL_ACC = 8'h00,
    parameter EXPECTED_FINAL_ZERO = 1'b0,
    parameter EXPECTED_FINAL_CARRY = 1'b0,
    parameter integer MAX_CYCLES = 64
) (
    input  wire clk,
    input  wire reset,
    output reg  done,
    output reg  failed
);

    wire [7:0] out_data;
    wire       out_valid;
    wire       halted;
    wire [3:0] dbg_pc;
    wire [7:0] dbg_ir;
    wire [7:0] dbg_acc;
    wire       dbg_zero;
    wire       dbg_carry;
    wire [1:0] dbg_state;
    wire       final_mismatch;

    integer cycles_run;
    integer outputs_seen;

    tiny8_system #(
        .PROGRAM_FILE(PROGRAM_FILE)
    ) dut (
        .clk       (clk),
        .reset     (reset),
        .out_data  (out_data),
        .out_valid (out_valid),
        .halted    (halted),
        .dbg_pc    (dbg_pc),
        .dbg_ir    (dbg_ir),
        .dbg_acc   (dbg_acc),
        .dbg_zero  (dbg_zero),
        .dbg_carry (dbg_carry),
        .dbg_state (dbg_state)
    );

    function [7:0] expected_output;
        input integer output_index;

        begin
            case (output_index)
                0: expected_output = EXPECTED_OUT_0;
                1: expected_output = EXPECTED_OUT_1;
                2: expected_output = EXPECTED_OUT_2;
                default: expected_output = 8'h00;
            endcase
        end
    endfunction

    function expected_zero;
        input integer output_index;

        begin
            case (output_index)
                0: expected_zero = EXPECTED_ZERO_0;
                1: expected_zero = EXPECTED_ZERO_1;
                2: expected_zero = EXPECTED_ZERO_2;
                default: expected_zero = 1'b0;
            endcase
        end
    endfunction

    function expected_carry;
        input integer output_index;

        begin
            case (output_index)
                0: expected_carry = EXPECTED_CARRY_0;
                1: expected_carry = EXPECTED_CARRY_1;
                2: expected_carry = EXPECTED_CARRY_2;
                default: expected_carry = 1'b0;
            endcase
        end
    endfunction

    assign final_mismatch = (outputs_seen !== EXPECTED_OUTPUT_COUNT)
                          || (dbg_pc !== EXPECTED_FINAL_PC)
                          || (dbg_ir !== 8'hF0)
                          || (dbg_acc !== EXPECTED_FINAL_ACC)
                          || (dbg_zero !== EXPECTED_FINAL_ZERO)
                          || (dbg_carry !== EXPECTED_FINAL_CARRY)
                          || (dbg_state !== `STATE_HALT)
                          || (out_valid !== 1'b0)
                          || (out_data !== expected_output(
                              EXPECTED_OUTPUT_COUNT - 1
                          ));

    initial begin
        done         = 1'b0;
        failed       = 1'b0;
        cycles_run   = 0;
        outputs_seen = 0;
    end

    always @(negedge clk) begin
        if (reset) begin
            done         <= 1'b0;
            failed       <= 1'b0;
            cycles_run   <= 0;
            outputs_seen <= 0;
        end else if (!done) begin
            cycles_run <= cycles_run + 1;

            if (out_valid) begin
                if (outputs_seen >= EXPECTED_OUTPUT_COUNT) begin
                    failed <= 1'b1;
                    $display(
                        "  %-24s FAIL: unexpected output %02h at index %0d",
                        TEST_NAME,
                        out_data,
                        outputs_seen
                    );
                end else if ((out_data !== expected_output(outputs_seen))
                          || (dbg_zero !== expected_zero(outputs_seen))
                          || (dbg_carry !== expected_carry(outputs_seen))) begin
                    failed <= 1'b1;
                    $display(
                        "  %-24s FAIL: output %0d data=%02h/%02h z=%b/%b c=%b/%b",
                        TEST_NAME,
                        outputs_seen,
                        out_data,
                        expected_output(outputs_seen),
                        dbg_zero,
                        expected_zero(outputs_seen),
                        dbg_carry,
                        expected_carry(outputs_seen)
                    );
                end

                outputs_seen <= outputs_seen + 1;
            end

            if (halted) begin
                if (final_mismatch) begin
                    failed <= 1'b1;
                    $display(
                        "  %-24s FAIL: outputs=%0d/%0d pc=%h/%h ir=%02h acc=%02h/%02h z=%b/%b c=%b/%b state=%02b",
                        TEST_NAME,
                        outputs_seen,
                        EXPECTED_OUTPUT_COUNT,
                        dbg_pc,
                        EXPECTED_FINAL_PC,
                        dbg_ir,
                        dbg_acc,
                        EXPECTED_FINAL_ACC,
                        dbg_zero,
                        EXPECTED_FINAL_ZERO,
                        dbg_carry,
                        EXPECTED_FINAL_CARRY,
                        dbg_state
                    );
                end

                done <= 1'b1;

                if (failed || final_mismatch) begin
                    $display("TEST %-24s FAIL", TEST_NAME);
                end else begin
                    $display(
                        "TEST %-24s PASS: outputs=%0d cycles=%0d",
                        TEST_NAME,
                        outputs_seen,
                        cycles_run + 1
                    );
                end
            end else if ((cycles_run + 1) >= MAX_CYCLES) begin
                failed <= 1'b1;
                done   <= 1'b1;
                $display(
                    "TEST %-24s FAIL: timeout after %0d cycles",
                    TEST_NAME,
                    cycles_run + 1
                );
            end
        end
    end

endmodule
/* verilator lint_on DECLFILENAME */

module tiny8_program_regression_tb;

    reg clk;
    reg reset;

    wire [7:0] done;
    wire [7:0] failed;
    wire       all_done;

    assign all_done = &done;

    tiny8_program_checker #(
        .TEST_NAME("ADD_5_3"),
        .PROGRAM_FILE("programs/add_5_3.hex"),
        .EXPECTED_OUTPUT_COUNT(1),
        .EXPECTED_OUT_0(8'h08),
        .EXPECTED_FINAL_PC(4'h8),
        .EXPECTED_FINAL_ACC(8'h08),
        .EXPECTED_FINAL_ZERO(1'b0),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) add_5_3_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[0]),
        .failed (failed[0])
    );

    tiny8_program_checker #(
        .TEST_NAME("ADD_CARRY_ZERO"),
        .PROGRAM_FILE("programs/add_carry_zero.hex"),
        .EXPECTED_OUTPUT_COUNT(1),
        .EXPECTED_OUT_0(8'h00),
        .EXPECTED_ZERO_0(1'b1),
        .EXPECTED_CARRY_0(1'b1),
        .EXPECTED_FINAL_PC(4'hB),
        .EXPECTED_FINAL_ACC(8'h00),
        .EXPECTED_FINAL_ZERO(1'b1),
        .EXPECTED_FINAL_CARRY(1'b1)
    ) add_carry_zero_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[1]),
        .failed (failed[1])
    );

    tiny8_program_checker #(
        .TEST_NAME("SUB_FLAGS"),
        .PROGRAM_FILE("programs/sub_flags.hex"),
        .EXPECTED_OUTPUT_COUNT(2),
        .EXPECTED_OUT_0(8'h02),
        .EXPECTED_OUT_1(8'hFE),
        .EXPECTED_CARRY_0(1'b1),
        .EXPECTED_FINAL_PC(4'hB),
        .EXPECTED_FINAL_ACC(8'hFE),
        .EXPECTED_FINAL_ZERO(1'b0),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) sub_flags_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[2]),
        .failed (failed[2])
    );

    tiny8_program_checker #(
        .TEST_NAME("LOGIC_OPS"),
        .PROGRAM_FILE("programs/logic_ops.hex"),
        .EXPECTED_OUTPUT_COUNT(3),
        .EXPECTED_OUT_0(8'h08),
        .EXPECTED_OUT_1(8'h0A),
        .EXPECTED_OUT_2(8'h00),
        .EXPECTED_ZERO_2(1'b1),
        .EXPECTED_FINAL_PC(4'hA),
        .EXPECTED_FINAL_ACC(8'h00),
        .EXPECTED_FINAL_ZERO(1'b1),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) logic_ops_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[3]),
        .failed (failed[3])
    );

    tiny8_program_checker #(
        .TEST_NAME("SHIFT_FLAGS"),
        .PROGRAM_FILE("programs/shift_flags.hex"),
        .EXPECTED_OUTPUT_COUNT(3),
        .EXPECTED_OUT_0(8'h00),
        .EXPECTED_OUT_1(8'h00),
        .EXPECTED_OUT_2(8'h01),
        .EXPECTED_ZERO_0(1'b1),
        .EXPECTED_ZERO_1(1'b1),
        .EXPECTED_CARRY_0(1'b1),
        .EXPECTED_CARRY_1(1'b1),
        .EXPECTED_FINAL_PC(4'hE),
        .EXPECTED_FINAL_ACC(8'h01),
        .EXPECTED_FINAL_ZERO(1'b0),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) shift_flags_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[4]),
        .failed (failed[4])
    );

    tiny8_program_checker #(
        .TEST_NAME("JZ_PATHS"),
        .PROGRAM_FILE("programs/jz_paths.hex"),
        .EXPECTED_OUTPUT_COUNT(2),
        .EXPECTED_OUT_0(8'h01),
        .EXPECTED_OUT_1(8'h02),
        .EXPECTED_FINAL_PC(4'hA),
        .EXPECTED_FINAL_ACC(8'h02),
        .EXPECTED_FINAL_ZERO(1'b0),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) jz_paths_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[5]),
        .failed (failed[5])
    );

    tiny8_program_checker #(
        .TEST_NAME("JMP_WRAP"),
        .PROGRAM_FILE("programs/jmp_wrap.hex"),
        .EXPECTED_OUTPUT_COUNT(1),
        .EXPECTED_OUT_0(8'h01),
        .EXPECTED_FINAL_PC(4'h2),
        .EXPECTED_FINAL_ACC(8'h01),
        .EXPECTED_FINAL_ZERO(1'b0),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) jmp_wrap_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[6]),
        .failed (failed[6])
    );

    tiny8_program_checker #(
        .TEST_NAME("OUT_HALT"),
        .PROGRAM_FILE("programs/out_halt.hex"),
        .EXPECTED_OUTPUT_COUNT(1),
        .EXPECTED_OUT_0(8'h0A),
        .EXPECTED_FINAL_PC(4'h3),
        .EXPECTED_FINAL_ACC(8'h0A),
        .EXPECTED_FINAL_ZERO(1'b0),
        .EXPECTED_FINAL_CARRY(1'b0)
    ) out_halt_checker (
        .clk    (clk),
        .reset  (reset),
        .done   (done[7]),
        .failed (failed[7])
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/tiny8_program_regression_tb.vcd");
        $dumpvars(0, clk, reset, done, failed);

        clk   = 1'b0;
        reset = 1'b1;

        repeat (2) @(posedge clk);
        @(negedge clk);
        #1;
        reset = 1'b0;

        wait (all_done);
        #1;

        if (failed == 8'h00) begin
            $display("ALL PROGRAM TESTS PASSED: 8 images");
            $finish;
        end else begin
            $fatal(1, "PROGRAM REGRESSION FAILED: bitmap=%08b", failed);
        end
    end

    initial begin
        repeat (200) @(posedge clk);
        #1;

        if (!all_done) begin
            $fatal(1, "PROGRAM REGRESSION GLOBAL TIMEOUT");
        end
    end

endmodule

`default_nettype wire
