// ============================================================================
// CO2070 Computer Architecture
// cpu_tb.v

`timescale 1ns/100ps

module cpu_tb;

    // Input /Output setup for CPU
    reg CLK;
    reg RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;


    // Array for instructions
    reg [7:0] instr_mem [0:1023];
    integer i;

    // Asynchronously Reading Instructions from memory
    // With a latency of #2 
    assign #2 INSTRUCTION = {instr_mem[PC+3], instr_mem[PC+2], instr_mem[PC+1], instr_mem[PC]};

    // CPU Module Instance
    cpu mycpu (
        .PC(PC),
        .INSTRUCTION(INSTRUCTION),
        .CLK(CLK),
        .RESET(RESET)
    );

    // ---------------------------------------------------------------------
    // Clock Generator
    // Period of 8 ns
    initial CLK = 1'b0;
    always #4 CLK = ~CLK;

    // Main Driver Simulation
    initial
    begin
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);

        CLK   = 1'b0;
        RESET = 1'b0; 

        // Force populate memory cells
        // Alternative NOP operations as 8'hFF
        // Used to stop WRITEENABLE getting stuck in High specially during empty cycles
        for (i = 0; i < 1024; i = i + 1) begin
            instr_mem[i] = 8'hFF; 
        end

        // Read compiled program file
        $readmemb("instr_mem.mem", instr_mem);
        #1; // Hardware cell stabilization window


        // ------------------------------------------------------------------------------------------------------------------
        // An Initial Hardware Reset was implemented for better clarity 
        // Hold through one full clock cycle period before beginning executions
        RESET = 1'b1;
        #8;

        // Value down at Negative CLK edge
        @(negedge CLK);
        RESET = 1'b0;

        // Run long enough to fully execute all 6 assembly lines
        // Suitable run time setup
        #120;



        // ############################################################################################
        /*
        Tested Instruction Set
            loadi 1 0xB6
            loadi 2 0x6D
            and 3 1 2
            or 4 1 2
            add 5 4 1
            mov 6 3
            sub 4 5 2
        */
        // ###############################################################################################
        $finish;
    end

    // Signal Tracing Monitor Terminal Output
    initial
    begin
        $monitor("Time=%0t ns | PC=%0d | Instr=0x%h | ALU_Out=0x%h | RegWriteEnable=%b",
         $time, PC, INSTRUCTION, mycpu.alu_result, mycpu.writeenable);
    end

endmodule