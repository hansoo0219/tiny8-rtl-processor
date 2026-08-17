`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module tiny8_system_tb;

    reg clk;
    reg reset;

    wire [7:0] out_data;
    wire       out_valid;
    wire       halted;
    wire [3:0] dbg_pc;
    wire [7:0] dbg_ir;
    wire [7:0] dbg_acc;
    wire       dbg_zero;
    wire       dbg_carry;
    wire [1:0] dbg_state;

    integer groups_run;
    integer checks_run;
    integer failures;
    integer failures_before_group;

    tiny8_system dut (
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

    always #5 clk = ~clk;

    task start_group;
        begin
            failures_before_group = failures;
        end
    endtask

    task finish_group;
        input [8*40-1:0] group_name;

        begin
            groups_run = groups_run + 1;

            if (failures == failures_before_group) begin
                $display("TEST %02d %-40s PASS", groups_run, group_name);
            end else begin
                $display("TEST %02d %-40s FAIL", groups_run, group_name);
            end
        end
    endtask

    task check_1bit;
        input [8*40-1:0] check_name;
        input              actual;
        input              expected;

        begin
            checks_run = checks_run + 1;

            if (actual !== expected) begin
                failures = failures + 1;
                $display(
                    "  CHECK %0d %-40s FAIL: expected=%b actual=%b time=%0t",
                    checks_run,
                    check_name,
                    expected,
                    actual,
                    $time
                );
            end
        end
    endtask

    task check_2bit;
        input [8*40-1:0] check_name;
        input [1:0]        actual;
        input [1:0]        expected;

        begin
            checks_run = checks_run + 1;

            if (actual !== expected) begin
                failures = failures + 1;
                $display(
                    "  CHECK %0d %-40s FAIL: expected=%02b actual=%02b time=%0t",
                    checks_run,
                    check_name,
                    expected,
                    actual,
                    $time
                );
            end
        end
    endtask

    task check_4bit;
        input [8*40-1:0] check_name;
        input [3:0]        actual;
        input [3:0]        expected;

        begin
            checks_run = checks_run + 1;

            if (actual !== expected) begin
                failures = failures + 1;
                $display(
                    "  CHECK %0d %-40s FAIL: expected=%h actual=%h time=%0t",
                    checks_run,
                    check_name,
                    expected,
                    actual,
                    $time
                );
            end
        end
    endtask

    task check_8bit;
        input [8*40-1:0] check_name;
        input [7:0]        actual;
        input [7:0]        expected;

        begin
            checks_run = checks_run + 1;

            if (actual !== expected) begin
                failures = failures + 1;
                $display(
                    "  CHECK %0d %-40s FAIL: expected=%02h actual=%02h time=%0t",
                    checks_run,
                    check_name,
                    expected,
                    actual,
                    $time
                );
            end
        end
    endtask

    task clock_edge;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check_reset_values;
        begin
            check_4bit("RESET PC", dbg_pc, 4'h0);
            check_8bit("RESET IR", dbg_ir, 8'h00);
            check_8bit("RESET ACC", dbg_acc, 8'h00);
            check_1bit("RESET ZERO", dbg_zero, 1'b1);
            check_1bit("RESET CARRY", dbg_carry, 1'b0);
            check_8bit("RESET OUTPUT DATA", out_data, 8'h00);
            check_1bit("RESET OUTPUT VALID", out_valid, 1'b0);
            check_2bit("RESET STATE", dbg_state, `STATE_FETCH);
            check_1bit("RESET HALTED", halted, 1'b0);
            check_1bit("RESET DATA WRITE", dut.data_we, 1'b0);
        end
    endtask

    initial begin
        $dumpfile("build/tiny8_system_tb.vcd");
        $dumpvars(
            0,
            clk,
            reset,
            dut.instr_addr,
            dut.instr_rdata,
            dut.data_addr,
            dut.data_rdata,
            dut.data_wdata,
            dut.data_we,
            out_data,
            out_valid,
            halted,
            dbg_pc,
            dbg_ir,
            dbg_acc,
            dbg_zero,
            dbg_carry,
            dbg_state
        );

        clk                   = 1'b0;
        reset                 = 1'b1;
        groups_run            = 0;
        checks_run            = 0;
        failures              = 0;
        failures_before_group = 0;

        start_group;
        clock_edge;
        check_reset_values;
        check_4bit("RESET PROGRAM ADDRESS", dut.instr_addr, 4'h0);
        check_8bit("RESET PROGRAM BYTE", dut.instr_rdata, 8'h15);

        reset = 1'b0;
        #1;
        check_2bit("FETCH ACTIVE AFTER RESET", dbg_state, `STATE_FETCH);
        finish_group("SYSTEM RESET AND ROM CONNECTION");

        start_group;
        clock_edge;
        check_2bit("LDI 5 FETCH STATE", dbg_state, `STATE_EXECUTE);
        check_4bit("LDI 5 FETCH PC", dbg_pc, 4'h1);
        check_8bit("LDI 5 FETCH IR", dbg_ir, 8'h15);
        clock_edge;
        check_8bit("LDI 5 RESULT", dbg_acc, 8'h05);
        check_1bit("LDI 5 ZERO", dbg_zero, 1'b0);

        clock_edge;
        check_8bit("STA 0 FETCH IR", dbg_ir, 8'h30);
        check_4bit("STA 0 RAM ADDRESS", dut.data_addr, 4'h0);
        check_8bit("STA 0 RAM WRITE DATA", dut.data_wdata, 8'h05);
        check_1bit("STA 0 RAM WRITE ENABLE", dut.data_we, 1'b1);
        clock_edge;
        check_1bit("STA 0 WRITE COMPLETES", dut.data_we, 1'b0);
        check_8bit("STA 0 RAM READBACK", dut.data_rdata, 8'h05);

        clock_edge;
        check_8bit("LDI 3 FETCH IR", dbg_ir, 8'h13);
        clock_edge;
        check_8bit("LDI 3 RESULT", dbg_acc, 8'h03);

        clock_edge;
        check_8bit("STA 1 FETCH IR", dbg_ir, 8'h31);
        check_4bit("STA 1 RAM ADDRESS", dut.data_addr, 4'h1);
        check_8bit("STA 1 RAM WRITE DATA", dut.data_wdata, 8'h03);
        check_1bit("STA 1 RAM WRITE ENABLE", dut.data_we, 1'b1);
        clock_edge;
        check_1bit("STA 1 WRITE COMPLETES", dut.data_we, 1'b0);
        check_8bit("STA 1 RAM READBACK", dut.data_rdata, 8'h03);

        clock_edge;
        check_8bit("LDA 0 FETCH IR", dbg_ir, 8'h20);
        check_4bit("LDA 0 RAM ADDRESS", dut.data_addr, 4'h0);
        check_8bit("LDA 0 RAM READ DATA", dut.data_rdata, 8'h05);
        clock_edge;
        check_8bit("LDA 0 RESULT", dbg_acc, 8'h05);

        clock_edge;
        check_8bit("ADD 1 FETCH IR", dbg_ir, 8'h41);
        check_4bit("ADD 1 RAM ADDRESS", dut.data_addr, 4'h1);
        check_8bit("ADD 1 RAM READ DATA", dut.data_rdata, 8'h03);
        clock_edge;
        check_8bit("ADD 1 RESULT", dbg_acc, 8'h08);
        check_1bit("ADD 1 ZERO", dbg_zero, 1'b0);
        check_1bit("ADD 1 CARRY", dbg_carry, 1'b0);

        clock_edge;
        check_8bit("OUT FETCH IR", dbg_ir, 8'hB0);
        check_1bit("OUT NOT VALID BEFORE COMMIT", out_valid, 1'b0);
        clock_edge;
        check_8bit("OUT RESULT DATA", out_data, 8'h08);
        check_1bit("OUT RESULT VALID", out_valid, 1'b1);

        clock_edge;
        check_8bit("HLT FETCH IR", dbg_ir, 8'hF0);
        check_4bit("HLT NEXT PC", dbg_pc, 4'h8);
        check_1bit("OUT VALID CLEARS AFTER ONE CYCLE", out_valid, 1'b0);
        check_8bit("OUT DATA RETAINS", out_data, 8'h08);
        check_1bit("HLT NOT EARLY", halted, 1'b0);
        clock_edge;
        check_2bit("HLT ENTERS HALT STATE", dbg_state, `STATE_HALT);
        check_1bit("HLT ASSERTS HALTED", halted, 1'b1);
        check_4bit("HLT HOLDS PC AFTER INSTRUCTION", dbg_pc, 4'h8);
        finish_group("INTEGRATED REFERENCE PROGRAM");

        start_group;
        repeat (3) begin
            clock_edge;
        end
        check_2bit("HALT STATE STABLE", dbg_state, `STATE_HALT);
        check_4bit("HALT PC STABLE", dbg_pc, 4'h8);
        check_8bit("HALT IR STABLE", dbg_ir, 8'hF0);
        check_8bit("HALT ACC STABLE", dbg_acc, 8'h08);
        check_1bit("HALT ZERO STABLE", dbg_zero, 1'b0);
        check_1bit("HALT CARRY STABLE", dbg_carry, 1'b0);
        check_8bit("HALT OUTPUT STABLE", out_data, 8'h08);
        check_1bit("HALT OUTPUT VALID LOW", out_valid, 1'b0);
        check_1bit("HALT RAM WRITE LOW", dut.data_we, 1'b0);
        finish_group("INTEGRATED HALT STABILITY");

        start_group;
        @(negedge clk);
        reset = 1'b1;
        #1;
        check_2bit("RESET ASSERTION WAITS FOR EDGE", dbg_state, `STATE_HALT);
        check_1bit("HALTED BEFORE RESET EDGE", halted, 1'b1);
        check_1bit("RESET MASKS RAM WRITE", dut.data_we, 1'b0);
        clock_edge;
        check_reset_values;
        check_8bit("DATA RAM SURVIVES RESET", dut.data_rdata, 8'h05);

        reset = 1'b0;
        #1;
        clock_edge;
        check_8bit("PROGRAM RESTART FETCH IR", dbg_ir, 8'h15);
        check_4bit("PROGRAM RESTART FETCH PC", dbg_pc, 4'h1);
        clock_edge;
        check_8bit("PROGRAM RESTART LDI RESULT", dbg_acc, 8'h05);
        finish_group("SYSTEM RESET RECOVERY AND RAM RETENTION");

        if (failures == 0) begin
            $display(
                "ALL TESTS PASSED: %0d groups, %0d checks",
                groups_run,
                checks_run
            );
            $finish;
        end else begin
            $fatal(
                1,
                "TESTS FAILED: %0d failures in %0d checks",
                failures,
                checks_run
            );
        end
    end

endmodule

`default_nettype wire
