# Timing Reference - 8-bit Single-Cycle Processor

## Clock Cycle

One clock cycle = **8 time units**, rising edge to rising edge.

Every instruction must complete within 8 time units. Register writes and PC updates happen on the **rising edge at the end** of the cycle.

---

## Artificial Delays (Simulation Model)

| Component | Delay | Type |
|-----------|-------|------|
| PC write | `#1` | Sequential (clocked) |
| Instruction memory read | `#2` | Combinational |
| PC+4 adder | `#1` | Combinational (parallel to memory read) |
| Instruction decode | `#1` | Combinational |
| Register file read | `#2` | Asynchronous |
| Register file write | `#1` | Sequential (clocked) |
| 2's complement unit | `#1` | Combinational |
| ALU — FORWARD / AND / OR | `#1` | Combinational |
| ALU — ADD | `#2` | Combinational |
| Branch/jump target adder | `#2` | Combinational (parallel to ALU) |

MUXes and wires are assumed to have **negligible delay**.

---

## Important Considerations

* MUXes and wires are assumed to have **negligible delay**.

* Immediate comes directly from instruction bits.

* PC+4 adder runs in parallel through PC adder and its result is discarded (not taken).

* The branch target adder runs in parallel with register read. If ZERO is asserted, the branch target is selected for PC; otherwise PC+4 is used.

---

## Reset Behaviour

- RESET is synchronous, triggered on the **positive clock edge**
- When RESET is high at a rising edge: `PC ← 0` and all registers ← `0`
- Processor restarts execution from instruction memory address `0x00000000`
