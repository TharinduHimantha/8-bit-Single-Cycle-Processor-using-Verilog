// ============================================================================
// CO2070 Computer Architecture
// File: control_unit_tb.v
// Description: Dedicated standalone unit testbench for the Control Unit.
// ============================================================================

`timescale 1ns/100ps

module control_unit_tb;

    // ------------------------------------------------------------------------
    // Testbench Signals
    // ------------------------------------------------------------------------
    reg  [7:0] TB_OPCODE;
    wire [2:0] TB_ALUOP;
    wire       TB_WRITEENABLE;
    wire       TB_IMM_SEL;
    wire       TB_NEG_SEL;

    // ------------------------------------------------------------------------
    // Unit Under Test
    // ------------------------------------------------------------------------
    control_unit uut (
        .OPCODE      (TB_OPCODE),
        .ALUOP       (TB_ALUOP),
        .WRITEENABLE (TB_WRITEENABLE),
        .IMM_SEL     (TB_IMM_SEL),
        .NEG_SEL     (TB_NEG_SEL)
    );


    initial begin
        // Setup GTKWave trace dump files
        $dumpfile("control_unit_wave.vcd");
        $dumpvars(0, control_unit_tb);


        // For reference 
            // Instruction Opcodes saved as local parameters
    // Values configured according to the Assembler ISA
    // localparam OP_LOADI = 8'b00000000;
    // localparam OP_MOV   = 8'b00000001;
    // localparam OP_ADD   = 8'b00000010;
    // localparam OP_SUB   = 8'b00000011;
    // localparam OP_AND   = 8'b00000100;
    // localparam OP_OR    = 8'b00000101;

        // Table Header
        $display("\n=====================================================================");
        $display("   TIME   |  OPCODE  | ALUOP | WRITEENABLE | IMM_SEL | NEG_SEL |  STATE  ");
        $display("=====================================================================");

        // Case 1: OP_LOADI (0x00)
        TB_OPCODE = 8'b00000000;
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | LOADI", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        // Case 2: OP_MOV (0x01)
        TB_OPCODE = 8'b00000001;
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | MOV", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        // Case 3: OP_ADD (0x02)
        TB_OPCODE = 8'b00000010;
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | ADD", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        //Case 4: OP_SUB (0x03)
        TB_OPCODE = 8'b00000011;
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | SUB", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        //Case 5: OP_AND (0x04)
        TB_OPCODE = 8'b00000100;
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | AND", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        //Case 6: OP_OR (0x05)
        TB_OPCODE = 8'b00000101;
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | OR", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        // Case 7: Invalid or  Unknown Opcode 0xFF
        TB_OPCODE = 8'b11111111; 
        #10;
        $display("%7t ns | 8'b%b |  %3b  |      %b      |    %b    |    %b    | DEFAULT/NOP", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL);

        $display("=====================================================================\n");
        
        // Terminating Simulation
        $finish;
    end

endmodule