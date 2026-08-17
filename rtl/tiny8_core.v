`timescale 1ns/1ps
`default_nettype none

`include "tiny8_defs.vh"

module tiny8_core (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] instr_rdata,
    input  wire [7:0] data_rdata,
    output wire [3:0] instr_addr,
    output wire [3:0] data_addr,
    output wire [7:0] data_wdata,
    output wire       data_we,
    output reg  [7:0] out_data,
    output reg        out_valid,
    output wire       halted,
    output wire [3:0] dbg_pc,
    output wire [7:0] dbg_ir,
    output wire [7:0] dbg_acc,
    output wire       dbg_zero,
    output wire       dbg_carry,
    output wire [1:0] dbg_state
);

    reg [3:0] pc_reg;
    reg [7:0] ir_reg;
    reg [7:0] acc_reg;
    reg       zero_reg;
    reg       carry_reg;

    wire       ir_we;
    wire       pc_inc;
    wire       pc_load;
    wire [2:0] alu_op;
    wire       operand_sel;
    wire       acc_we;
    wire       z_we;
    wire       c_we;
    wire       out_we;

    wire [7:0] immediate_operand;
    wire [7:0] alu_operand_b;
    wire [7:0] alu_result;
    wire       alu_carry_out;

    assign instr_addr       = pc_reg;
    assign data_addr        = ir_reg[3:0];
    assign data_wdata       = acc_reg;
    assign immediate_operand = {4'h0, ir_reg[3:0]};
    assign alu_operand_b    = (operand_sel == `OPERAND_SEL_MEMORY)
                            ? data_rdata
                            : immediate_operand;

    assign dbg_pc    = pc_reg;
    assign dbg_ir    = ir_reg;
    assign dbg_acc   = acc_reg;
    assign dbg_zero  = zero_reg;
    assign dbg_carry = carry_reg;

    control_unit control_inst (
        .clk         (clk),
        .reset       (reset),
        .opcode      (ir_reg[7:4]),
        .zero_flag   (zero_reg),
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
        .state       (dbg_state),
        .halted      (halted)
    );

    alu8 alu_inst (
        .a         (acc_reg),
        .b         (alu_operand_b),
        .alu_op    (alu_op),
        .result    (alu_result),
        .carry_out (alu_carry_out)
    );

    always @(posedge clk) begin
        if (reset) begin
            pc_reg    <= 4'h0;
            ir_reg    <= 8'h00;
            acc_reg   <= 8'h00;
            zero_reg  <= 1'b1;
            carry_reg <= 1'b0;
            out_data  <= 8'h00;
            out_valid <= 1'b0;
        end else begin
            out_valid <= 1'b0;

            if (ir_we) begin
                ir_reg <= instr_rdata;
            end

            if (pc_load) begin
                pc_reg <= ir_reg[3:0];
            end else if (pc_inc) begin
                pc_reg <= pc_reg + 4'h1;
            end

            if (acc_we) begin
                acc_reg <= alu_result;
            end

            if (z_we) begin
                zero_reg <= (alu_result == 8'h00);
            end

            if (c_we) begin
                carry_reg <= alu_carry_out;
            end

            if (out_we) begin
                out_data  <= acc_reg;
                out_valid <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
