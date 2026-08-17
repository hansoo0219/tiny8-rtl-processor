# Tiny8 Verification Plan

**Status:** In progress. The `alu8` and `instruction_decoder` modules completed
the required simulation, lint, waveform, and synthesis checks on 2026-08-17.
All remaining module and integration checks are still planned.

## 1. Required quality gates

Each implemented module must pass, in order:

1. specification review;
2. Icarus compilation;
3. Verilator lint with warnings understood;
4. self-checking directed and boundary tests;
5. VCD waveform inspection;
6. Yosys synthesis;
7. documentation update.

The integrated system additionally requires multiple complete program tests.

## 2. Planned unit tests

### `alu8_tb.v`

- `PASS_B` with `00`, `FF`, and representative values
- ADD without carry
- ADD with carry and zero result
- SUB with no borrow
- SUB with borrow
- SUB producing zero
- AND, OR, and XOR directed patterns
- SHL with carry clear/set and zero result
- SHR with carry clear/set and zero result
- boundary values `00` and `FF`
- reference-model comparison over additional input combinations

### `instruction_decoder_tb.v`

- check all 16 opcode values
- verify every control field
- verify opcode `E` has no side effects
- verify no unknown or unassigned output

### `data_ram_tb.v`

- write and read all 16 addresses
- confirm writes happen only on rising edges
- confirm `we=0` preserves memory
- confirm address independence
- do not require a reset value

### `program_rom_tb.v`

- load a known 16-byte image
- read all addresses
- check unused locations contain `F0`

### `control_unit_tb.v`

- synchronous reset to `FETCH`
- `FETCH -> EXECUTE -> FETCH`
- correct fetch controls
- taken and not-taken `JZ`
- unconditional `JMP`
- `HLT -> HALT`
- no control side effects in `HALT`
- reset recovery from `HALT`
- invalid-state safe recovery
- no Data RAM write while reset is high

## 3. Core integration tests

- complete reset-state check
- PC increment and modulo-16 wrap-around
- IR fetch timing
- `LDI` and `LDA` writeback
- `STA` address/data/write-edge behavior
- ADD carry and zero combinations
- SUB borrow/no-borrow combinations
- AND, OR, and XOR
- SHL and SHR shift-out carry
- JMP target fetch
- JZ taken and not taken
- reserved opcode behavior
- one-cycle `out_valid` and retained `out_data`
- HLT register/state stability over multiple clocks

## 4. Complete program tests

At minimum, separate program images will verify:

1. RAM initialization, `LDA`, `STA`, and arithmetic output;
2. ADD carry and zero behavior;
3. SUB borrow and no-borrow behavior;
4. AND/OR/XOR results;
5. SHL/SHR results and shifted-out carry;
6. JZ taken and not taken;
7. JMP and PC wrap-around;
8. OUT and HLT behavior.

The first reference program is the 5 + 3 example in
`docs/instruction_set.md`, with expected output `8'h08`.

## 5. Self-checking result policy

Testbenches must compare expected and actual values automatically. A waveform
alone is not a passing test. Expected terminal output will follow this style:

```text
TEST 01 RESET ............... PASS
TEST 02 RAM STORE/LOAD ...... PASS
TEST 03 ADD AND CARRY ....... PASS
...
ALL TESTS PASSED
```

A failed comparison must print the test name, expected value, actual value, and
relevant simulation time before ending with a non-zero/fatal result.

## 6. Waveform checklist

The integration waveform must include:

- `clk`, `reset`
- `dbg_state`
- `dbg_pc`, `dbg_ir`, `dbg_acc`
- `dbg_zero`, `dbg_carry`
- Data RAM address, write data, read data, and write enable
- `out_data`, `out_valid`, `halted`

At least one annotated screenshot will be retained in `artifacts/screenshots/`.

## 7. Synthesis checklist

Yosys must synthesize `tiny8_core` and `tiny8_system` without errors. Reports
will be saved under `artifacts/synthesis/` and reviewed for:

- flip-flops corresponding to architectural registers;
- accumulator and PC arithmetic;
- mux and decoder logic;
- memory inference or expansion;
- accidental latch cells;
- undriven or multiply-driven signals;
- unexpected removal of required logic.
