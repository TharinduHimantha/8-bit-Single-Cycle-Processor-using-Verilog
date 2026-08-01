# CO2070 8 bit Processor Simulation Workflow

End-to-end guide for assembling a test program and simulating the CPU,
instruction cache, data cache, and memory hierarchy in Icarus Verilog,
then inspecting the results in GTKWave.

---

## 0. Prerequisites

Install the toolchain once per machine.

**Ubuntu / Debian / WSL**
```bash
sudo apt-get update
sudo apt-get install -y iverilog gtkwave gcc
```

**macOS (Homebrew)**
```bash
brew install icarus-verilog gtkwave
```

**Windows**
Install WSL (Windows Subsystem for Linux) and follow the Ubuntu instructions above.

Verify the install:
```bash
iverilog -V
gtkwave --version
gcc --version
```

---

## 1. Project Layout

Put everything in one flat working folder (no subdirectories needed):

```
cpu.v
reg_file.v
alu.v                
icache.v
insmem.v
dcache.v
dmem.v
top_level_processor.v
tb_.v
CO2070Assembler.c
my_program.s
```


---

## 2. Build the Assembler *(once only)*

```bash
gcc -o CO2070Assembler CO2070Assembler.c
```

This produces the `CO2070Assembler` executable used to compile every
`.s` program you write from here on.

---

## 3. Write Your Assembly Program

Create a `.s` file, for example `my_program.s`:

```assembly
loadi 4 0x05    // R4 = 5
loadi 2 0x09    // R2 = 9
add   6 4 2     // R6 = R4 + R2
loadi 1 0x01    // R1 = 1
add   2 2 1     // R2 = R2 + R1
```

### Rules

| Rule | Detail |
|---|---|
| Format | One instruction per line |
| Registers | `0`–`7` only |
| Immediates | Hex, range `0x00`–`0xFF` |
| Comments | Start with `//` |

---

## 4. Assemble the Program

```bash
./CO2070Assembler my_program.s
```

This produces `my_program.s.machine` — one 32-character binary line per
instruction, with **no separators** between bytes.

---

## 5. Generate the Instruction Memory Image

`$readmemb` can't split an unbroken 32-character line into four 8-bit
words on its own, so reformat the assembler output into one byte per
line (least-significant byte first — this matches how `memory_array` is
addressed in both `insmem.v` and `dmem.v`):

```bash
awk '{print substr($0,25,8) "\n" substr($0,17,8) "\n" substr($0,9,8) "\n" substr($0,1,8)}' \
    my_program.s.machine > my_program.instr.mem
```

Sanity-check the output:
```bash
head my_program.instr.mem
```
You should see one 8-character binary byte per line.

> Make sure `insmem.v`'s `$readmemb(...)` call points at this exact
> filename (`my_program.instr.mem`).

---

## 6. Compile the Verilog Design

```bash
iverilog -o sim cpu.v reg_file.v alu.v icache.v insmem.v dcache.v dmem.v top_level_processor.v tb_.v
```

A clean compile returns silently to the prompt. Any errors will name the
offending file and line number — fix those before moving on.

---

## 7. Run the Simulation

```bash
vvp sim
```


This also silently will write a waveform dump to the same folder.

---

## 8. Inspect the Waveform in GTKWave

```bash
gtkwave waveform_file_name.vcd
```

---

## Workflow Summary

| # | Step | Command |
|---|---|---|
| 1 | Install tools | `apt-get install iverilog gtkwave gcc` |
| 2 | Build assembler | `gcc -o CO2070Assembler CO2070Assembler.c` |
| 3 | Write program | edit `my_program.s` |
| 4 | Assemble | `./CO2070Assembler my_program.s` |
| 5 | Generate memory image | `awk ... > my_program.instr.mem` |
| 6 | Compile design | `iverilog -o sim *.v` |
| 7 | Simulate | `vvp sim` |
| 8 | Inspect waveform | `gtkwave *.vcd` |

---

## Troubleshooting

| Problem | Likely Cause |
|---|---|
| `iverilog: command not found` | Toolchain install didn't complete — redo Step 0 |
| Compile error: `alu` undefined | `alu.v` wasn't included in the `iverilog` command |
| `$readmemb` warns "not enough words" | Harmless — `memory_array` is sized larger than your program needs |
| No `.vcd` file appears | Simulation crashed before `$finish` — check the `vvp` output for the real error |
| GTKWave shows the signal tree but no waveform | Signals must be dragged/appended into the right-hand pane — selecting them in the tree alone doesn't plot them |
| Register array doesn't appear under `rf` in GTKWave | `$dumpvars` doesn't capture memory arrays automatically — use top-level tap wires (`r0`–`r7`) instead |
| Register values wrong after `mov` | Known datapath issue where `mov` and `loadi` share an ALU select code — verify your `alu.v`/`cpu.v` handle this correctly, or avoid `mov` and use `add Rd, Rs, Rzero` with a register held at `0` |
