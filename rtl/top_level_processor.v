// ============================================================================
// Top-Level Processor Wrapper
// Instantiates CPU, Instruction Cache, Instruction Memory, 
// Data Cache, and Data Memory.
// ============================================================================

`timescale 1ns/100ps

module top_level_processor (
    input wire clock,
    input wire reset
);

    // ========================================================================
    // Internal Interconnect Signals
    // =======================================================================

    // ------------------------------------------------------------------------
    // 1. CPU <-> Instruction Cache Communications
    
    wire [31:0] pc;               // Program Counter from CPU
    wire [31:0] instruction;      // Fetched instruction from I-Cache
    wire        icache_busywait;  // I-Cache stall signal


    // ------------------------------------------------------------------------
    // 2. CPU <-> Data Cache Communications
    
    wire       cpu_read;          // CPU data read control signal
    wire       cpu_write;         // CPU data write control signal
    wire       dcache_busywait;   // D-Cache stall signal
    wire [7:0] cpu_address;       // Memory address driven by CPU
    wire [7:0] cpu_writedata;     // Data to write driven by CPU
    wire [7:0] cpu_readdata;      // Data read from D-Cache


    // Mask CPU read/write signals with icache_busywait to prevent spurious 
    // memory requests during instruction-cache fetch stalls
    wire cpu_read_masked  = cpu_read  & ~icache_busywait;
    wire cpu_write_masked = cpu_write & ~icache_busywait;

    // Master busywait signal stalling the CPU whenever either cache is busy
    wire overall_busywait = icache_busywait | dcache_busywait;


    // ------------------------------------------------------------------------
    // 3. Instruction Cache <-> Instruction Memory Communications
    
    wire         imem_read;       // Read request from I-Cache to I-Mem
    wire         imem_busywait;   // Stall signal from I-Mem to I-Cache
    wire [5:0]   imem_address;    // Block address to I-Mem
    wire [127:0] imem_readinst;   // 16-byte instruction block from I-Mem


    // ------------------------------------------------------------------------
    // 4. Data Cache <-> Data Memory Communications
    
    wire        dmem_read;        // Read request from D-Cache to D-Mem
    wire        dmem_write;       // Write request from D-Cache to D-Mem
    wire        dmem_busywait;    // Stall signal from D-Mem to D-Cache
    wire [5:0]  dmem_address;     // Block address to D-Mem
    wire [31:0] dmem_writedata;   // Block write-data from D-Cache to D-Mem
    wire [31:0] dmem_readdata;    // Block read-data from D-Mem to D-Cache



    // ========================================================================
    // Module Instantiations
    // ========================================================================

    // 1. CPU Instance
    cpu mycpu (
        .PC(pc),
        .INSTRUCTION(instruction),
        .CLK(clock),
        .RESET(reset),
        .READ(cpu_read),
        .WRITE(cpu_write),
        .ADDRESS(cpu_address),
        .WRITEDATA(cpu_writedata),
        .READDATA(cpu_readdata),
        .BUSYWAIT(overall_busywait)
    );

    // 2. Instruction Cache Instance
    icache myicache (
        .clock(clock),
        .reset(reset),
        .address(pc[9:0]),
        .instruction(instruction),
        .busywait(icache_busywait),

        .mem_read(imem_read),
        .mem_address(imem_address),
        .mem_readinst(imem_readinst),
        .mem_busywait(imem_busywait)
    );

    // 3. Instruction Memory Instance
    instruction_memory imem (
        .clock(clock),
        .read(imem_read),
        .address(imem_address),
        .readinst(imem_readinst),
        .busywait(imem_busywait)
    );

    // 4. Data Cache Instance
    dcache mydcache (
        .clock(clock),
        .reset(reset),

        .read(cpu_read_masked),
        .write(cpu_write_masked),
        .address(cpu_address),
        .writedata(cpu_writedata),
        .readdata(cpu_readdata),
        .busywait(dcache_busywait),

        .mem_read(dmem_read),
        .mem_write(dmem_write),
        .mem_address(dmem_address),
        .mem_writedata(dmem_writedata),
        .mem_readdata(dmem_readdata),
        .mem_busywait(dmem_busywait)
    );

    // 5. Data Memory Instance
    data_memory dmem (
        .clock(clock),
        .reset(reset),
        .read(dmem_read),
        .write(dmem_write),
        .address(dmem_address),
        .writedata(dmem_writedata),
        .readdata(dmem_readdata),
        .busywait(dmem_busywait)
    );

endmodule