`timescale 1ns/1ps
`default_nettype none

module program_rom_tb;

    reg  [3:0] addr;
    wire [7:0] rdata;

    integer address_index;
    integer tests_run;
    integer failures;
    integer test_number;
    integer failures_before_group;

`ifdef PROGRAM_ROM_NETLIST
    program_rom dut (
        .addr  (addr),
        .rdata (rdata)
    );
`else
    program_rom #(
        .INIT_FILE("programs/add_5_3.hex")
    ) dut (
        .addr  (addr),
        .rdata (rdata)
    );
`endif

    function [7:0] expected_instruction;
        input [3:0] address;

        begin
            case (address)
                4'h0: expected_instruction = 8'h15;
                4'h1: expected_instruction = 8'h30;
                4'h2: expected_instruction = 8'h13;
                4'h3: expected_instruction = 8'h31;
                4'h4: expected_instruction = 8'h20;
                4'h5: expected_instruction = 8'h41;
                4'h6: expected_instruction = 8'hB0;
                default: expected_instruction = 8'hF0;
            endcase
        end
    endfunction

    task check_address;
        input [3:0] address;

        reg [7:0] expected_value;

        begin
            addr = address;
            #1;

            tests_run      = tests_run + 1;
            expected_value = expected_instruction(address);

            if (rdata !== expected_value) begin
                failures = failures + 1;
                $display(
                    "  CASE %0d FAIL: addr=%h expected=%02h actual=%02h time=%0t",
                    tests_run,
                    address,
                    expected_value,
                    rdata,
                    $time
                );
            end
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
        $dumpfile("build/program_rom_tb.vcd");
        $dumpvars(0, addr, rdata);

        addr                  = 4'h0;
        tests_run             = 0;
        failures              = 0;
        test_number           = 0;
        failures_before_group = 0;

        start_group;
        for (address_index = 0;
                address_index < 8;
                address_index = address_index + 1) begin
            check_address(address_index[3:0]);
        end
        finish_group("PROGRAM BYTES");

        start_group;
        for (address_index = 8;
                address_index < 16;
                address_index = address_index + 1) begin
            check_address(address_index[3:0]);
        end
        finish_group("UNUSED LOCATIONS");

        if (failures == 0) begin
            $display(
                "ALL TESTS PASSED: %0d groups, %0d addresses",
                test_number,
                tests_run
            );
            $finish;
        end else begin
            $fatal(
                1,
                "TESTS FAILED: %0d of %0d addresses failed",
                failures,
                tests_run
            );
        end
    end

endmodule

`default_nettype wire
