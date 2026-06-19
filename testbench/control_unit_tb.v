`timescale 1ns/100ps

module control_unit_tb;
    // Testbench Signals
    reg  [7:0] TB_OPCODE;
    wire [2:0] TB_ALUOP;
    wire       TB_WRITEENABLE;
    wire       TB_IMM_SEL;
    wire       TB_NEG_SEL;
    wire       TB_JUMP;
    wire       TB_BRANCH_EQ;
    wire       TB_BRANCH_NEQ;
    wire [1:0] TB_SHIFT_SEL;

    control_unit uut (
        .OPCODE      (TB_OPCODE),
        .ALUOP       (TB_ALUOP),
        .WRITEENABLE (TB_WRITEENABLE),
        .IMM_SEL     (TB_IMM_SEL),
        .NEG_SEL     (TB_NEG_SEL),
        .JUMP        (TB_JUMP),
        .BRANCH_EQ   (TB_BRANCH_EQ),
        .BRANCH_NEQ  (TB_BRANCH_NEQ),
        .SHIFT_SEL   (TB_SHIFT_SEL)
    );

    initial begin
        $dumpfile("control_unit_wave.vcd");
        $dumpvars(0, control_unit_tb);

        $display("\n=========================================================================================================");
        $display("   TIME   |  OPCODE  | ALUOP | W_EN | IMM | NEG | JUMP | BEQ | BNE | SH_SEL | STATE  ");
        $display("=========================================================================================================");

        TB_OPCODE = 8'b00000000; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | LOADI", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);

        // ... (Include intermediate tests like ADD, SUB, AND, OR) ...

        TB_OPCODE = 8'b00001000; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | MULT", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);

        TB_OPCODE = 8'b00001001; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | SLL", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);

        TB_OPCODE = 8'b00001010; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | SRL", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);
                 
        TB_OPCODE = 8'b00001011; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | SRA", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);

        TB_OPCODE = 8'b00001100; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | ROR", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);

        TB_OPCODE = 8'b00001101; #10;
        $display("%7t ns | 8'b%b |  %3b  |  %b   |  %b  |  %b  |  %b   |  %b  |  %b  |   %2b   | BNE", 
                 $time, TB_OPCODE, TB_ALUOP, TB_WRITEENABLE, TB_IMM_SEL, TB_NEG_SEL, TB_JUMP, TB_BRANCH_EQ, TB_BRANCH_NEQ, TB_SHIFT_SEL);

        $display("=========================================================================================================\n");
        $finish;
    end
endmodule