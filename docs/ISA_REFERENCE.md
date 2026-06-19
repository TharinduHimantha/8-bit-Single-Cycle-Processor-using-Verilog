# ISA Reference — CO2070 8-bit Processor

## Instruction Encoding

All instructions are 32-bit fixed length.

```
 31      24 23      16 15       8 7        0
 ┌─────────┬──────────┬──────────┬──────────┐
 │ OP-CODE │  RD/IMM  │    RT    │  RS/IMM  │
 └─────────┴──────────┴──────────┴──────────┘
```

| Field | Bits | Usage |
|-------|------|-------|
| OP-CODE | 31–24 | Operation identifier |
| RD / IMM | 23–16 | Destination register, or jump/branch offset |
| RT | 15–8 | Source register 1 (or ignored) |
| RS / IMM | 7–0 | Source register 2, or immediate value |

---

## Opcode Table

| Instruction | OP-CODE (hex) | OP-CODE (binary) |
|-------------|---------------|------------------|
| `loadi`     | `0x00`        | `00000000`       |
| `mov`       | `0x01`        | `00000001`       |
| `add`       | `0x02`        | `00000010`       |
| `sub`       | `0x03`        | `00000011`       |
| `and`       | `0x04`        | `00000100`       |
| `or`        | `0x05`        | `00000101`       |
| `j`         | `0x06`        | `00000110`       |
| `beq`       | `0x07`        | `00000111`       |


---

## ALU SELECT Encoding

The control unit derives a 3-bit `ALUOP` signal from the instruction OP-CODE and sends it to the ALU's `SELECT` port.

| SELECT | ALU Operation | Instruction(s) |
|--------|---------------|----------------|
| `000`  | FORWARD: `RESULT ← DATA2` | `loadi`, `mov` |
| `001`  | ADD: `RESULT ← DATA1 + DATA2` | `add`, `sub` |
| `010`  | AND: `RESULT ← DATA1 & DATA2` | `and` |
| `011`  | OR:  `RESULT ← DATA1 \| DATA2` | `or` |
| `1XX`  | Reserved / Extended | — |

For `sub`, the control unit negates DATA2 using 2's complement before it reaches the ALU, so the same ADD unit handles both `add` and `sub`.

---

## Instruction Details

### `add rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] + REG[rs]`
- **Encoding:** `OP-CODE=add | rd | rt | rs`
- **Notes:** Operands treated as signed 8-bit integers (two's complement)

### `sub rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] − REG[rs]`
- **Encoding:** `OP-CODE=sub | rd | rt | rs`
- **Notes:** 2's complement of RS applied before ADD unit

### `and rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] & REG[rs]` (bitwise)
- **Encoding:** `OP-CODE=and | rd | rt | rs`

### `or rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] | REG[rs]` (bitwise)
- **Encoding:** `OP-CODE=or | rd | rt | rs`

### `mov rd rt`
- **Operation:** `REG[rd] ← REG[rt]`
- **Encoding:** `OP-CODE=mov | rd | rt | --` (bits 7–0 ignored)
- **Notes:** Routes RT value through ALU FORWARD unit

### `loadi rd imm`
- **Operation:** `REG[rd] ← imm`
- **Encoding:** `OP-CODE=loadi | rd | -- | imm` (bits 15–8 ignored)
- **Notes:** 8-bit immediate from bits 7–0, routed through ALU FORWARD unit

### `j offset`
- **Operation:** `PC ← (PC + 4) + (offset × 4)`
- **Encoding:** `OP-CODE=j | offset | -- | --` (bits 15–0 ignored)
- **Notes:** Offset is signed 8-bit. Positive = forward, negative = backward. Computed by branch/jump adder.

### `beq offset rt rs`
- **Operation:** `if REG[rt] == REG[rs]: PC ← (PC + 4) + (offset × 4)`
- **Encoding:** `OP-CODE=beq | offset | rt | rs`
- **Notes:** Uses ALU to compute `REG[rt] − REG[rs]`; branches if ZERO flag is set

---

## Register File

| Register | Name | Notes |
|----------|------|-------|
| R0 | Register 0 | General purpose |
| R1 | Register 1 | General purpose |
| R2 | Register 2 | General purpose |
| R3 | Register 3 | General purpose |
| R4 | Register 4 | General purpose |
| R5 | Register 5 | General purpose |
| R6 | Register 6 | General purpose |
| R7 | Register 7 | General purpose |

All registers are 8-bit. There is no hardwired zero register.

---

## Assembly Example Programs

### Sum of registers
```asm
loadi 0 0x05    ; R0 = 5
loadi 1 0x03    ; R1 = 3
add   2 0 1     ; R2 = R0 + R1  →  R2 = 8
```

### Loop (counting down)
```asm
loadi 0 0x05    ; R0 = 5  (counter)
loadi 1 0x01    ; R1 = 1  (decrement)
sub   0 0 1     ; R0 = R0 - 1
beq   0xFE 0 2  ; if R0 == R2 (R2=0), branch back 2 instructions (repeat sub)
```
> Note: R2 starts at 0 after reset. `0xFE` = −2 in signed 8-bit, so `PC+4 + (−2×4)` jumps back 8 bytes (2 instructions).

---

## Extended ISA Opcodes

| Instruction | OP-CODE (suggested) | ALUOP | Notes |
|-------------|---------------------|-------|-------|
| `mult` | `0x08` | `100` | R4 ← R1 × R2 |
| `sll`  | `0x09` | `101` | Shift left logical |
| `srl`  | `0x0A` | `101` | Shift right logical (shares unit with sll) |
| `sra`  | `0x0B` | `110` | Shift right arithmetic |
| `ror`  | `0x0C` | `111` | Rotate right |
| `bne`  | `0x0D` | `001` | Branch if not equal (reuses ZERO flag, inverted) |


