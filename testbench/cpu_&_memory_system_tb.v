// ============================================================================
// CO2070 Computer Architecture
// tb.v
// Testbench for Implementations

`timescale 1ns/100ps

// ===========================================================================
// Simply created Instruction ROM\
// mapped to read the generated machine code file

module instruction_memory(
    input  wire [31:0] pc,
    output reg  [31:0] instruction
);  
    // Setting up the capacity
    reg [7:0] memory_array [1023:0];
    
    initial begin
        // loding the instructions
        $readmemb("memory_test.s.machine", memory_array);
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
// Full workflow test with instances of CPU, Data Memory, Instruction Memory

module tb;
    reg clk;
    reg reset;
    
    // CPU connections
    wire [31:0] pc;
    wire [31:0] instruction;
    wire read, write, busywait;
    wire [7:0] address, writedata, readdata;

    // CPU instance
    cpu mycpu (
        .PC(pc),
        .INSTRUCTION(instruction),
        .CLK(clk),
        .RESET(reset),
        .READ(read),
        .WRITE(write),
        .ADDRESS(address),
        .WRITEDATA(writedata),
        .READDATA(readdata),
        .BUSYWAIT(busywait)
    );

    // Instruction memory instance
    instruction_memory imem (
        .pc(pc),
        .instruction(instruction)
    );


    // Data memory module instance
    // 256 B memory
    data_memory dmem (
        .clock(clk),
        .reset(reset),
        .read(read),
        .write(write),
        .address(address),
        .writedata(writedata),
        .readdata(readdata),
        .busywait(busywait)
    );


    // ---------------------------------------------------------------------
    // Clock Generator
    // Period of 8 ns
    initial begin
        clk = 0;
        forever #4 clk = ~clk; 
    end

    // Main Driver Simulation
    initial begin
        $dumpfile("cpu_memory_wave.vcd");
        $dumpvars(0, tb);

        // ------------------------------------------------------------------------------------------------------------------
        // An Initial Hardware Reset was implemented for better clarity 
        // Hold through 10 time units before beginning executions
        reset = 1;
        #10 reset = 0;

        // Suitable run time setup
        // Run long enough to fully execute all assembly lines
        // and allow enough time for delays by the memory module
        #1000;


        // ############################################################################################
        /*
        Tested Instruction Set
            loadi 1 0x10  // R1 = 0x10 (used as memory address for direct addressing later)
            loadi 2 0x55  // R2 = 0x55 (Test data #1)
            loadi 3 0xAA  // R3 = 0xAA (Test data #2)
            swi 2 0x2A    // Store value of R2 (0x55) into memory address 0x2A
            lwi 4 0x2A    // Load value from memory address 0x2A into R4. (R4 should become 0x55)
            swd 3 1       // Store value of R3 (0xAA) into memory address given by R1 (0x10)
            lwd 5 1       // Load value from memory address given by R1 (0x10) into R5. (R5 should become 0xAA)
            add 6 4 5     // R6 = R4 + R5 (0x55 + 0xAA = 0xFF). Proves RegFile handles post-load operations normally
        */
        
        // ###############################################################################################

        $finish;
    end
endmodule