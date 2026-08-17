`ifndef TINY8_DEFS_VH
`define TINY8_DEFS_VH

`define ALU_OP_PASS_B 3'b000
`define ALU_OP_ADD    3'b001
`define ALU_OP_SUB    3'b010
`define ALU_OP_AND    3'b011
`define ALU_OP_OR     3'b100
`define ALU_OP_XOR    3'b101
`define ALU_OP_SHL    3'b110
`define ALU_OP_SHR    3'b111

`define OPCODE_NOP      4'h0
`define OPCODE_LDI      4'h1
`define OPCODE_LDA      4'h2
`define OPCODE_STA      4'h3
`define OPCODE_ADD      4'h4
`define OPCODE_SUB      4'h5
`define OPCODE_AND      4'h6
`define OPCODE_OR       4'h7
`define OPCODE_XOR      4'h8
`define OPCODE_JMP      4'h9
`define OPCODE_JZ       4'hA
`define OPCODE_OUT      4'hB
`define OPCODE_SHL      4'hC
`define OPCODE_SHR      4'hD
`define OPCODE_RESERVED 4'hE
`define OPCODE_HLT      4'hF

`define OPERAND_SEL_IMMEDIATE 1'b0
`define OPERAND_SEL_MEMORY    1'b1

`endif
