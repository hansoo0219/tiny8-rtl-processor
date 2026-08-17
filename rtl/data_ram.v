`timescale 1ns/1ps
`default_nettype none

module data_ram (
    input  wire       clk,
    input  wire       we,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata
);

    reg [7:0] memory [0:15];

    assign rdata = memory[addr];

    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= wdata;
        end
    end

endmodule

`default_nettype wire
