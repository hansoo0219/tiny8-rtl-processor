# Development Log

## 2026-08-14 — Architecture baseline

### Completed

- Chose a RAM-based baseline rather than an immediate-only first architecture.
- Fixed the data width, instruction format, memory sizes, ISA, flag rules,
  reset behavior, output timing, FSM, and module hierarchy.
- Created the repository directory structure and initial design documents.

### Important limitation

No Tiny8 RTL has been implemented, simulated, linted, or synthesized yet.

### Next step

Review the `alu8` specification, then write and verify only `rtl/alu8.v` and its
self-checking testbench.

## 2026-08-17 — Combinational ALU

### Completed

- Added shared 3-bit ALU operation encodings in `rtl/tiny8_defs.vh`.
- Implemented `PASS_B`, `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SHL`, and `SHR` in
  `rtl/alu8.v`.
- Added the self-checking `tb/alu8_tb.v` testbench with directed boundary tests
  and a reference-model sweep.

### Verified results

- Icarus Verilog compiled the ALU and testbench without warnings.
- Self-checking simulation passed 9 test groups and 796 individual cases.
- Verilator lint completed without warnings.
- Representative arithmetic, logic, and carry behavior was reviewed in the VCD
  waveform.
- Yosys synthesized `alu8`, reported zero check problems, and produced only
  combinational logic cells with no latch, flip-flop, or memory cells.

### Important limitation

Only the ALU is implemented and verified. No instruction decoder, control unit,
memory, processor core, or integrated CPU result is claimed yet.

### Next step

Implement and verify the combinational instruction decoder for all 16 opcodes.

## 2026-08-17 — Instruction decoder

### Completed

- Added the 16 ISA opcode encodings and operand-source encodings to
  `rtl/tiny8_defs.vh`.
- Implemented the combinational `rtl/instruction_decoder.v` module.
- Added the self-checking `tb/instruction_decoder_tb.v` testbench covering every
  opcode from `NOP` through `HLT`.
- Implemented deterministic reserved-opcode classification with all
  architectural write controls disabled.

### Verified results

- Icarus Verilog compiled the decoder and testbench without warnings.
- Self-checking simulation passed all 16 opcode cases.
- Verilator lint completed without warnings.
- The complete opcode-to-control sequence was reviewed in the VCD waveform.
- Yosys synthesized the decoder, reported zero check problems, and produced 32
  combinational logic cells with no latch, flip-flop, or memory cells.
- The ALU regression was rerun after extending `tiny8_defs.vh`; all 796 cases
  continued to pass.

### Important limitation

The decoder produces an ungated control description only. State-dependent
control gating will be implemented later in `control_unit`; no processor-level
execution result is claimed yet.

### Next step

Implement and verify the 16 x 8-bit Data RAM with combinational read and
synchronous write behavior.

## 2026-08-17 — Data RAM

### Completed

- Implemented `rtl/data_ram.v` as a 16 x 8-bit memory with combinational read
  and rising-edge synchronous write behavior.
- Kept the RAM free of reset and initialization logic as required by the
  architecture.
- Added `tb/data_ram_tb.v` with checks for all addresses, write timing, disabled
  writes, and address independence.

### Verified results

- Icarus Verilog compiled the RAM and testbench without warnings.
- Self-checking simulation passed 4 test groups and 52 individual cases.
- The VCD waveform confirmed unknown values before first write, immediate
  asynchronous reads, and data changes only after enabled rising edges.
- Verilator lint completed without warnings.
- Yosys synthesized the RAM and reported zero check problems. Generic synthesis
  expanded the asynchronous-read memory into 128 enabled flip-flops plus
  combinational selection logic, with no latch cells.

### Important limitation

The generic Yosys result does not claim inference of a specific FPGA memory
primitive. The asynchronous-read architecture may map to distributed memory or
flip-flops depending on the eventual target technology.

### Next step

Implement and verify the 16 x 8-bit Program ROM and its hexadecimal program
image loading behavior.

## 2026-08-17 — Program ROM

### Completed

- Implemented `rtl/program_rom.v` as a 16 x 8-bit ROM with combinational read
  behavior and hexadecimal image loading through `$readmemh`.
- Added the complete 16-byte `programs/add_5_3.hex` reference image. The first
  seven bytes implement the 5 + 3 example, and every unused location contains
  the deterministic `HLT` instruction `F0`.
- Added `tb/program_rom_tb.v` to check every ROM address against an independent
  expected-value table.

### Verified results

- Icarus Verilog compiled the RTL ROM and testbench without warnings.
- Self-checking RTL simulation passed 2 test groups covering all 16 addresses.
- Verilator lint completed without warnings.
- The VCD waveform confirmed immediate address-dependent reads and the expected
  program bytes at addresses `0` through `F`.
- Yosys synthesized the ROM, reported zero check problems, and produced 13
  combinational logic cells with no latch or flip-flop cells.
- The synthesized netlist passed the same 16-address self-checking testbench.

### Synthesis note

An earlier implementation filled the array with `F0` in a procedural loop
before calling `$readmemh`. In the current generic Yosys flow that combination
collapsed the synthesized ROM to a constant `F0`, despite correct RTL
simulation. The prefill loop was removed and the program-image contract now
requires exactly 16 explicit bytes, including `F0` in every unused location.

### Important limitation

The generic synthesis result embeds the current default image as combinational
logic. A different program image requires resynthesis, and mapping to a
technology-specific ROM primitive is not claimed.

### Next step

Implement and verify the `FETCH`, `EXECUTE`, and `HALT` sequencing in
`control_unit`.

## 2026-08-17 — Control unit

### Completed

- Added the fixed `FETCH`, `EXECUTE`, `HALT`, and invalid/recovery encodings to
  `rtl/tiny8_defs.vh`.
- Implemented `rtl/control_unit.v` with a synchronous state register and
  combinational next-state and gated-control logic.
- Reused `instruction_decoder` for opcode decode, then allowed architectural
  side effects only during `EXECUTE`.
- Implemented unconditional and zero-conditional PC-load control, stable
  `HALT`, invalid-state recovery, and reset masking of every write control.
- Added `tb/control_unit_tb.v` with state, opcode, branch, halt, reset, and
  invalid-state checks.

### Verified results

- Icarus Verilog compiled the control unit and testbench without warnings.
- Self-checking RTL simulation passed 7 test groups and 47 checks.
- Verilator lint completed without warnings.
- The VCD waveform confirmed `FETCH/EXECUTE` sequencing, reset masking of a
  pending `STA`, `HLT` entry and stability, reset recovery, and invalid-state
  recovery.
- Yosys reported zero check problems and produced two synchronous-reset
  flip-flops for the 2-bit FSM state, plus combinational control and decoder
  logic. No latch cells were inferred.
- The synthesized netlist passed the same 7 groups and 47 checks.
- ALU, decoder, Data RAM, and Program ROM regression simulations all continued
  to pass.

### Important limitation

This module emits `out_we` but does not create `out_valid`. The processor core
will register `out_we` so `out_valid` remains high for the full cycle after an
`OUT` instruction commits. No complete instruction execution is claimed until
the datapath is integrated in `tiny8_core`.

### Next step

Implement and verify `tiny8_core`, including the PC, IR, accumulator, flags,
output register, ALU operand mux, and memory interfaces.
