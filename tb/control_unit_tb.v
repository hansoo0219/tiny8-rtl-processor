`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module control_unit_tb;

    reg        clk;
    reg        reset;
    reg  [3:0] opcode;
    reg        zero_flag;

    wire       ir_we;
    wire       pc_inc;
    wire       pc_load;
    wire [2:0] alu_op;
    wire       operand_sel;
    wire       acc_we;
    wire       z_we;
    wire       c_we;
    wire       data_we;
    wire       out_we;
    wire [1:0] state;
    wire       halted;

    integer groups_run;
    integer cases_run;
    integer failures;
    integer failures_before_group;

    reg [8:0] actual_enables;

    localparam [8:0] ENABLE_NONE = 9'b000000000;
    localparam [8:0] ENABLE_FETCH = 9'b110000000;
    localparam [8:0] ENABLE_ACC_Z = 9'b000110000;
    localparam [8:0] ENABLE_ACC_Z_C = 9'b000111000;
    localparam [8:0] ENABLE_DATA_WRITE = 9'b000000100;
    localparam [8:0] ENABLE_OUT_WRITE = 9'b000000010;
    localparam [8:0] ENABLE_PC_LOAD = 9'b001000000;
    localparam [8:0] ENABLE_HALTED = 9'b000000001;

    control_unit dut (
        .clk         (clk),
        .reset       (reset),
        .opcode      (opcode),
        .zero_flag   (zero_flag),
        .ir_we       (ir_we),
        .pc_inc      (pc_inc),
        .pc_load     (pc_load),
        .alu_op      (alu_op),
        .operand_sel (operand_sel),
        .acc_we      (acc_we),
        .z_we        (z_we),
        .c_we        (c_we),
        .data_we     (data_we),
        .out_we      (out_we),
        .state       (state),
        .halted      (halted)
    );

    always #5 clk = ~clk;

    task start_group;
        begin
            failures_before_group = failures;
        end
    endtask

    task finish_group;
        input [8*32-1:0] group_name;

        begin
            groups_run = groups_run + 1;

            if (failures == failures_before_group) begin
                $display("TEST %02d %-32s PASS", groups_run, group_name);
            end else begin
                $display("TEST %02d %-32s FAIL", groups_run, group_name);
            end
        end
    endtask

    task check_controls;
        input [8*32-1:0] check_name;
        input [1:0]      expected_state;
        input [2:0]      expected_alu_op;
        input            expected_operand_sel;
        input [8:0]      expected_enables;

        begin
            cases_run      = cases_run + 1;
            actual_enables = {
                ir_we,
                pc_inc,
                pc_load,
                acc_we,
                z_we,
                c_we,
                data_we,
                out_we,
                halted
            };

            if ((state          !== expected_state)
                    || (alu_op      !== expected_alu_op)
                    || (operand_sel !== expected_operand_sel)
                    || (actual_enables !== expected_enables)) begin
                failures = failures + 1;
                $display("  CASE %0d %-32s FAIL", cases_run, check_name);
                $display(
                    "    actual: state=%02b alu=%03b operand=%b enables=%09b time=%0t",
                    state,
                    alu_op,
                    operand_sel,
                    actual_enables,
                    $time
                );
                $display(
                    "    expect: state=%02b alu=%03b operand=%b enables=%09b",
                    expected_state,
                    expected_alu_op,
                    expected_operand_sel,
                    expected_enables
                );
            end

            if ((pc_inc === 1'b1) && (pc_load === 1'b1)) begin
                failures = failures + 1;
                $display(
                    "  CASE %0d %-32s FAIL: pc_inc and pc_load overlap",
                    cases_run,
                    check_name
                );
            end
        end
    endtask

    task check_fetch_active;
        input [8*32-1:0] check_name;

        begin
            check_controls(
                check_name,
                `STATE_FETCH,
                `ALU_OP_PASS_B,
                `OPERAND_SEL_IMMEDIATE,
                ENABLE_FETCH
            );
        end
    endtask

    task run_execute_case;
        input [8*32-1:0] check_name;
        input [3:0]      test_opcode;
        input            test_zero_flag;
        input [2:0]      expected_alu_op;
        input            expected_operand_sel;
        input [8:0]      expected_enables;

        begin
            @(negedge clk);
            opcode    = test_opcode;
            zero_flag = test_zero_flag;

            @(posedge clk);
            #1;
            check_controls(
                check_name,
                `STATE_EXECUTE,
                expected_alu_op,
                expected_operand_sel,
                expected_enables
            );

            @(posedge clk);
            #1;
            check_fetch_active("RETURN TO FETCH");
        end
    endtask

    initial begin
        $dumpfile("build/control_unit_tb.vcd");
        $dumpvars(
            0,
            clk,
            reset,
            opcode,
            zero_flag,
            state,
            halted,
            ir_we,
            pc_inc,
            pc_load,
            alu_op,
            operand_sel,
            acc_we,
            z_we,
            c_we,
            data_we,
            out_we
        );

        clk                   = 1'b0;
        reset                 = 1'b1;
        opcode                = `OPCODE_STA;
        zero_flag             = 1'b1;
        groups_run            = 0;
        cases_run             = 0;
        failures              = 0;
        failures_before_group = 0;
        actual_enables        = ENABLE_NONE;

        start_group;
        @(posedge clk);
        #1;
        check_controls(
            "SYNCHRONOUS RESET EDGE",
            `STATE_FETCH,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_NONE
        );
        reset = 1'b0;
        #1;
        check_fetch_active("FETCH AFTER RESET");
        finish_group("RESET AND FETCH");

        start_group;
        run_execute_case(
            "NOP", `OPCODE_NOP, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_NONE
        );
        run_execute_case(
            "LDI", `OPCODE_LDI, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_ACC_Z
        );
        run_execute_case(
            "LDA", `OPCODE_LDA, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_MEMORY, ENABLE_ACC_Z
        );
        run_execute_case(
            "STA", `OPCODE_STA, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_DATA_WRITE
        );
        run_execute_case(
            "ADD", `OPCODE_ADD, 1'b0,
            `ALU_OP_ADD, `OPERAND_SEL_MEMORY, ENABLE_ACC_Z_C
        );
        run_execute_case(
            "SUB", `OPCODE_SUB, 1'b0,
            `ALU_OP_SUB, `OPERAND_SEL_MEMORY, ENABLE_ACC_Z_C
        );
        run_execute_case(
            "AND", `OPCODE_AND, 1'b0,
            `ALU_OP_AND, `OPERAND_SEL_MEMORY, ENABLE_ACC_Z
        );
        run_execute_case(
            "OR", `OPCODE_OR, 1'b0,
            `ALU_OP_OR, `OPERAND_SEL_MEMORY, ENABLE_ACC_Z
        );
        run_execute_case(
            "XOR", `OPCODE_XOR, 1'b0,
            `ALU_OP_XOR, `OPERAND_SEL_MEMORY, ENABLE_ACC_Z
        );
        run_execute_case(
            "OUT", `OPCODE_OUT, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_OUT_WRITE
        );
        run_execute_case(
            "SHL", `OPCODE_SHL, 1'b0,
            `ALU_OP_SHL, `OPERAND_SEL_IMMEDIATE, ENABLE_ACC_Z_C
        );
        run_execute_case(
            "SHR", `OPCODE_SHR, 1'b0,
            `ALU_OP_SHR, `OPERAND_SEL_IMMEDIATE, ENABLE_ACC_Z_C
        );
        run_execute_case(
            "RESERVED", `OPCODE_RESERVED, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_NONE
        );
        finish_group("EXECUTE CONTROL GATING");

        start_group;
        run_execute_case(
            "JMP", `OPCODE_JMP, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_PC_LOAD
        );
        run_execute_case(
            "JZ NOT TAKEN", `OPCODE_JZ, 1'b0,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_NONE
        );
        run_execute_case(
            "JZ TAKEN", `OPCODE_JZ, 1'b1,
            `ALU_OP_PASS_B, `OPERAND_SEL_IMMEDIATE, ENABLE_PC_LOAD
        );
        finish_group("BRANCH CONTROLS");

        start_group;
        @(negedge clk);
        opcode = `OPCODE_STA;
        reset  = 1'b0;
        @(posedge clk);
        #1;
        check_controls(
            "STA EXECUTE",
            `STATE_EXECUTE,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_DATA_WRITE
        );
        @(negedge clk);
        reset = 1'b1;
        #1;
        check_controls(
            "RESET MASKS STA",
            `STATE_EXECUTE,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_NONE
        );
        @(posedge clk);
        #1;
        check_controls(
            "RESET RETURNS FETCH",
            `STATE_FETCH,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_NONE
        );
        reset = 1'b0;
        #1;
        check_fetch_active("FETCH AFTER WRITE GUARD");
        finish_group("RESET WRITE GUARD");

        start_group;
        @(negedge clk);
        opcode = `OPCODE_HLT;
        @(posedge clk);
        #1;
        check_controls(
            "HLT EXECUTE",
            `STATE_EXECUTE,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_NONE
        );
        @(posedge clk);
        #1;
        check_controls(
            "ENTER HALT",
            `STATE_HALT,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_HALTED
        );
        @(negedge clk);
        opcode = `OPCODE_STA;
        repeat (2) begin
            @(posedge clk);
            #1;
            check_controls(
                "HALT STABLE",
                `STATE_HALT,
                `ALU_OP_PASS_B,
                `OPERAND_SEL_IMMEDIATE,
                ENABLE_HALTED
            );
        end
        finish_group("HALT ENTRY AND STABILITY");

        start_group;
        @(negedge clk);
        reset = 1'b1;
        #1;
        check_controls(
            "RESET ASSERTED IN HALT",
            `STATE_HALT,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_HALTED
        );
        @(posedge clk);
        #1;
        check_controls(
            "HALT RESET EDGE",
            `STATE_FETCH,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_NONE
        );
        reset = 1'b0;
        #1;
        check_fetch_active("FETCH AFTER HALT RESET");
        finish_group("HALT RESET RECOVERY");

        start_group;
        @(negedge clk);
        opcode        = `OPCODE_STA;
        dut.state_reg = `STATE_INVALID;
        #1;
        check_controls(
            "INVALID STATE SAFE",
            `STATE_INVALID,
            `ALU_OP_PASS_B,
            `OPERAND_SEL_IMMEDIATE,
            ENABLE_NONE
        );
        @(posedge clk);
        #1;
        check_fetch_active("INVALID RECOVERS FETCH");
        finish_group("INVALID STATE RECOVERY");

        if (failures == 0) begin
            $display(
                "ALL TESTS PASSED: %0d groups, %0d checks",
                groups_run,
                cases_run
            );
            $finish;
        end else begin
            $fatal(
                1,
                "TESTS FAILED: %0d failures in %0d checks",
                failures,
                cases_run
            );
        end
    end

endmodule

`default_nettype wire
