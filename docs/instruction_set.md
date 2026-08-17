# Tiny8 Instruction Set Architecture

**ISA version:** 0.1.0 (Tiny8-RAM baseline)

## Instruction encoding

Every instruction is one byte:

```text
[ opcode (bits 7:4) ][ operand (bits 3:0) ]
```

## Opcode table

| Opcode | Mnemonic | Operand | Operation | `Z` | `C` |
|---:|---|---|---|---|---|
| `0` | `NOP` | ignored | No architectural change | keep | keep |
| `1` | `LDI imm4` | immediate | `ACC <- zero_extend(imm4)` | update | keep |
| `2` | `LDA addr` | RAM address | `ACC <- RAM[addr]` | update | keep |
| `3` | `STA addr` | RAM address | `RAM[addr] <- ACC` | keep | keep |
| `4` | `ADD addr` | RAM address | `{C, ACC} <- ACC + RAM[addr]` | update | update |
| `5` | `SUB addr` | RAM address | `ACC <- ACC - RAM[addr]` | update | no-borrow |
| `6` | `AND addr` | RAM address | `ACC <- ACC & RAM[addr]` | update | keep |
| `7` | `OR addr` | RAM address | `ACC <- ACC OR RAM[addr]` | update | keep |
| `8` | `XOR addr` | RAM address | `ACC <- ACC XOR RAM[addr]` | update | keep |
| `9` | `JMP addr` | ROM address | `PC <- addr` | keep | keep |
| `A` | `JZ addr` | ROM address | `if Z == 1: PC <- addr` | keep | keep |
| `B` | `OUT` | ignored | `OUT <- ACC`, pulse `out_valid` | keep | keep |
| `C` | `SHL` | ignored | `{C, ACC} <- {ACC[7], ACC << 1}` | update | shift-out |
| `D` | `SHR` | ignored | `ACC <- ACC >> 1`, `C <- old ACC[0]` | update | shift-out |
| `E` | reserved | ignored | Deterministic `NOP` behavior | keep | keep |
| `F` | `HLT` | ignored | Enter `HALT` until reset | keep | keep |

`SUB` defines `C = 1` for no borrow and `C = 0` for borrow.

For canonical program images, ignored operand fields are encoded as zero:
`NOP=00`, `OUT=B0`, `SHL=C0`, `SHR=D0`, and `HLT=F0`.

## Encoding examples

| Assembly | Machine byte | Explanation |
|---|---:|---|
| `LDI 5` | `8'h15` | Load the immediate value 5 |
| `LDA 3` | `8'h23` | Load Data RAM address 3 |
| `STA A` | `8'h3A` | Store into Data RAM address 10 |
| `ADD 1` | `8'h41` | Add Data RAM address 1 |
| `JZ C` | `8'hAC` | Jump to Program ROM address 12 if `Z=1` |
| `OUT` | `8'hB0` | Copy `ACC` to the output register |
| `SHL` | `8'hC0` | Shift `ACC` left by one bit |
| `HLT` | `8'hF0` | Halt the processor |

## Reference program: add 5 and 3

Because Program ROM and Data RAM are separate, program address 0 and data
address 0 do not conflict.

| ROM address | Byte | Assembly | Effect |
|---:|---:|---|---|
| `0` | `15` | `LDI 5` | `ACC = 5` |
| `1` | `30` | `STA 0` | `RAM[0] = 5` |
| `2` | `13` | `LDI 3` | `ACC = 3` |
| `3` | `31` | `STA 1` | `RAM[1] = 3` |
| `4` | `20` | `LDA 0` | `ACC = 5` |
| `5` | `41` | `ADD 1` | `ACC = 8` |
| `6` | `B0` | `OUT` | output 8 |
| `7` | `F0` | `HLT` | halt |

The expected visible result is one `out_valid` pulse with `out_data = 8'h08`,
followed by `halted = 1`.

