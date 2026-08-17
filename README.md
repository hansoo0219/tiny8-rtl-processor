# Tiny8: Synthesizable 8-bit Accumulator-Based Processor in Verilog

Tiny8 is an educational 8-bit processor implemented as synthesizable RTL. The
project is intentionally small enough to understand completely while still
covering a datapath, a finite-state control unit, program and data memories,
branching, flags, output, verification, linting, and synthesis.

## Current status

The RAM-based architecture and instruction set are frozen as the implementation
baseline. All planned RTL modules, including `tiny8_system`, have been
implemented and verified with self-checking simulation, lint, waveform review,
and logic synthesis. The integrated real ROM/RAM hierarchy executes the
reference 5 + 3 program, produces `8'h08`, and enters `HALT`. The additional
complete-program regression images and final annotated waveform artifact are
still pending.

## Baseline architecture

- 8-bit accumulator datapath
- 8-bit fixed-width instructions
- 4-bit program counter
- 16 x 8-bit program ROM
- 16 x 8-bit data RAM
- Harvard architecture
- active-high synchronous reset
- `FETCH`, `EXECUTE`, and `HALT` control states
- zero and carry flags
- registered output with a one-cycle `out_valid` pulse

The complete frozen specification is in:

- [Specification](docs/specification.md)
- [Architecture](docs/architecture.md)
- [Instruction set](docs/instruction_set.md)
- [Verification plan](docs/verification_plan.md)
- [Decision log](docs/decision_log.md)

## Planned open-source toolchain

- Icarus Verilog for compilation and simulation
- GTKWave for waveform inspection
- Verilator for linting
- Yosys for logic synthesis
- GNU Make under WSL for repeatable commands

## Project scope statement

This is an independent educational RTL design project. It is not a commercial
CPU, an ASIC tapeout, or professional semiconductor work.
