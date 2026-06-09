# CPU Simulation Workflow

## Step 1 — Compile the Assembler (Once Only)

```bash
gcc CO2070Assembler.c -o CO2070Assembler
chmod +x generate_memory_image.sh
```

---

## Step 2 — Write Your Assembly Program

Create a `.s` file, for example `my_program.s`:

```assembly
loadi 4 0x05    // R4 = 5
loadi 2 0x09    // R2 = 9
add   6 4 2     // R6 = R4 + R2
mov   0 6       // R0 = R6
loadi 1 0x01    // R1 = 1
add   2 2 1     // R2 = R2 + R1
```

### Rules

- One instruction per line.
- Register numbers must be in the range **0–7**.
- Immediate values must be in the range **0x00–0xFF**.
- Comments begin with `//`.

---

## Step 3 — Assemble and Generate the Memory Image

Run:

```bash
./generate_memory_image.sh my_program.s
```

This generates an `instr_mem.mem` file in the current directory.

Move it into the `programmer/` subdirectory:

```bash
mv instr_mem.mem programmer/
```

---

## Step 4 — Simulate

### Compile

```bash
iverilog -o cpu_sim cpu_tb.v cpu.v alu.v reg_file.v
```

### Run

```bash
vvp cpu_sim
```

### View Waveform (GTKWave)

```bash
gtkwave cpu_wavedata.vcd
```

---

## Workflow Summary

1. Compile the assembler.
2. Write an assembly program (`.s` file).
3. Generate the memory image (`instr_mem.mem`).
4. Move the memory image to `programmer/`.
5. Compile the Verilog design.
6. Run the simulation.
7. Inspect waveforms using GTKWave.