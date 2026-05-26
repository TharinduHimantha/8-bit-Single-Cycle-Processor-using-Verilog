// Setting up the time step
`timescale 1ns/100ps

module alu_tb;

    // Testbench Components Setup
    reg  [7:0] OPERAND1;
    reg  [7:0] OPERAND2;
    reg  [2:0] ALUOP;
    wire [7:0] ALURESULT;


    // Instantiating uut - alu module 
    alu uut (
        .DATA1(OPERAND1),
        .DATA2(OPERAND2),
        .RESULT(ALURESULT),
        .SELECT(ALUOP)
    );


    // Test Sequence.....


    initial begin

        // Generating the waveform file for GTKWave
        $dumpfile("group13_lab2_part1_waves.vcd");
        $dumpvars(0, alu_tb);

        // Output formatting for console display
        $display("\n.. Monitoring ALU Components .. \n");
        $display("Time\t |\tALUOP\t |\tOP1\t |\tOP2\t |\tRESULT");
        $display("-----------------------------------------------------------------------------");
        
        // continously showcase, when at least one component get changed
        $monitor("%0t\t |\t%b\t |\t%d\t |\t%d\t |\t%d", $time, ALUOP, OPERAND1, OPERAND2, ALURESULT);

        //for system stabilizing
        #10;

        // For inputs hex values were used siince 8 bit operands needs to be given

        // 1. Initialize Inputs
        OPERAND1 = 8'h00;
        OPERAND2 = 8'h00;
        ALUOP    = 3'b000;
        
        // Let the system stabilize
        #10;

        // 2. Test FORWARD -> SELECT = 000
        // Should forward DATA2: 255 to RESULT
        ALUOP    = 3'b000; 
        OPERAND1 = 8'h00; // Not used in this instance
        OPERAND2 = 8'hAA; 
        #10;

        // 3. Test ADD -> SELECT = 001
        // 0x03 + 0x0A = 0x0D = 13
        ALUOP    = 3'b001; 
        OPERAND1 = 8'h03; 
        OPERAND2 = 8'h0A; 
        #10;

        // 4. Test AND -> SELECT = 010
        // 0xFF & 0x0F =  0x0F = 15
        ALUOP    = 3'b010; 
        OPERAND1 = 8'hFF; 
        OPERAND2 = 8'h0F; 
        #10;

        // 5. Test OR -> SELECT = 011
        // 0xF0 | 0x0F = 0xFF = 255
        ALUOP    = 3'b011; 
        OPERAND1 = 8'hF0; 
        OPERAND2 = 8'h0F; 
        #10;

        // 6. Test for Unused Combination -> SELECT = 1XX
        // As by the implementation, must output 0x00
        ALUOP    = 3'b101;  //101 was used
        OPERAND1 = 8'hFF; 
        OPERAND2 = 8'hFF; 
        #10;

        // Simulation termination at end
        $finish;
    end

endmodule