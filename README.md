# Multicycle RISC-V Core with Zmmul and CRC Extensions

A 32-bit multicycle RISC-V processor written in Verilog. It implements the RV32I base integer instructions, the four Zmmul multiply instructions, and three custom CRC-16 instructions (Xicrc). It was developed and verified in ChipInventor and taken through OpenLane to a GDSII layout.

| | |
|---|---|
| **ISA** | RV32I (44 instruction types in scope) + Zmmul (4) + custom Xicrc (3) |
| **Microarchitecture** | Multicycle, one instruction at a time, 7-state FSM |
| **Reset** | Synchronous, active high. PC = `0x00400000`, state = FETCH |
| **Top module** | `top` (`clk`, `rst` in; `pc_o[31:0]` out) |
| **Verification** | 44/44 instruction types, 9/9 firmware stages in each of 2 runs |
| **Physical** | OpenLane flow, 1.6 mm × 1.6 mm, density 0.3 |



## Instruction set

| Category | Instructions |
|---|---|
| Register arithmetic and logic (10) | `ADD SUB SLL SLT SLTU XOR SRL SRA OR AND` |
| Immediate arithmetic and logic (9) | `ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI` |
| Load (5) | `LB LH LW LBU LHU` |
| Store (3) | `SB SH SW` |
| Branch (6) | `BEQ BNE BLT BGE BLTU BGEU` |
| Jump (2) | `JAL JALR` |
| Upper immediate (2) | `LUI AUIPC` |
| Multiplication, Zmmul (4) | `MUL MULH MULHSU MULHU` |
| CRC, custom Xicrc (3) | `CRCB CRCH CRCW` |
| **Total** | **44** |

`FENCE` is treated as a no-op. `ECALL`/`EBREAK` and any illegal encoding send the FSM to a terminal `HALT` state. They are outside the 44-instruction verification scope.

### CRC extension

The CRC instructions use the R-type format on opcode `0110011` with `funct7 = 1000000`:

| Instruction | funct3 | Bytes of `rs1` consumed (in order) |
|---|---|---|
| `CRCB` | `000` | `[7:0]` |
| `CRCH` | `001` | `[15:8]`, `[7:0]` |
| `CRCW` | `010` | `[31:24]`, `[23:16]`, `[15:8]`, `[7:0]` |

The CRC is CRC-16/CCITT: polynomial `0x1021`, MSB-first, no reflection, no final XOR. The 16-bit seed is `rs2[15:0]`. The result is zero-extended into `rd`. `funct3 = 011` is illegal.

### Encodings

<details>
<summary>Opcode / funct3 / funct7 table (click to expand)</summary>

| Instruction | Opcode | funct3 | funct7 |
|---|---|---|---|
| ADD / SUB | 0110011 | 000 | 0000000 / 0100000 |
| SLL | 0110011 | 001 | 0000000 |
| SLT / SLTU | 0110011 | 010 / 011 | 0000000 |
| XOR | 0110011 | 100 | 0000000 |
| SRL / SRA | 0110011 | 101 | 0000000 / 0100000 |
| OR / AND | 0110011 | 110 / 111 | 0000000 |
| ADDI SLTI SLTIU XORI ORI ANDI | 0010011 | 000 010 011 100 110 111 | n/a |
| SLLI / SRLI / SRAI | 0010011 | 001 / 101 / 101 | 0000000 / 0000000 / 0100000 |
| LB LH LW LBU LHU | 0000011 | 000 001 010 100 101 | n/a |
| SB SH SW | 0100011 | 000 001 010 | n/a |
| BEQ BNE BLT BGE BLTU BGEU | 1100011 | 000 001 100 101 110 111 | n/a |
| JAL | 1101111 | n/a | n/a |
| JALR | 1100111 | 000 | n/a |
| LUI / AUIPC | 0110111 / 0010111 | n/a | n/a |
| MUL MULH MULHSU MULHU | 0110011 | 000 001 010 011 | 0000001 |
| CRCB CRCH CRCW | 0110011 | 000 001 010 | 1000000 |

</details>

## Architecture

### Execution model

Each instruction walks through the FSM in `MAIN_FSM`:

```
FETCH → DECODE → EXECUTE ─┬→ WRITEBACK → FETCH                      (ALU, branch, jump, LUI/AUIPC, MUL, CRC, FENCE)
                          ├→ MEM_REQUEST → WRITEBACK → FETCH        (store)
                          ├→ MEM_REQUEST → MEM_CAPTURE → WRITEBACK  (load)
                          └→ HALT                                    (ECALL/EBREAK; illegal also leaves DECODE → HALT)
```

| Instruction class | Cycles |
|---|---|
| ALU, MUL, CRC, LUI/AUIPC, branch, JAL/JALR, FENCE | 4 |
| Store | 5 |
| Load | 6 |

Key design points:

- **One shared execution unit.** `EXECUTION_UNIT` selects its two operands (`rs1`, `PC`, old PC, `rs2`, immediate, constant 4), then picks the result from the ALU, multiplier or CRC block.
- **PC increment reuses the ALU.** During FETCH the ALU computes `PC + 4`. That value is also latched so JAL/JALR can write the correct link address after the PC has been redirected.
- **Staging registers.** Instruction, old PC, `rs1`, `rs2`, ALU result, memory data register and `PC+4` are each held in a `REGISTER32` with its own enable from `CONTROL_SIGNALS`.
- **Shared memory port.** Instruction fetch and data access use the same `MEMORY` interface. The LSU address mux selects PC during FETCH and the result register otherwise.
- **Multiplier.** One unsigned 32×32→64 product with modulo-2³² corrections yields the signed high halves for `MULH` and `MULHSU`.

### Memory map

| Region | Base | Size (this build) | Notes |
|---|---|---|---|
| Instruction memory (ROM) | `0x00400000` | 259 words (decoder window: 4 MB) | Embedded firmware and constants, combinational read |
| Data memory (SRAM) | `0x10010000` | 7 words (28 bytes) | Synchronous read/write, per-byte write enables |

Reads from unmapped addresses return 0. Writes to unmapped addresses are ignored.

### Module hierarchy

```
top
├── CONTROL_UNIT
│   ├── INSTRUCTION_DECODER
│   ├── MAIN_FSM
│   └── CONTROL_SIGNALS
├── EXECUTION_UNIT
│   ├── MUX4_32 (A operand, B operand, result select)
│   ├── ALU
│   ├── MULTIPLIER
│   └── CRC
│       └── CRC_BYTE (x4, chained)
├── REGISTER_FILE
├── REGISTER32 (x8: instruction, PC, old PC, rs1, rs2, result, MDR, PC+4)
├── INSTRUCTION_FIELDS
├── IMMEDIATE_EXTENSION
├── BRANCH_COMPARATOR
├── JALR_TARGET
├── MUX2_32 (memory address select)
├── LSU
└── MEMORY
    ├── ADDRESS_DECODER
    ├── INSTRUCTION_MEMORY
    ├── DATA_MEMORY
    └── MUX4_32 (read data select)
```

### Datapath and control

<p align="center">
  <img src="docs/img/datapath_left.png" width="48%" alt="Datapath, left view">
  <img src="docs/img/datapath_right.png" width="48%" alt="Datapath, right view">
</p>

<p align="center">
  <img src="docs/img/execution_unit.png" width="32%" alt="Execution unit">
  <img src="docs/img/control_unit.png" width="32%" alt="Control unit">
  <img src="docs/img/memory.png" width="32%" alt="Memory subsystem">
</p>

