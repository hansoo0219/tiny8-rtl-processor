# Tiny8 Baseline Specification

**Specification version:** 0.1.0  
**Status:** Frozen architecture baseline; implementation and verification complete
**Architecture name:** Tiny8-RAM

## 1. Purpose

Tiny8-RAM is a small accumulator-based processor for learning synthesizable
Verilog, control/datapath separation, self-checking verification, waveform
debugging, linting, and synthesis. Every behavior required by the baseline is
defined here before RTL implementation begins.

## 2. Fixed architectural parameters

| Item | Value |
|---|---:|
| Data width | 8 bits |
| Instruction width | 8 bits |
| Program address width | 4 bits |
| Data address width | 4 bits |
| Program ROM | 16 x 8 bits |
| Data RAM | 16 x 8 bits |
| Accumulator | 8 bits |
| Instruction register | 8 bits |
| Program counter | 4 bits |
| Arithmetic | Unsigned |
| Reset | Active-high, synchronous |
| Execution model | Multi-cycle, non-pipelined |
| Memory organization | Harvard architecture |

Widths are fixed in the baseline. Parameterizing the architecture is outside
the baseline scope.

## 3. Instruction format

```text
  7             4 3             0
 +---------------+---------------+
 |    opcode     |    operand    |
 +---------------+---------------+
       4 bits          4 bits
```

- `instruction[7:4]` is the opcode.
- `instruction[3:0]` is either a data address, a program address, or an
  immediate value.
- Immediate values are zero-extended from 4 bits to 8 bits.
- Operands for `NOP`, `OUT`, `SHL`, `SHR`, and `HLT` are ignored.
- Signed arithmetic and an overflow flag are not supported.

The normative opcode table is in `docs/instruction_set.md`.

## 4. Programmer-visible state

| State | Width | Purpose |
|---|---:|---|
| `PC` | 4 | Address of the next instruction to fetch |
| `IR` | 8 | Currently executing instruction |
| `ACC` | 8 | Arithmetic, logic, load, store, shift, and output accumulator |
| `Z` | 1 | Zero flag |
| `C` | 1 | Carry/no-borrow/shift-out flag |
| `OUT` | 8 | Registered external output value |

The FSM state is internal architectural control state. Data RAM is writable
architectural storage but is not cleared by reset.

## 5. Reset contract

Reset is sampled only on a rising clock edge. The environment must hold
`reset = 1` across at least one rising edge.

After such an edge:

| State | Reset value |
|---|---:|
| `PC` | `4'h0` |
| `IR` | `8'h00` (`NOP 0`) |
| `ACC` | `8'h00` |
| `Z` | `1'b1` |
| `C` | `1'b0` |
| `OUT` | `8'h00` |
| `out_valid` | `1'b0` |
| FSM state | `FETCH` |
| `halted` | `1'b0` |

Reset disables Data RAM writes. Data RAM contents are unspecified after reset;
software must write a location before relying on its value.

## 6. Memory contract

### 6.1 Program ROM

- Separate from Data RAM.
- Addressed by `PC`.
- Combinational/asynchronous read.
- Initialized from a 16-byte hexadecimal program image.
- Unused program locations are filled with `8'hF0` (`HLT 0`).
- Not writable by the processor.

### 6.2 Data RAM

- Separate from Program ROM.
- Addressed by `IR[3:0]` while executing a memory instruction.
- Combinational/asynchronous read.
- Synchronous write on the rising clock edge when `data_we = 1`.
- Write data is the current `ACC` value.
- Contains 16 independently addressable 8-bit locations.
- Is not initialized or cleared by processor reset.

Program address `n` and Data RAM address `n` refer to different storage because
the processor uses Harvard architecture.

## 7. Execution timing

The baseline is non-pipelined and normally uses two clock edges per instruction.

### `FETCH`

At the rising edge ending `FETCH`:

1. `IR <= program_rom[PC]`
2. `PC <= PC + 1` modulo 16
3. FSM state becomes `EXECUTE`

### `EXECUTE`

During `EXECUTE`, the instruction in `IR` is decoded. At the rising edge ending
`EXECUTE`, the specified register, memory, flag, output, PC, or state update is
committed. The next state is normally `FETCH`.

- `JMP` and a taken `JZ` replace the already incremented `PC` with the target.
- A not-taken `JZ` leaves the incremented `PC` unchanged; there is no delay slot.
- `STA` writes Data RAM at this edge.
- `HLT` changes the next state to `HALT`.

