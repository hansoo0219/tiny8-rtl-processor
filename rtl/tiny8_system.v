`timescale 1ns/1ps
`default_nettype none

module tiny8_system #(
    parameter PROGRAM_FILE = "programs/add_5_3.hex"
) (
    input  wire       clk,
    input  wire       reset,
    output wire [7:0] out_data,
    output wire       out_valid,
    output wire       halted,
    output wire [3:0] dbg_pc,
    output wire [7:0] dbg_ir,
    output wire [7:0] dbg_acc,
    output wire       dbg_zero,
    output wire       dbg_carry,
    output wire [1:0] dbg_state
);

    wire [3:0] instr_addr;
    wire [7:0] instr_rdata;
    wire [3:0] data_addr;
    wire [7:0] data_rdata;
    wire [7:0] data_wdata;
    wire       data_we;

    program_rom #(
        .INIT_FILE(PROGRAM_FILE)
    ) program_rom_inst (
        .addr  (instr_addr),
        .rdata (instr_rdata)
    );

    data_ram data_ram_inst (
        .clk   (clk),
        .we    (data_we),
        .addr  (data_addr),
        .wdata (data_wdata),
        .rdata (data_rdata)
    );

    tiny8_core core_inst (
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

endmodule

`default_nettype wire
