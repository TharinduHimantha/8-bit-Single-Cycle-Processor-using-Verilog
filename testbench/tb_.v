// ============================================================================
// Testbench for Top-Level Processor
// Top-Level Module Under Test: top_level_processor
// ============================================================================

`timescale 1ns/100ps

module tb_top_level_processor;

    // ========================================================================
    // Testbench Clock and Reset Signals
    // ========================================================================
    reg clock;
    reg reset;

    // ========================================================================
    // Unit Under Test (UUT) Instance
    // ========================================================================
    top_level_processor uut (
        .clock(clock),
        .reset(reset)
    );

    // ========================================================================
    // Clock Generator (8ns Period / 125MHz)
    // ========================================================================
    initial begin
        clock = 0;
        forever #4 clock = ~clock;
    end

    // ========================================================================
    // Wires to Monitor Internal Register File States
    // Hierarchical probing into uut -> mycpu -> rf
    // ========================================================================
    wire [7:0] r0 = uut.mycpu.rf.registers[0];
    wire [7:0] r1 = uut.mycpu.rf.registers[1];
    wire [7:0] r2 = uut.mycpu.rf.registers[2];
    wire [7:0] r3 = uut.mycpu.rf.registers[3];
    wire [7:0] r4 = uut.mycpu.rf.registers[4];
    wire [7:0] r5 = uut.mycpu.rf.registers[5];
    wire [7:0] r6 = uut.mycpu.rf.registers[6];
    wire [7:0] r7 = uut.mycpu.rf.registers[7];

    // Read PC and Busywait status for logging
    wire [31:0] current_pc     = uut.mycpu.PC;
    wire        busywait_state = uut.overall_busywait;

    // ========================================================================
    // Main Driver & Waveform Dump Setup
    // ========================================================================
    initial begin
        // VCD Waveform Output Setup
        $dumpfile("top_level_processor_wave.vcd");
        $dumpvars(0, tb_top_level_processor);

        // Assert Initial Reset
        reset = 1;
        #10 reset = 0;

        // Safety Timeout Backstop
        #10000;
        $display("\n[TIMEOUT] Simulation exceeded maximum time limit!");
        $finish;
    end

    // ========================================================================
    // Activity Loggers & Monitors
    // ========================================================================

    // Log Register Writes
    always @(posedge clock) begin
        if (!reset && uut.mycpu.gated_writeenable) begin
            $display("t=%0t | PC=%0d | REG WRITE: R%0d <= 0x%02h",
                     $time, current_pc, uut.mycpu.rd, uut.mycpu.reg_in_data);
        end
    end


endmodule