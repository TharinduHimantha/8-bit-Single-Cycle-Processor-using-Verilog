# ISA Reference — 8-bit Processor

## Instruction Encoding

All instructions are 32-bit fixed length.

```
 31      24 23      16 15       8 7        0
 ┌─────────┬──────────┬──────────┬──────────┐
 │ OP-CODE │  RD/IMM  │    RT    │  RS/IMM  │
 └─────────┴──────────┴──────────┴──────────┘
```

| Field | Bits | Usage |
|---|---|---|
| OP-CODE | 31–24 | Operation identifier |
| RD / IMM | 23–16 | Destination register, or jump/branch offset |
| RT | 15–8 | Source register 1 (or ignored → `0x00`) |
| RS / IMM | 7–0 | Source register 2, or immediate value |

---

## Opcode Table

Opcodes are listed directly from `CO2070Assembler.c`.

| Instruction | OP-CODE (binary) | OP-CODE (hex) | Added in |
|---|---|---|---|
| `loadi` | `00000000` | `0x00` | Lab 2 |
| `mov`   | `00000001` | `0x01` | Lab 2 |
| `add`   | `00000010` | `0x02` | Lab 2 |
| `sub`   | `00000011` | `0x03` | Lab 2 |
| `and`   | `00000100` | `0x04` | Lab 2 |
| `or`    | `00000101` | `0x05` | Lab 2 |
| `j`     | `00000110` | `0x06` | Lab 4 |
| `beq`   | `00000111` | `0x07` | Lab 4 |
| `mult`  | `00001000` | `0x08` | Lab 4.5 |
| `sll`   | `00001001` | `0x09` | Lab 4.5 |
| `srl`   | `00001010` | `0x0A` | Lab 4.5 |
| `sra`   | `00001011` | `0x0B` | Lab 4.5 |
| `ror`   | `00001100` | `0x0C` | Lab 4.5 |
| `bne`   | `00001101` | `0x0D` | Lab 4.5 |
| `lwd`   | `00001110` | `0x0E` | Lab 5 |
| `lwi`   | `00001111` | `0x0F` | Lab 5 |
| `swd`   | `00010000` | `0x10` | Lab 5 |
| `swi`   | `00010001` | `0x11` | Lab 5 |

> The memory instruction opcodes (`lwd`–`swi`) were shifted up to `0x0E`–`0x11` to avoid collision with the Lab 4.5 extended ISA opcodes at `0x08`–`0x0D`.

---

## ALU SELECT Encoding

| SELECT [2:0] | ALU Operation | Instruction(s) |
|---|---|---|
| `000` | FORWARD: `RESULT ← DATA2` | `loadi`, `mov`, `lwi` |
| `001` | ADD: `RESULT ← DATA1 + DATA2` | `add`, `sub`, `lwd`, `swd` |
| `010` | AND: `RESULT ← DATA1 & DATA2` | `and` |
| `011` | OR:  `RESULT ← DATA1 \| DATA2` | `or` |
| `100` | MULT (Extended ISA) | `mult` |
| `101` | SHIFT (Extended ISA, shared) | `sll`, `srl` |
| `110` | SRA (Extended ISA) | `sra` |
| `111` | ROR (Extended ISA) | `ror` |

For `sub`, the control unit negates DATA2 via 2's complement before the ALU, so the ADD unit handles both `add` and `sub`. `bne` reuses `001` (ADD) with the ZERO flag inverted.

---

## Instruction Details

### `loadi rd imm`
- **Operation:** `REG[rd] ← imm`
- **Encoding:** `0x00 | rd | 0x00 | imm`
- **Notes:** Bits 15–8 are ignored (assembled as `0x00`). 8-bit immediate from bits [7:0] via ALU FORWARD.

### `mov rd rt`
- **Operation:** `REG[rd] ← REG[rt]`
- **Encoding:** `0x01 | rd | rt | 0x00`
- **Notes:** Bits 7–0 are ignored (assembled as `0x00`). RT routed through ALU FORWARD.

### `add rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] + REG[rs]`
- **Encoding:** `0x02 | rd | rt | rs`
- **Notes:** Signed 8-bit two's complement arithmetic.

