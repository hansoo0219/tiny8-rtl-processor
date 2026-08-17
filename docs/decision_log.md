# Tiny8 Architecture Decision Log

## D-001 — Data RAM is part of the baseline

**Date:** 2026-08-14  
**Decision:** Include 16 x 8-bit Data RAM and memory instructions from the first
frozen architecture instead of adding them after a completed immediate-only
CPU.  
**Reason:** This avoids a later incompatible redesign of the ISA, datapath, and
control unit. Implementation will still proceed module by module.

## D-002 — Harvard memory organization

**Date:** 2026-08-14  
**Decision:** Use separate 16 x 8 Program ROM and 16 x 8 Data RAM.  
**Reason:** Separate instruction and data buses keep the two-cycle control model
simple and make memory roles explicit.

## D-003 — Two-cycle non-pipelined execution

**Date:** 2026-08-14  
**Decision:** Use `FETCH`, `EXECUTE`, and `HALT` states.  
**Reason:** A fixed fetch/execute rhythm is understandable, easy to verify, and
sufficient with combinational memory reads.

## D-004 — Combinational read and synchronous RAM write

**Date:** 2026-08-14  
**Decision:** Program ROM and Data RAM reads are combinational; Data RAM writes
occur on a rising edge.  
**Reason:** Memory operands are available within `EXECUTE` without adding a wait
state, while writes retain correct sequential behavior.

## D-005 — Data RAM is not reset

**Date:** 2026-08-14  
**Decision:** Processor reset does not clear Data RAM.  
**Reason:** Resetting every memory bit adds unnecessary reset hardware and can
prevent useful memory inference. Tests and programs must initialize locations
before reading them.

## D-006 — Accumulator-centered memory ISA

**Date:** 2026-08-14  
**Decision:** Arithmetic and logic instructions use a 4-bit Data RAM address.
`LDI` remains available to introduce constants.  
**Reason:** This demonstrates memory access while preserving a small, explainable
accumulator datapath.

## D-007 — Flag semantics

**Date:** 2026-08-14  
**Decision:** `Z` follows every ACC write. `C` changes only for ADD, SUB, SHL,
and SHR. SUB uses `1 = no borrow`, `0 = borrow`.  
**Reason:** The rules are deterministic and match common unsigned arithmetic
conventions.

## D-008 — One reserved opcode is a safe NOP

**Date:** 2026-08-14  
**Decision:** Opcode `E` has no side effects and continues execution.  
**Reason:** This provides deterministic behavior without exception logic and
leaves one encoding for a future compatible extension.

## D-009 — Registered output with validity pulse

**Date:** 2026-08-14  
**Decision:** `OUT` stores `ACC` in `out_data`; `out_valid` pulses for one full
clock period.  
**Reason:** A stable data value plus an event pulse is easy to observe, verify,
and connect to a future peripheral.

## D-010 — Meaningful modules, not one module per register

**Date:** 2026-08-14  
**Decision:** Keep small state registers in `tiny8_core`; separate ALU, decoder,
control, and memories into modules.  
**Reason:** This preserves clear control/datapath boundaries without creating
excessive wrapper modules and wiring.

## D-011 — Preserve baseline shift operations

**Date:** 2026-08-14  
**Decision:** Use opcodes `C` and `D` for `SHL` and `SHR`.  
**Reason:** Shifts require only small ALU/decode additions, exercise carry
behavior, and preserve useful functionality from the original project charter.

