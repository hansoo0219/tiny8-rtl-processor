`timescale 1ns/1ps
`default_nettype none

module data_ram_tb;

    reg        clk;
    reg        we;
    reg  [3:0] addr;
    reg  [7:0] wdata;
    wire [7:0] rdata;

    reg [7:0] expected_memory [0:15];

    integer address_index;
    integer cases_run;
    integer failures;
    integer test_number;
    integer failures_before_group;

    data_ram dut (
        .clk   (clk),
        .we    (we),
        .addr  (addr),
        .wdata (wdata),
        .rdata (rdata)
    );

    always #5 clk = ~clk;

    task check_value;
        input [8*32-1:0] check_name;
        input [7:0]      expected_value;

        begin
            cases_run = cases_run + 1;

            if (rdata !== expected_value) begin
                failures = failures + 1;
                $display(
                    "  CASE %0d %0s FAIL: addr=%h expected=%02h actual=%02h time=%0t",
                    cases_run,
                    check_name,
                    addr,
                    expected_value,
                    rdata,
                    $time
                );
            end
        end
    endtask

    task write_location;
        input [3:0] address;
        input [7:0] value;

        begin
            @(negedge clk);
            addr  = address;
            wdata = value;
            we    = 1'b1;

            @(posedge clk);
            #1;

            we                       = 1'b0;
            expected_memory[address] = value;
            check_value("WRITE COMMIT", value);
        end
    endtask

    task check_location;
        input [3:0] address;
        input [7:0] expected_value;

        begin
            addr = address;
            #1;
            check_value("COMBINATIONAL READ", expected_value);
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
        $dumpfile("build/data_ram_tb.vcd");
        $dumpvars(0, clk, we, addr, wdata, rdata);

        clk                   = 1'b0;
        we                    = 1'b0;
        addr                  = 4'h0;
        wdata                 = 8'h00;
        cases_run             = 0;
        failures              = 0;
        test_number           = 0;
        failures_before_group = 0;

        start_group;
        for (address_index = 0;
                address_index < 16;
                address_index = address_index + 1) begin
            write_location(
                address_index[3:0],
                8'hA0 + address_index[7:0]
            );
        end

        for (address_index = 0;
                address_index < 16;
                address_index = address_index + 1) begin
            check_location(
                address_index[3:0],
                expected_memory[address_index]
            );
        end
        finish_group("ALL ADDRESSES");

        start_group;
        @(negedge clk);
        addr  = 4'h3;
        wdata = 8'h5A;
        we    = 1'b1;

        #1;
        check_value("BEFORE RISING EDGE", expected_memory[3]);

        @(posedge clk);
        #1;
        expected_memory[3] = 8'h5A;
        check_value("AFTER RISING EDGE", expected_memory[3]);
        we = 1'b0;
        finish_group("SYNCHRONOUS WRITE");

        start_group;
        @(negedge clk);
        addr  = 4'h7;
        wdata = 8'h5A;
        we    = 1'b0;

        @(posedge clk);
        #1;
        check_value("WRITE DISABLED", expected_memory[7]);
        finish_group("WRITE ENABLE LOW");

        start_group;
        write_location(4'hA, 8'h3C);

        for (address_index = 0;
                address_index < 16;
                address_index = address_index + 1) begin
            check_location(
                address_index[3:0],
                expected_memory[address_index]
            );
        end
        finish_group("ADDRESS INDEPENDENCE");

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
