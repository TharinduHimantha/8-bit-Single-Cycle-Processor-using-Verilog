// ============================================================================
// CO2070 Computer Architecture
// tb_lab6.v
// Testbench for Lab 6: CPU + Data Cache + Data Memory

`timescale 1ns/100ps

// ===========================================================================
// Simply created Instruction ROM
// mapped to read the generated machine code file

module instruction_memory(
    input  wire [31:0] pc,
    output reg  [31:0] instruction
);
    // Setting up the capacity
    reg [7:0] memory_array [1023:0];

    initial begin
        // Loading the instructions.
        // NOTE: the raw assembler output (cache_test.s.machine) packs each
        // 32-bit instruction as a single continuous 32-character line with
        // no separators, so $readmemb cannot split it into four 8-bit
        // words on its own. We pre-format it (one whitespace-separated
        // 8-bit token per byte, most-significant byte first) into
        // cache_test.instr.mem before running this testbench - see
        // build_and_run.sh / the awk one-liner in the README.
        $readmemb("locality_test.instr.mem", memory_array);
    end

    always @(pc) begin

        // Asynchronously Reading Instructions from memory
        // With a latency of #2

        #2;     // Instruction fetch delay
        instruction = {memory_array[pc], memory_array[pc+1], memory_array[pc+2], memory_array[pc+3]};
    end
endmodule


// ===========================================================================
// Test bench module
// Full workflow test with instances of CPU, Data Cache, Data Memory and Instruction Memory

module tb_lab6;
    reg clk;
    reg reset;

    // Cache connections with CPU 
    wire [31:0] pc;
    wire [31:0] instruction;
    wire cpu_read, cpu_write, cpu_busywait;
    wire [7:0] cpu_address, cpu_writedata, cpu_readdata;

    // Cache connections with memory
    wire mem_read, mem_write, mem_busywait;
    wire [5:0]  mem_address;
    wire [31:0] mem_writedata, mem_readdata;

    // Instantiation of CPU
    cpu mycpu (
        .PC(pc),
        .INSTRUCTION(instruction),
        .CLK(clk),
        .RESET(reset),
        .READ(cpu_read),
        .WRITE(cpu_write),
        .ADDRESS(cpu_address),
        .WRITEDATA(cpu_writedata),
        .READDATA(cpu_readdata),
        .BUSYWAIT(cpu_busywait)
    );

    // Instruction memory instance
    instruction_memory imem (
        .pc(pc),
        .instruction(instruction)
    );

    // Instantiating Data cache
    dcache mycache (
        .clock(clk),
        .reset(reset),

        .read(cpu_read),
        .write(cpu_write),
        .address(cpu_address),
        .writedata(cpu_writedata),
        .readdata(cpu_readdata),
        .busywait(cpu_busywait),

        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_writedata(mem_writedata),
        .mem_readdata(mem_readdata),
        .mem_busywait(mem_busywait)
    );

    // Instantiating Data Memory
    // 4-byte block based
    // 64 blocks x 4B = 256B
    data_memory dmem (
        .clock(clk),
        .reset(reset),
        .read(mem_read),
        .write(mem_write),
        .address(mem_address),
        .writedata(mem_writedata),
        .readdata(mem_readdata),
        .busywait(mem_busywait)
    );

    // ---------------------------------------------------------------------
    // Clock Generator
    // Period of 8 ns

    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    // ---------------------------------------------------------------------
    // Activity monitor
    // For Hit and Miss checks

    always @(posedge clk) begin
        if (!reset && (cpu_read || cpu_write))
            $display("t=%0t | PC=%0d | Read=%b Write=%b ADDR=%h | CACHE busywait=%b | MEMORY busywait=%b | FSM state=%0d",
                       $time, pc, cpu_read, cpu_write, cpu_address, cpu_busywait, mem_busywait, mycache.state);
    end

    // Main Driver Simulation
    initial begin
        $dumpfile("locality_test_wave.vcd");
        $dumpvars(0, tb_lab6);

        // ------------------------------------------------------------------
        // An Initial Hardware Reset was implemented for better clarity
        // Held for 10 time units before initial executions
        reset = 1;
        #10 reset = 0;

        // Aproppriate run time setup
        // 21 cycle, 42 cycle Penalty misses were taken into consideration
        #1130;

        // ####################################################################
        /*
        Tested Instruction Set on cache_test.s)
            loadi 1 0x11
            loadi 2 0x22
            swi   1 0x00   // Write Miss (not DIRTY - clean)  -  Tag0  Idx 0
            lwi   3 0x00   // Read Hit
            swi   2 0x04   // Write Miss (not DIRTY - clean)  -  Tag0  Idx 1
            lwi   4 0x04   // Read Hit
            swi   1 0x20   // Write Miss (DIRTY --> evict Idx 0) -  Tag1 Idx 0
            lwi   5 0x20   // Read Hit
            lwi   6 0x00   // read-miss (DIRTY --> evict Idx 0) -  Tag0 Idx 0
            loadi 7 0x33
            swi   7 0x00   // Write Hit
            lwi   0 0x00   // Read Hit (0x33 is expected)
        */
        // ####################################################################

        // To get fnal register values in Reg File

        $display("Final Register Values:");
        $display("R3 (expected value: 0x11) = %h", mycpu.rf.registers[3]);
        $display("R4 (expected value: 0x22) = %h", mycpu.rf.registers[4]);
        $display("R5 (expected value: 0x11) = %h", mycpu.rf.registers[5]);
        $display("R6 (expected value: 0x11) = %h", mycpu.rf.registers[6]);
        $display("R0 (expected value: 0x33) = %h", mycpu.rf.registers[0]);

        $finish;
    end
endmodule