### `sub rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] − REG[rs]`
- **Encoding:** `0x03 | rd | rt | rs`
- **Notes:** Control unit applies 2's complement to RS before the ADD unit.

### `and rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] & REG[rs]`
- **Encoding:** `0x04 | rd | rt | rs`

### `or rd rt rs`
- **Operation:** `REG[rd] ← REG[rt] | REG[rs]`
- **Encoding:** `0x05 | rd | rt | rs`

### `j offset`
- **Operation:** `PC ← (PC + 4) + SignExt(offset) × 4`
- **Encoding:** `0x06 | offset | 0x00 | 0x00`
- **Notes:** Bits 15–0 are ignored (assembled as `0x00 0x00`). Signed 8-bit offset: positive = forward, negative = backward (e.g. `0xFE` = −2).

### `beq offset rt rs`
- **Operation:** `if REG[rt] == REG[rs]: PC ← (PC + 4) + SignExt(offset) × 4`
- **Encoding:** `0x07 | offset | rt | rs`
- **Notes:** Equality tested via subtraction in the ALU; branches when ZERO flag is asserted.

### `mult rd rt rs` *(Lab 4.5)*
- **Operation:** `REG[rd] ← REG[rt] × REG[rs]`
- **Encoding:** `0x08 | rd | rt | rs`
- **Notes:** Implemented without the `*` operator. Result is the lower 8 bits of the product.

### `sll rd rt imm` *(Lab 4.5)*
- **Operation:** `REG[rd] ← REG[rt] << imm` (logical shift left)
- **Encoding:** `0x09 | rd | rt | imm`
- **Notes:** Implemented without the `<<` operator. Shares a functional unit with `srl`.

### `srl rd rt imm` *(Lab 4.5)*
- **Operation:** `REG[rd] ← REG[rt] >> imm` (logical shift right, zero-fill)
- **Encoding:** `0x0A | rd | rt | imm`
- **Notes:** Shares functional unit with `sll`.

### `sra rd rt imm` *(Lab 4.5)*
- **Operation:** `REG[rd] ← REG[rt] >>> imm` (arithmetic shift right, sign-extend)
- **Encoding:** `0x0B | rd | rt | imm`

### `ror rd rt imm` *(Lab 4.5)*
- **Operation:** `REG[rd] ← REG[rt] rotated right by imm`
- **Encoding:** `0x0C | rd | rt | imm`

### `bne offset rt rs` *(Lab 4.5)*
- **Operation:** `if REG[rt] ≠ REG[rs]: PC ← (PC + 4) + SignExt(offset) × 4`
- **Encoding:** `0x0D | offset | rt | rs`
- **Notes:** Reuses the ADD unit (same as `beq`); branches when ZERO flag is **not** asserted.

### `lwd rd rs` *(Lab 5)*
- **Operation:** `REG[rd] ← Mem[REG[rs]]`
- **Encoding:** `0x0E | rd | 0x00 | rs`
- **Notes:** Bits 15–8 are ignored (assembled as `0x00`). ALU computes address from RS via ADD.

### `lwi rd imm` *(Lab 5)*
- **Operation:** `REG[rd] ← Mem[imm]`
- **Encoding:** `0x0F | rd | 0x00 | imm`
- **Notes:** Bits 15–8 are ignored (assembled as `0x00`). Immediate address via ALU FORWARD.

### `swd rt rs` *(Lab 5)*
- **Operation:** `Mem[REG[rs]] ← REG[rt]`
- **Encoding:** `0x10 | 0x00 | rt | rs`
- **Notes:** Bits 23–16 are ignored (assembled as `0x00`). RT is the write data; RS provides the address. No register write-back.

### `swi rt imm` *(Lab 5)*
- **Operation:** `Mem[imm] ← REG[rt]`
- **Encoding:** `0x11 | 0x00 | rt | imm`
- **Notes:** Bits 23–16 are ignored (assembled as `0x00`). RT is the write data; immediate is the address. No register write-back.

---

## Assembler Field Handling

The assembler inserts `0x00` for ignored fields automatically. The table below shows which fields each instruction actually uses.

