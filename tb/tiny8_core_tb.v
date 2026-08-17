`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module tiny8_core_tb;

    reg clk;
    reg reset;

    wire [3:0] instr_addr;
    wire [7:0] instr_rdata;
    wire [3:0] data_addr;
    wire [7:0] data_rdata;
    wire [7:0] data_wdata;
    wire       data_we;
    wire [7:0] out_data;
    wire       out_valid;
    wire       halted;
    wire [3:0] dbg_pc;
    wire [7:0] dbg_ir;
    wire [7:0] dbg_acc;
    wire       dbg_zero;
    wire       dbg_carry;
    wire [1:0] dbg_state;

    reg [7:0] instruction_memory [0:15];
    reg [7:0] data_memory [0:15];

    integer memory_index;
    integer groups_run;
    integer checks_run;
    integer failures;
    integer failures_before_group;

    assign instr_rdata = instruction_memory[instr_addr];
    assign data_rdata  = data_memory[data_addr];

    tiny8_core dut (
        .clk         (clk),
        .reset       (reset),
        .instr_rdata (instr_rdata),
        .data_rdata  (data_rdata),
        .instr_addr  (instr_addr),
        .data_addr   (data_addr),
        .data_wdata  (data_wdata),
        .data_we     (data_we),
        .out_data    (out_data),
        .out_valid   (out_valid),
        .halted      (halted),
        .dbg_pc      (dbg_pc),
        .dbg_ir      (dbg_ir),
        .dbg_acc     (dbg_acc),
        .dbg_zero    (dbg_zero),
        .dbg_carry   (dbg_carry),
        .dbg_state   (dbg_state)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (data_we) begin
            data_memory[data_addr] <= data_wdata;
        end
    end

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

    task run_instruction;
        begin
            clock_edge;
            clock_edge;
        end
    endtask

    task prepare_test;
        integer index;

        begin
            @(negedge clk);
            reset = 1'b1;
            #1;

            for (index = 0; index < 16; index = index + 1) begin
                instruction_memory[index] = 8'hF0;
                data_memory[index]        = 8'h00;
            end
        end
    endtask

    task release_reset;
        begin
            clock_edge;
            reset = 1'b0;
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
            check_8bit("RESET OUT DATA", out_data, 8'h00);
            check_1bit("RESET OUT VALID", out_valid, 1'b0);
            check_2bit("RESET STATE", dbg_state, `STATE_FETCH);
            check_1bit("RESET HALTED", halted, 1'b0);
            check_1bit("RESET DATA WRITE", data_we, 1'b0);
        end
    endtask

    initial begin
        $dumpfile("build/tiny8_core_tb.vcd");
        $dumpvars(
            0,
            clk,
            reset,
            instr_addr,
            instr_rdata,
            data_addr,
            data_rdata,
            data_wdata,
            data_we,
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

        for (memory_index = 0;
                memory_index < 16;
                memory_index = memory_index + 1) begin
            instruction_memory[memory_index] = 8'hF0;
            data_memory[memory_index]        = 8'h00;
        end

        instruction_memory[0] = 8'h15;

        start_group;
        clock_edge;
        check_reset_values;

        reset = 1'b0;
        #1;
        check_2bit("FETCH STATE AFTER RESET", dbg_state, `STATE_FETCH);
        check_4bit("FETCH ADDRESS AFTER RESET", instr_addr, 4'h0);

        clock_edge;
        check_2bit("FIRST FETCH ENTERS EXECUTE", dbg_state, `STATE_EXECUTE);
        check_4bit("FIRST FETCH INCREMENTS PC", dbg_pc, 4'h1);
        check_8bit("FIRST FETCH LOADS IR", dbg_ir, 8'h15);
        check_8bit("FETCH PRESERVES ACC", dbg_acc, 8'h00);

        clock_edge;
        check_2bit("LDI RETURNS FETCH", dbg_state, `STATE_FETCH);
        check_4bit("LDI PRESERVES PC", dbg_pc, 4'h1);
        check_8bit("LDI ZERO EXTENDS IMMEDIATE", dbg_acc, 8'h05);
        check_1bit("LDI UPDATES ZERO", dbg_zero, 1'b0);
        check_1bit("LDI PRESERVES CARRY", dbg_carry, 1'b0);
        finish_group("RESET, FETCH, AND LDI TIMING");

        prepare_test;
        instruction_memory[0] = 8'h15;
        instruction_memory[1] = 8'h30;
        instruction_memory[2] = 8'h13;
        instruction_memory[3] = 8'h31;
        instruction_memory[4] = 8'h20;
        instruction_memory[5] = 8'h41;
        instruction_memory[6] = 8'hB0;
        instruction_memory[7] = 8'hF0;
        release_reset;

        start_group;
        run_instruction;
        check_8bit("REFERENCE LDI 5", dbg_acc, 8'h05);

        clock_edge;
        check_2bit("STA 0 EXECUTE STATE", dbg_state, `STATE_EXECUTE);
        check_4bit("STA 0 ADDRESS", data_addr, 4'h0);
        check_8bit("STA 0 WRITE DATA", data_wdata, 8'h05);
        check_1bit("STA 0 WRITE ENABLE", data_we, 1'b1);
        check_8bit("STA 0 BEFORE EDGE", data_memory[0], 8'h00);
        clock_edge;
        check_1bit("STA 0 WRITE ENDS", data_we, 1'b0);
        check_8bit("STA 0 COMMITTED", data_memory[0], 8'h05);

        run_instruction;
        check_8bit("REFERENCE LDI 3", dbg_acc, 8'h03);
        run_instruction;
        check_8bit("STA 1 COMMITTED", data_memory[1], 8'h03);
        run_instruction;
        check_8bit("REFERENCE LDA 0", dbg_acc, 8'h05);
        run_instruction;
        check_8bit("REFERENCE ADD 1", dbg_acc, 8'h08);
        check_1bit("REFERENCE ADD ZERO", dbg_zero, 1'b0);
        check_1bit("REFERENCE ADD CARRY", dbg_carry, 1'b0);

        clock_edge;
        check_1bit("OUT BEFORE COMMIT", out_valid, 1'b0);
        clock_edge;
        check_8bit("REFERENCE OUTPUT DATA", out_data, 8'h08);
        check_1bit("REFERENCE OUTPUT VALID", out_valid, 1'b1);

        clock_edge;
        check_1bit("OUTPUT PULSE CLEARS", out_valid, 1'b0);
        check_8bit("OUTPUT DATA RETAINS", out_data, 8'h08);
        clock_edge;
        check_2bit("REFERENCE PROGRAM HALTS", dbg_state, `STATE_HALT);
        check_1bit("REFERENCE HALTED", halted, 1'b1);
        check_4bit("PC AFTER REFERENCE HLT", dbg_pc, 4'h8);
        finish_group("REFERENCE 5 PLUS 3 PROGRAM");

        prepare_test;
        instruction_memory[0] = 8'h20;
        instruction_memory[1] = 8'h41;
        instruction_memory[2] = 8'h22;
        instruction_memory[3] = 8'h53;
        instruction_memory[4] = 8'h24;
        instruction_memory[5] = 8'h55;
        instruction_memory[6] = 8'h56;
        data_memory[0]        = 8'hFF;
        data_memory[1]        = 8'h01;
        data_memory[2]        = 8'h05;
        data_memory[3]        = 8'h03;
        data_memory[4]        = 8'h03;
        data_memory[5]        = 8'h05;
        data_memory[6]        = 8'hFE;
        release_reset;

        start_group;
        run_instruction;
        check_8bit("LDA FF", dbg_acc, 8'hFF);
        check_1bit("LDA FF ZERO", dbg_zero, 1'b0);
        check_1bit("LDA PRESERVES CARRY 0", dbg_carry, 1'b0);
        run_instruction;
        check_8bit("ADD WRAPS TO ZERO", dbg_acc, 8'h00);
        check_1bit("ADD ZERO FLAG", dbg_zero, 1'b1);
        check_1bit("ADD CARRY FLAG", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("LDA 5", dbg_acc, 8'h05);
        check_1bit("LDA PRESERVES CARRY 1", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("SUB NO BORROW RESULT", dbg_acc, 8'h02);
        check_1bit("SUB NO BORROW CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("LDA 3", dbg_acc, 8'h03);
        check_1bit("SECOND LDA PRESERVES CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("SUB BORROW RESULT", dbg_acc, 8'hFE);
        check_1bit("SUB BORROW CARRY", dbg_carry, 1'b0);
        check_1bit("SUB BORROW ZERO", dbg_zero, 1'b0);
        run_instruction;
        check_8bit("SUB EQUAL RESULT", dbg_acc, 8'h00);
        check_1bit("SUB EQUAL NO BORROW", dbg_carry, 1'b1);
        check_1bit("SUB EQUAL ZERO", dbg_zero, 1'b1);
        finish_group("ADD AND SUB FLAG BEHAVIOR");

        prepare_test;
        instruction_memory[0] = 8'h20;
        instruction_memory[1] = 8'h41;
        instruction_memory[2] = 8'h22;
        instruction_memory[3] = 8'h63;
        instruction_memory[4] = 8'h24;
        instruction_memory[5] = 8'h75;
        instruction_memory[6] = 8'h86;
        instruction_memory[7] = 8'h00;
        instruction_memory[8] = 8'hEA;
        data_memory[0]        = 8'hFF;
        data_memory[1]        = 8'h01;
        data_memory[2]        = 8'hF0;
        data_memory[3]        = 8'h0F;
        data_memory[4]        = 8'h55;
        data_memory[5]        = 8'h0A;
        data_memory[6]        = 8'h5F;
        release_reset;

        start_group;
        run_instruction;
        run_instruction;
        check_8bit("LOGIC SETUP ADD RESULT", dbg_acc, 8'h00);
        check_1bit("LOGIC SETUP CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("LOGIC LDA F0", dbg_acc, 8'hF0);
        check_1bit("LOGIC LDA KEEPS CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("AND RESULT", dbg_acc, 8'h00);
        check_1bit("AND ZERO", dbg_zero, 1'b1);
        check_1bit("AND KEEPS CARRY", dbg_carry, 1'b1);
        run_instruction;
        run_instruction;
        check_8bit("OR RESULT", dbg_acc, 8'h5F);
        check_1bit("OR KEEPS CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("XOR RESULT", dbg_acc, 8'h00);
        check_1bit("XOR ZERO", dbg_zero, 1'b1);
        check_1bit("XOR KEEPS CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("NOP PRESERVES ACC", dbg_acc, 8'h00);
        check_1bit("NOP PRESERVES ZERO", dbg_zero, 1'b1);
        check_1bit("NOP PRESERVES CARRY", dbg_carry, 1'b1);
        run_instruction;
        check_8bit("RESERVED PRESERVES ACC", dbg_acc, 8'h00);
        check_1bit("RESERVED PRESERVES ZERO", dbg_zero, 1'b1);
        check_1bit("RESERVED PRESERVES CARRY", dbg_carry, 1'b1);
        check_1bit("RESERVED DOES NOT WRITE RAM", data_we, 1'b0);
        finish_group("LOGIC AND PRESERVED STATE");

        prepare_test;
        instruction_memory[0] = 8'h20;
        instruction_memory[1] = 8'hC0;
        instruction_memory[2] = 8'h21;
        instruction_memory[3] = 8'hD0;
        instruction_memory[4] = 8'h22;
        instruction_memory[5] = 8'hD0;
        instruction_memory[6] = 8'hC0;
        data_memory[0]        = 8'h80;
        data_memory[1]        = 8'h01;
        data_memory[2]        = 8'h02;
        release_reset;

        start_group;
        run_instruction;
        run_instruction;
        check_8bit("SHL 80 RESULT", dbg_acc, 8'h00);
        check_1bit("SHL 80 ZERO", dbg_zero, 1'b1);
        check_1bit("SHL 80 CARRY", dbg_carry, 1'b1);
        run_instruction;
        run_instruction;
        check_8bit("SHR 01 RESULT", dbg_acc, 8'h00);
        check_1bit("SHR 01 ZERO", dbg_zero, 1'b1);
        check_1bit("SHR 01 CARRY", dbg_carry, 1'b1);
        run_instruction;
        run_instruction;
        check_8bit("SHR 02 RESULT", dbg_acc, 8'h01);
        check_1bit("SHR 02 ZERO", dbg_zero, 1'b0);
        check_1bit("SHR 02 CARRY", dbg_carry, 1'b0);
        run_instruction;
        check_8bit("SHL 01 RESULT", dbg_acc, 8'h02);
        check_1bit("SHL 01 ZERO", dbg_zero, 1'b0);
        check_1bit("SHL 01 CARRY", dbg_carry, 1'b0);
        finish_group("SHIFT RESULT AND CARRY");

        prepare_test;
        instruction_memory[0]  = 8'h11;
        instruction_memory[1]  = 8'hA4;
        instruction_memory[2]  = 8'h12;
        instruction_memory[3]  = 8'h96;
        instruction_memory[4]  = 8'h1E;
        instruction_memory[5]  = 8'h1D;
        instruction_memory[6]  = 8'h10;
        instruction_memory[7]  = 8'hAA;
        instruction_memory[8]  = 8'h1C;
        instruction_memory[9]  = 8'h1B;
        instruction_memory[10] = 8'h17;
        instruction_memory[11] = 8'hB0;
        instruction_memory[12] = 8'hF0;
        release_reset;

        start_group;
        run_instruction;
        check_8bit("BRANCH LDI 1", dbg_acc, 8'h01);
        run_instruction;
        check_4bit("JZ NOT TAKEN PC", dbg_pc, 4'h2);
        run_instruction;
        check_8bit("NOT TAKEN FALLTHROUGH", dbg_acc, 8'h02);
        run_instruction;
        check_4bit("JMP TARGET PC", dbg_pc, 4'h6);
        check_8bit("JMP SKIPS ACC WRITES", dbg_acc, 8'h02);
        run_instruction;
        check_8bit("BRANCH LDI ZERO", dbg_acc, 8'h00);
        check_1bit("BRANCH ZERO SET", dbg_zero, 1'b1);
        run_instruction;
        check_4bit("JZ TAKEN TARGET PC", dbg_pc, 4'hA);
        run_instruction;
        check_8bit("TAKEN TARGET EXECUTES", dbg_acc, 8'h07);
        run_instruction;
        check_8bit("BRANCH PROGRAM OUTPUT", out_data, 8'h07);
        check_1bit("BRANCH PROGRAM OUT VALID", out_valid, 1'b1);
        clock_edge;
        check_1bit("BRANCH OUT PULSE CLEARS", out_valid, 1'b0);
        clock_edge;
        check_2bit("BRANCH PROGRAM HALT STATE", dbg_state, `STATE_HALT);
        check_1bit("BRANCH PROGRAM HALTED", halted, 1'b1);
        check_4bit("BRANCH PROGRAM FINAL PC", dbg_pc, 4'hD);
        finish_group("JMP AND JZ CONTROL FLOW");

        prepare_test;
        instruction_memory[0]  = 8'h9F;
        instruction_memory[15] = 8'hEA;
        release_reset;

        start_group;
        run_instruction;
        check_4bit("JMP F TARGET", dbg_pc, 4'hF);
        clock_edge;
        check_8bit("FETCH AT F LOADS RESERVED", dbg_ir, 8'hEA);
        check_4bit("FETCH AT F WRAPS PC", dbg_pc, 4'h0);
        check_2bit("WRAP FETCH ENTERS EXECUTE", dbg_state, `STATE_EXECUTE);
        clock_edge;
        check_4bit("RESERVED KEEPS WRAPPED PC", dbg_pc, 4'h0);
        check_8bit("RESERVED KEEPS ACC", dbg_acc, 8'h00);
        check_1bit("RESERVED KEEPS ZERO", dbg_zero, 1'b1);
        check_1bit("RESERVED KEEPS CARRY", dbg_carry, 1'b0);
        check_1bit("RESERVED KEEPS RAM OFF", data_we, 1'b0);
        clock_edge;
        check_8bit("WRAP FETCHES ADDRESS ZERO", dbg_ir, 8'h9F);
        check_4bit("POST-WRAP FETCH PC", dbg_pc, 4'h1);
        finish_group("PC WRAP AND RESERVED OPCODE");

        prepare_test;
        instruction_memory[0] = 8'h1A;
        instruction_memory[1] = 8'h33;
        data_memory[3]        = 8'h5A;
        release_reset;

        start_group;
        run_instruction;
        check_8bit("RESET GUARD LDI A", dbg_acc, 8'h0A);
        clock_edge;
        check_2bit("RESET GUARD STA EXECUTE", dbg_state, `STATE_EXECUTE);
        check_4bit("RESET GUARD STA ADDRESS", data_addr, 4'h3);
        check_8bit("RESET GUARD STA DATA", data_wdata, 8'h0A);
        check_1bit("RESET GUARD STA ENABLE", data_we, 1'b1);
        check_8bit("RESET GUARD SENTINEL BEFORE", data_memory[3], 8'h5A);
        @(negedge clk);
        reset = 1'b1;
        #1;
        check_2bit("RESET ASSERTION IS SYNCHRONOUS", dbg_state, `STATE_EXECUTE);
        check_1bit("RESET IMMEDIATELY MASKS STA", data_we, 1'b0);
        clock_edge;
        check_reset_values;
        check_8bit("RESET BLOCKED STA WRITE", data_memory[3], 8'h5A);
        reset = 1'b0;
        #1;
        finish_group("RESET BLOCKS PENDING STA");

        prepare_test;
        instruction_memory[0] = 8'h1A;
        instruction_memory[1] = 8'hB0;
        instruction_memory[2] = 8'h00;
        instruction_memory[3] = 8'hF0;
        data_memory[5]        = 8'hA5;
        release_reset;

        start_group;
        run_instruction;
        run_instruction;
        check_8bit("OUT CAPTURES ACC", out_data, 8'h0A);
        check_1bit("OUT VALID FOR FETCH CYCLE", out_valid, 1'b1);
        clock_edge;
        check_1bit("NEXT FETCH CLEARS OUT VALID", out_valid, 1'b0);
        check_8bit("NEXT FETCH RETAINS OUT DATA", out_data, 8'h0A);
        clock_edge;
        check_8bit("NOP RETAINS OUT DATA", out_data, 8'h0A);
        clock_edge;
        check_2bit("HLT EXECUTE PHASE", dbg_state, `STATE_EXECUTE);
        check_1bit("HLT NOT EARLY", halted, 1'b0);
        clock_edge;
        check_2bit("HLT ENTERS HALT", dbg_state, `STATE_HALT);
        check_1bit("HLT ASSERTS HALTED", halted, 1'b1);
        check_4bit("HLT HOLDS NEXT PC", dbg_pc, 4'h4);

        repeat (3) begin
            clock_edge;
        end
        check_4bit("HALT STABLE PC", dbg_pc, 4'h4);
        check_8bit("HALT STABLE IR", dbg_ir, 8'hF0);
        check_8bit("HALT STABLE ACC", dbg_acc, 8'h0A);
        check_1bit("HALT STABLE ZERO", dbg_zero, 1'b0);
        check_1bit("HALT STABLE CARRY", dbg_carry, 1'b0);
        check_8bit("HALT STABLE OUT", out_data, 8'h0A);
        check_1bit("HALT OUT VALID LOW", out_valid, 1'b0);
        check_1bit("HALT DATA WRITE LOW", data_we, 1'b0);
        check_8bit("HALT RAM UNCHANGED", data_memory[5], 8'hA5);

        @(negedge clk);
        reset = 1'b1;
        #1;
        check_2bit("HALT WAITS FOR RESET EDGE", dbg_state, `STATE_HALT);
        check_1bit("HALTED HIGH BEFORE RESET EDGE", halted, 1'b1);
        check_1bit("RESET MASKS HALT WRITES", data_we, 1'b0);
        clock_edge;
        check_reset_values;
        check_8bit("RESET PRESERVES DATA RAM", data_memory[5], 8'hA5);
        reset = 1'b0;
        #1;
        check_2bit("RESET RECOVERY FETCH", dbg_state, `STATE_FETCH);
        check_4bit("RESET RECOVERY ADDRESS ZERO", instr_addr, 4'h0);
        finish_group("OUT PULSE, HALT, AND RESET RECOVERY");

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
