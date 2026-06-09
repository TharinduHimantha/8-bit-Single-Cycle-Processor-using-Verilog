// ============================================================================
// CO2070 Computer Architecture
// cpu.v

`timescale 1ns/100ps

// ------------------------------------------------------------
// Control Unit 

/* ==================================================================
Unit: control_unit
Description: According to the given OPCODE,
            Outputs ALU operation code,
            WRite Enable signal,
            Immediate, 2s complement selector 
*/
module control_unit (

    // Input / Output
    input  wire [7:0] OPCODE,
    output reg [2:0] ALUOP,
    output reg WRITEENABLE,
    output reg IMM_SEL,     
    output reg NEG_SEL      
);

    // Instruction Opcodes saved as local parameters
    // Values configured according to the Assembler ISA
    localparam OP_LOADI = 8'b00000000;
    localparam OP_MOV   = 8'b00000001;
    localparam OP_ADD   = 8'b00000010;
    localparam OP_SUB   = 8'b00000011;
    localparam OP_AND   = 8'b00000100;
    localparam OP_OR    = 8'b00000101;

    // Control Unit Operations
    always @(OPCODE) begin
        #1; // Artificial decode delay
        ALUOP       = 3'b000;
        WRITEENABLE = 1'b0;
        IMM_SEL     = 1'b0;
        NEG_SEL     = 1'b0;

        // Setting up output according to the OPCODE Input
        // Used case base setup
        case (OPCODE)
            OP_LOADI: begin
                ALUOP       = 3'b000; 
                WRITEENABLE = 1'b1;
                IMM_SEL     = 1'b1;   
                NEG_SEL     = 1'b0;
            end

            OP_MOV: begin
                ALUOP       = 3'b000; 
                WRITEENABLE = 1'b1;
                IMM_SEL     = 1'b0;   
                NEG_SEL     = 1'b0;
            end

            OP_ADD: begin
                ALUOP       = 3'b001; 
                WRITEENABLE = 1'b1;
                IMM_SEL     = 1'b0;
                NEG_SEL     = 1'b0;
            end

            OP_SUB: begin
                ALUOP       = 3'b001; 
                WRITEENABLE = 1'b1;
                IMM_SEL     = 1'b0;
                NEG_SEL     = 1'b1;   
            end

            OP_AND: begin
                ALUOP       = 3'b010; 
                WRITEENABLE = 1'b1;
                IMM_SEL     = 1'b0;
                NEG_SEL     = 1'b0;
            end

            OP_OR: begin
                ALUOP       = 3'b011; 
                WRITEENABLE = 1'b1;
                IMM_SEL     = 1'b0;
                NEG_SEL     = 1'b0;
            end
            
            // default also setup for fault tollerence
            default: begin
                ALUOP       = 3'b000;
                WRITEENABLE = 1'b0;
                IMM_SEL     = 1'b0;
                NEG_SEL     = 1'b0;
            end
        endcase
    end
endmodule

/* ==================================================================
Unit: twos_comp
Description: provide 2's complement for an INPUT
Unit's Delay: 1
*/
module twos_comp (
    input  wire [7:0] DATA,
    output reg  [7:0] RESULT
);
    always @(DATA) begin
        #1 RESULT = ~DATA + 8'b00000001;
    end
endmodule

/* ==================================================================
Unit: pc_adder
Description: register which points to the next instruction.
Initially 0 and resets to 0 at RESET signal
Unit's Delay: 1 delat for write to PC register
*/
module pc_adder (
    input  wire [31:0] PC_IN,
    output reg  [31:0] PC_NEXT
);
    always @(PC_IN) begin
        #1 PC_NEXT = PC_IN + 32'd4;
    end
endmodule

// ------------------------------------------------------------
// Unit: Top-Level CPU Module
// module cpu(PC, INSTRUCTION, CLK, RESET)
//
module cpu (
    output reg  [31:0] PC,          
    input  wire [31:0] INSTRUCTION, 
    input  wire CLK,
    input  wire RESET
);
    // Slicing of Instruction
    wire [7:0] opcode = INSTRUCTION[31:24]; 
    wire [2:0] rd     = INSTRUCTION[18:16]; 
    wire [7:0] imm    = INSTRUCTION[7:0];   

    // Wires for register reading
    reg [2:0] read_reg1_addr;
    reg [2:0] read_reg2_addr;


    // Control Unit Signals
    wire [2:0] aluop;
    wire writeenable;
    wire imm_sel;
    wire neg_sel;

    // Connections in Datapath
    wire [7:0] regout1;   
    wire [7:0] regout2;   
    wire [7:0] twos_result; //twos comp result
    wire [31:0] pc_next;
    wire [7:0] alu_result;

    reg [7:0] mux_sub_out;
    reg [7:0] alu_data2;

    // ----------------------------------------------------------
    // Adresses of two Read registers parsing according to instruction type
    // done based on OPCODE
    always @(*) begin

        // For MOV instructions
        // localparam OP_MOV   = 8'b00000001;
        if (opcode == 8'b00000001) begin
            read_reg1_addr = INSTRUCTION[2:0];  // Source register from Byte 0
            read_reg2_addr = 3'b000;    // for fault tollerence rather than keeping floating

        // Other instructions - ADD, SUB, AND, OR    
        end else begin
            read_reg1_addr = INSTRUCTION[10:8]; // Source 1 - from Byte 1
            read_reg2_addr = INSTRUCTION[2:0];  // Source 2 - from Byte 0
        end
    end

    // Creating instants of each submodule

    // control unit
    control_unit cu (
        .OPCODE (opcode),
        .ALUOP (aluop),
        .WRITEENABLE (writeenable),
        .IMM_SEL (imm_sel),
        .NEG_SEL (neg_sel)
    );

    // register unit
    reg_file rf (
        .IN (alu_result),
        .OUT1 (regout1),
        .OUT2 (regout2),
        .INADDRESS (rd),
        .OUT1ADDRESS (read_reg1_addr), // Routed dynamically
        .OUT2ADDRESS (read_reg2_addr), // Routed dynamically
        .WRITE (writeenable),
        .CLK (CLK),
        .RESET (RESET)
    );

    // twos complement creator
    twos_comp tc (
        .DATA (regout2),
        .RESULT (twos_result)
    );

    //pc adder
    pc_adder pca (
        .PC_IN (PC),
        .PC_NEXT (pc_next)
    );


    // ALU unit
    alu main_alu (
        .DATA1 (regout1),
        .DATA2 (alu_data2),
        .RESULT (alu_result),
        .SELECT(aluop)
    );

// Additional MUXes needed

/* ==================================================================
Unit: MUX
Description: select 8 bit selection based on a control signal
CONTROL SIGNAL: 0 / 1
Unit's Delay: 0
*/

    // MUX 1: 2's Complement Selection
    always @(*) begin
        if (neg_sel)
            mux_sub_out = twos_result;
        else
            mux_sub_out = regout2;
    end

    // MUX 2: Immediate Selection
    always @(*) begin
        if (imm_sel)
            alu_data2 = imm;
        else
            alu_data2 = mux_sub_out;
    end

    // Register Update Logic
    // Happens according to Synchronous CLK
    // PC update delay is present
    always @(posedge CLK) begin
        if (RESET)
            #1 PC <= 32'b0;
        else
            #1 PC <= pc_next;
    end

endmodule