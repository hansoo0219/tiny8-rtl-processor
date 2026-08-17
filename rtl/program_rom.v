`timescale 1ns/1ps
`default_nettype none

module program_rom #(
    parameter INIT_FILE = "programs/add_5_3.hex"
) (
    input  wire [3:0] addr,
    output wire [7:0] rdata
);

    reg [7:0] memory [0:15];

    initial begin
        $readmemh(INIT_FILE, memory);
    end

    assign rdata = memory[addr];

endmodule

`default_nettype wire
