// ============================================================================
// CO2070 Computer Architecture
// tb_lab7.v
// Testbench for Lab 7: CPU + Instruction Cache + Instruction Memory
//                           + Data Cache + Data Memory
// ============================================================================

// time unit setup
`timescale 1ns/100ps

// ===========================================================================
// Test bench module
// Full workflow test with instances of CPU, Data Cache, Data Memory and Instruction Memory + cache

module tb_lab7;
    reg clk;
    reg reset;

    // ====================================================================================
    // Testbench Components of CPU connections 
    // ====================================================================================

    // ------------------------------------------------------------------
    // CPU to instruction memory cache communications
    wire [31:0] pc;
    wire [31:0] instruction;
    wire        icache_busywait;

    // ------------------------------------------------------------------
    // CPU to data memory cache communications
    wire cpu_read, cpu_write, dcache_busywait;
    wire [7:0] cpu_address, cpu_writedata, cpu_readdata;

    // masking busy wait signals to stalling cpu memory operations
    // to stop garbage memory data
    wire cpu_read_masked  = cpu_read  & ~icache_busywait;
    wire cpu_write_masked = cpu_write & ~icache_busywait;

    // Master stalling signal
    // CPU must wait if EITHER cache is busy
    wire overall_busywait = icache_busywait | dcache_busywait;



    // ====================================================================================
    // Testbench Components of Memory units
    // Both Instruction memory unit and Data Memory unit
    // ====================================================================================

    // Instruction cache to instruction memory communications
    wire        imem_read, imem_busywait;
    wire [5:0]  imem_address;
    wire [127:0] imem_readinst;

    // Data cache to data memory communications
    wire dmem_read, dmem_write, dmem_busywait;
    wire [5:0]  dmem_address;
    wire [31:0] dmem_writedata, dmem_readdata;


    // ====================================================================================
    // Module Instances
    // ====================================================================================

    // CPU
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
        .BUSYWAIT(overall_busywait)
    );

    // Instruction cache
    icache myicache (
        .clock(clk),
        .reset(reset),
        .address(pc[9:0]),
        .instruction(instruction),
        .busywait(icache_busywait),

        .mem_read(imem_read),
        .mem_address(imem_address),
        .mem_readinst(imem_readinst),
        .mem_busywait(imem_busywait)
    );

    // Instruction memory
    instruction_memory imem (
        .clock(clk),
        .read(imem_read),
        .address(imem_address),
        .readinst(imem_readinst),
        .busywait(imem_busywait)
    );

    // Data cache
    dcache mydcache (
        .clock(clk),
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

    // Data memory
    data_memory dmem (
        .clock(clk),
        .reset(reset),
        .read(dmem_read),
        .write(dmem_write),
        .address(dmem_address),
        .writedata(dmem_writedata),
        .readdata(dmem_readdata),
        .busywait(dmem_busywait)
    );

    // ====================================================================================
    // Test Components Setup
    // ====================================================================================


    // ---------------------------------------------------------------------
    // Clock Generator
    // Period of 8 ns

    initial begin
        clk = 0;
        forever #4 clk = ~clk;
    end

    // Wires to tap register values
    wire [7:0] r0 = mycpu.rf.registers[0];
    wire [7:0] r1 = mycpu.rf.registers[1];
    wire [7:0] r2 = mycpu.rf.registers[2];
    wire [7:0] r3 = mycpu.rf.registers[3];
    wire [7:0] r4 = mycpu.rf.registers[4];
    wire [7:0] r5 = mycpu.rf.registers[5];
    wire [7:0] r6 = mycpu.rf.registers[6];
    wire [7:0] r7 = mycpu.rf.registers[7];


    // ---------------------------------------------------------------------
    // Activity monitoring Console Log
    // For Hit and Miss checks

    // whenever either cache is doing something,prints each cycle
    // also eache reg write
    // ------------------------------------------------------------------

    always @(posedge clk) begin
        if (!reset)
            $display("t=%0t | PC=%0d | I$ busy=%b (state=%0d) | D$ busy=%b (state=%0d) | READ=%b WRITE=%b ADDR=%h",
                       $time, pc, icache_busywait, myicache.state,
                       dcache_busywait, mydcache.state,
                       cpu_read_masked, cpu_write_masked, cpu_address);
    end

    // Writes to Reg file monitor
    always @(posedge clk) begin
        if (!reset && mycpu.gated_writeenable)
            $display("            -> REG WRITE: R%0d <= 0x%02h  (t=%0t)",
                       mycpu.rd, mycpu.reg_in_data, $time);
    end

    // -------------------------------------.--
    // Main Driver Simulation
    initial begin
        // Creating the waveform file
        $dumpfile("cpu_icache_dcache_wave.vcd");
        $dumpvars(0, tb_lab7);

        // ------------------------------------------------------------------
        // An Initial Hardware Reset was implemented for better clarity
        // Held for 10 time units before initial executions
        reset = 1;
        #10 reset = 0;

        // Timeout backstop for handle infinite loop cases
        #10000;
        $display("TIMEOUT: self-loop instruction never reached!");
        $finish;
    end

    // actual execution
    always @(posedge clk) begin
        if (!reset && pc == 168 && !overall_busywait) begin
            $display("");
            $display("================= Final Register Values =================");
            $display("R0 (expect 0x15 = F8 = 21) = 0x%02h", mycpu.rf.registers[0]);
            $display("R1 (expect 0x22 = F9 = 34) = 0x%02h", mycpu.rf.registers[1]);
            $display("R2 (expect 0x22 = F9 = 34) = 0x%02h", mycpu.rf.registers[2]);
            $display("R3 (expect 0x00 = F0 = 0)  = 0x%02h", mycpu.rf.registers[3]);
            $display("R4 (expect 0x05 = F5 = 5)  = 0x%02h", mycpu.rf.registers[4]);
            $display("R5 (expect 0x22 = F9 = 34) = 0x%02h", mycpu.rf.registers[5]);
            $display("R6 (expect 0x20)           = 0x%02h", mycpu.rf.registers[6]);
            $display("R7 (expect 0x00, fresh blk)= 0x%02h", mycpu.rf.registers[7]);
            $display("===========================================================");
            $finish;
        end
    end
endmodule