| Instruction | bits 23–16 (RD/IMM) | bits 15–8 (RT) | bits 7–0 (RS/IMM) |
|---|---|---|---|
| `loadi` | RD | `0x00` (ignored) | IMM |
| `mov` | RD | RT | `0x00` (ignored) |
| `add` / `sub` / `and` / `or` | RD | RT | RS |
| `j` | IMM (offset) | `0x00` (ignored) | `0x00` (ignored) |
| `beq` | IMM (offset) | RT | RS |
| `mult` / `sll` / `srl` / `sra` / `ror` | RD | RT | RS or IMM |
| `bne` | IMM (offset) | RT | RS |
| `lwd` | RD | `0x00` (ignored) | RS |
| `lwi` | RD | `0x00` (ignored) | IMM |
| `swd` | `0x00` (ignored) | RT | RS |
| `swi` | `0x00` (ignored) | RT | IMM |

---

## Register Encoding

| Register number | Binary encoding |
|---|---|
| 0 | `00000000` |
| 1 | `00000001` |
| 2 | `00000010` |
| 3 | `00000011` |
| 4 | `00000100` |
| 5 | `00000101` |
| 6 | `00000110` |
| 7 | `00000111` |

---

## Immediate Value Format

Immediates must be written in **two-digit hex format** with the `0x` prefix (e.g. `0xFF`, `0x1F`, `0x02`). The assembler converts each hex digit to 4 bits and concatenates them to form the 8-bit field.

Valid range: `0x00` – `0xFF`. For signed offsets (`j`, `beq`, `bne`), `0x80`–`0xFF` are negative values in two's complement (e.g. `0xFE` = −2).

---

## Assembly Example Programs

### Arithmetic
```asm
loadi 0 0x05    ; R0 = 5
loadi 1 0x03    ; R1 = 3
add   2 0 1     ; R2 = R0 + R1 = 8
sub   3 0 1     ; R3 = R0 - R1 = 2
and   4 0 1     ; R4 = R0 & R1 = 0x01
or    5 0 1     ; R5 = R0 | R1 = 0x07
```

### Jump
```asm
loadi 0 0x01    ; R0 = 1
j 0x01          ; skip next instruction (jump forward 1)
loadi 0 0xFF    ; SKIPPED
loadi 1 0x02    ; R1 = 2
```

### Loop (counting down with beq)
```asm
loadi 0 0x05    ; R0 = 5  (counter)
loadi 1 0x01    ; R1 = 1  (decrement step)
loadi 2 0x00    ; R2 = 0  (comparison target)
sub   0 0 1     ; R0 = R0 - 1        [loop body]
beq   0xFD 0 2  ; if R0 == 0, branch back 3 instructions
                ; 0xFD = -3: PC+4 + (-3*4) jumps back to 'sub'
```

### Store and load (register direct)
```asm
loadi 0 0x42    ; R0 = 0x42
loadi 1 0x10    ; R1 = 0x10  (address)
swd   0 1       ; Mem[R1] ← R0
lwd   2 1       ; R2 ← Mem[R1]  (R2 should be 0x42)
```

### Store and load (immediate addressing)
```asm
loadi 0 0xFF    ; R0 = 0xFF
swi   0 0x20    ; Mem[0x20] ← R0
lwi   1 0x20    ; R1 ← Mem[0x20]  (R1 should be 0xFF)
```

### Extended ISA — shifts
```asm
loadi 0 0x08    ; R0 = 0b00001000
sll   1 0 0x02  ; R1 = R0 << 2 = 0b00100000 = 0x20
srl   2 0 0x01  ; R2 = R0 >> 1 = 0b00000100 = 0x04
sra   3 0 0x01  ; R3 = R0 >>> 1 (arithmetic) = 0x04 (MSB=0, same result here)
ror   4 0 0x03  ; R4 = R0 rotated right 3 times
```

---

## Using the Assembler

```bash
# Compile
gcc -o CO2070Assembler CO2070Assembler.c

# Assemble a program
./CO2070Assembler program.s
# Produces: program.s.machine  (one 32-bit binary string per line)

# Convert to testbench memory image
bash generate_memory_image.sh program.s.machine
```

The `.machine` file contains one 32-bit binary string per instruction line, which the shell script converts into a Verilog `$readmemb`-compatible memory image.