### `HALT`

No instruction is fetched or executed. `PC`, `IR`, `ACC`, flags, `OUT`, and Data
RAM remain unchanged until reset. `out_valid` is low and `halted` is high.
Because `HLT` was already fetched, the held `PC` points to the address after the
`HLT` instruction.

## 8. Flag contract

### Zero flag (`Z`)

`Z` is updated whenever `ACC` is written by `LDI`, `LDA`, `ADD`, `SUB`, `AND`,
`OR`, `XOR`, `SHL`, or `SHR`:

```text
Z = 1 when the new ACC value is 8'h00
Z = 0 otherwise
```

Other instructions preserve `Z`.
`JZ` tests the currently stored `Z` value left by an earlier ACC-writing
instruction.

### Carry flag (`C`)

- `ADD`: `C` is the ninth bit of the unsigned sum.
- `SUB`: `C = 1` means no borrow; `C = 0` means a borrow occurred.
- `SHL`: `C` receives the old `ACC[7]` bit.
- `SHR`: `C` receives the old `ACC[0]` bit.
- All other instructions preserve `C`.

Examples:

```text
8'hFF + 8'h01 -> ACC = 8'h00, C = 1, Z = 1
8'h05 - 8'h03 -> ACC = 8'h02, C = 1, Z = 0
8'h03 - 8'h05 -> ACC = 8'hFE, C = 0, Z = 0
SHL 8'h80      -> ACC = 8'h00, C = 1, Z = 1
SHR 8'h01      -> ACC = 8'h00, C = 1, Z = 1
```

## 9. Output contract

`OUT` copies `ACC` into the output register on its `EXECUTE` edge.

- `out_data` retains the most recently written output value.
- `out_valid` is high for exactly one full clock period immediately after an
  `OUT` instruction commits.
- Later instructions do not erase `out_data`.
- Reset clears both signals.

## 10. Reserved opcode contract

Opcode `4'hE` is reserved. In this baseline it executes as a deterministic
`NOP` instruction:

- no register, flag, memory, or output side effect;
- execution continues with the next sequential instruction;
- no trap or exception is generated.

## 11. Top-level functional interface

`tiny8_system` exposes:

| Port | Direction | Width | Meaning |
|---|---|---:|---|
| `clk` | input | 1 | Rising-edge clock |
| `reset` | input | 1 | Active-high synchronous reset |
| `out_data` | output | 8 | Last value committed by `OUT` |
| `out_valid` | output | 1 | One-cycle output-valid pulse |
| `halted` | output | 1 | High only in `HALT` state |
| `dbg_pc` | output | 4 | Verification/debug view of `PC` |
| `dbg_ir` | output | 8 | Verification/debug view of `IR` |
| `dbg_acc` | output | 8 | Verification/debug view of `ACC` |
| `dbg_zero` | output | 1 | Verification/debug view of `Z` |
| `dbg_carry` | output | 1 | Verification/debug view of `C` |
| `dbg_state` | output | 2 | Verification/debug view of FSM state |

Debug outputs are synthesizable observation ports. They do not alter processor
behavior.

## 12. Architectural invariants

The implementation must maintain all of the following:

1. `PC` changes only during `FETCH` or a taken jump during `EXECUTE`.
2. Data RAM changes only on a rising edge with `data_we = 1`.
3. `ACC` changes only for accumulator-writing instructions.
4. `Z` changes only when `ACC` changes.
5. `C` changes only for `ADD`, `SUB`, `SHL`, and `SHR`.
6. `out_valid` never remains high for more than one clock period per `OUT`.
7. `HALT` is stable until reset.
8. Reset cannot cause a Data RAM write.
9. All combinational logic has a defined output for every input combination.
10. No signal is driven by more than one RTL process.

## 13. Baseline exclusions

The following are intentionally not part of version 0.1.0:

- general-purpose register file
- stack pointer, subroutines, or stack operations
- interrupts or exceptions
- signed arithmetic or overflow flag
- carry-based branch instruction
- rotates
- input port or memory-mapped peripherals
- caches, pipelining, speculation, or out-of-order execution
- synchronous-read memory support
- FPGA board implementation
- assembler, compiler, or operating system

These exclusions keep the design explainable and fully verifiable within the
project schedule.
