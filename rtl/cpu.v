`timescale 1ns/100ps

// ------------------------------------------------------------
// Control Unit 

/* ==================================================================
Unit: control_unit
Description: According to the given OPCODE,
            Outputs ALU operation code,
            WRite Enable signal,
            Immediate, 2s complement selector
Newly Implemented : Control Signals related to memory unit
*/

module control_unit (
    input  wire [7:0] OPCODE,
    output reg [2:0] ALUOP,
    output reg WRITEENABLE,
    output reg IMM_SEL,  
    output reg NEG_SEL,
    output reg JUMP,        
    output reg BRANCH_EQ,   
    output reg BRANCH_NEQ,  
    output reg [1:0] SHIFT_SEL,
    
    // Newly implemented Data Memory Control Signals
    output reg MEM_READ,
    output reg MEM_WRITE,
    output reg MEM_TO_REG,

    // 0- RegDirect (RS)
    // 1- Immediate (IMM)
    output reg MEM_ADDR_SEL 
);
    // Instruction Opcodes saved as local parameters
    // Values configured according to the Assembler ISA
    localparam OP_LOADI = 8'b00000000;
    localparam OP_MOV   = 8'b00000001;
    localparam OP_ADD   = 8'b00000010;
    localparam OP_SUB   = 8'b00000011;
    localparam OP_AND   = 8'b00000100;
    localparam OP_OR    = 8'b00000101;
    localparam OP_J     = 8'b00000110;
    localparam OP_BEQ   = 8'b00000111;

    localparam OP_MULT  = 8'b00001000;
    localparam OP_SLL   = 8'b00001001;
    localparam OP_SRL   = 8'b00001010;
    localparam OP_SRA   = 8'b00001011;
    localparam OP_ROR   = 8'b00001100;
    localparam OP_BNE   = 8'b00001101;

    // Memory Access Opcodes
    localparam OP_LWD   = 8'b00001110;
    localparam OP_LWI   = 8'b00001111;
    localparam OP_SWD   = 8'b00010000;
    localparam OP_SWI   = 8'b00010001;

    always @(OPCODE) begin
        #1; // Artificial decode delay    

        // Setting up output according to the OPCODE Input ------------
        
        // Defaults establishing
        ALUOP       = 3'b000;
        WRITEENABLE = 1'b0;
        IMM_SEL     = 1'b0;
        NEG_SEL     = 1'b0;
        JUMP        = 1'b0;
        BRANCH_EQ   = 1'b0;
        BRANCH_NEQ  = 1'b0;
        SHIFT_SEL   = 2'b00;
        MEM_READ    = 1'b0;
        MEM_WRITE   = 1'b0;
        MEM_TO_REG  = 1'b0;
        MEM_ADDR_SEL= 1'b0;

        // Used case base setup
        case (OPCODE)
            OP_LOADI: begin ALUOP = 3'b000; WRITEENABLE = 1'b1; IMM_SEL = 1'b1; end
            OP_MOV:   begin ALUOP = 3'b000; WRITEENABLE = 1'b1; end
            OP_ADD:   begin ALUOP = 3'b001; WRITEENABLE = 1'b1; end
            OP_SUB:   begin ALUOP = 3'b001; WRITEENABLE = 1'b1; NEG_SEL = 1'b1; end
            OP_AND:   begin ALUOP = 3'b010; WRITEENABLE = 1'b1; end
            OP_OR:    begin ALUOP = 3'b011; WRITEENABLE = 1'b1; end
            OP_J:     begin JUMP  = 1'b1; end
            OP_BEQ:   begin ALUOP = 3'b001; NEG_SEL = 1'b1; BRANCH_EQ = 1'b1; end
            
            OP_MULT:  begin ALUOP = 3'b100; WRITEENABLE = 1'b1; end
            OP_SLL:   begin ALUOP = 3'b101; WRITEENABLE = 1'b1; IMM_SEL = 1'b1; SHIFT_SEL = 2'b00; end
            OP_SRL:   begin ALUOP = 3'b101; WRITEENABLE = 1'b1; IMM_SEL = 1'b1; SHIFT_SEL = 2'b01; end
            OP_SRA:   begin ALUOP = 3'b101; WRITEENABLE = 1'b1; IMM_SEL = 1'b1; SHIFT_SEL = 2'b10; end
            OP_ROR:   begin ALUOP = 3'b101; WRITEENABLE = 1'b1; IMM_SEL = 1'b1; SHIFT_SEL = 2'b11; end
            OP_BNE:   begin ALUOP = 3'b001; NEG_SEL = 1'b1; BRANCH_NEQ = 1'b1; end

            // Memory Access Logic
            OP_LWD:   begin WRITEENABLE = 1'b1; MEM_READ = 1'b1; MEM_TO_REG = 1'b1; MEM_ADDR_SEL = 1'b0; end
            OP_LWI:   begin WRITEENABLE = 1'b1; MEM_READ = 1'b1; MEM_TO_REG = 1'b1; MEM_ADDR_SEL = 1'b1; end
            OP_SWD:   begin MEM_WRITE = 1'b1; MEM_ADDR_SEL = 1'b0; end
            OP_SWI:   begin MEM_WRITE = 1'b1; MEM_ADDR_SEL = 1'b1; end
        endcase        
    end
endmodule

/* ==================================================================
Unit: twos_comp
Description: provide 2's complement for an INPUT
Unit's Delay: 1
*/
module twos_comp (input wire [7:0] DATA, output reg [7:0] RESULT);
    always @(DATA) begin #1 RESULT = ~DATA + 8'b00000001; end
endmodule


/* ==================================================================
Unit: pc_adder
Description: register which points to the next instruction.
Initially 0 and resets to 0 at RESET signal
Unit's Delay: 1 delat for write to PC register
*/
module pc_adder (input wire [31:0] PC_IN, output reg [31:0] PC_NEXT);
    always @(PC_IN) begin #1 PC_NEXT = PC_IN + 32'd4; end
endmodule


/* =================================================================
Unit: bj_adder
Description: branch or jump target adder
Computes target relative to PC_NEXT
Unit's Delay: #2 latency
*/
module bj_adder (input wire [31:0] PC_NEXT, input wire [31:0] OFFSET, output reg [31:0] TARGET);
    always @(PC_NEXT or OFFSET) begin #2 TARGET = PC_NEXT + OFFSET; end
endmodule



// ------------------------------------------------------------
// Unit: Top-Level CPU Module
// module cpu(PC, INSTRUCTION, CLK, RESET)
//
module cpu (
    output reg  [31:0] PC,          
    input  wire [31:0] INSTRUCTION, 
    input  wire CLK,
    input  wire RESET,
    
    // Data Memory Ports
    output wire        READ,
    output wire        WRITE,
    output wire [7:0]  ADDRESS,
    output wire [7:0]  WRITEDATA,
    input  wire [7:0]  READDATA,
    input  wire        BUSYWAIT
);
    
    // Slicing of Instruction
    wire [7:0] opcode = INSTRUCTION[31:24];
    wire [2:0] rd     = INSTRUCTION[18:16]; 
    wire [7:0] imm    = INSTRUCTION[7:0];

    // Extracting the offset in RD,IMM field
    // bits 23:16
    wire [7:0] offset_imm = INSTRUCTION[23:16];


    // Wires for register reading
    reg [2:0] read_reg1_addr;
    reg [2:0] read_reg2_addr;
    wire [2:0] aluop;

    // Control Unit Signals
    wire writeenable, imm_sel, neg_sel, jump, branch_eq, branch_neq;
    wire [1:0] shift_sel;
    wire mem_read, mem_write, mem_to_reg, mem_addr_sel;

    // Connections in Datapath
    wire [7:0] regout1, regout2, twos_result, alu_result, reg_in_data;

    // Branch and Jump calculations adder related
    wire [31:0] pc_next, bj_target;
    wire zero; 

    // Data memory unit related
    reg [7:0] mux_sub_out, alu_data2;
    wire pc_src;
    wire [31:0] extended_offset;
    
    // Sign extend 8 bit offset
    // Then shift left by 2 = multiply by 4 (instruction size)
    assign extended_offset = {{22{offset_imm[7]}}, offset_imm, 2'b00};


    // ----------------------------------------------------------
    // Adresses of two Read registers parsing according to instruction type
    // done based on OPCODE

    always @(*) begin

        // For MOV instructions
        // localparam OP_MOV   = 8'b00000001;
        if (opcode == 8'b00000001) begin
            read_reg1_addr = INSTRUCTION[2:0];
            read_reg2_addr = 3'b000;                // for fault tollerence rather than keeping floating

        // Other instructions - ADD, SUB, AND, OR 
        end else begin
            read_reg1_addr = INSTRUCTION[10:8]; // Captures RT
            read_reg2_addr = INSTRUCTION[2:0];  // Captures RS
        end
    end

    // Creating instants of each submodule

    // control unit
    control_unit cu (
        .OPCODE (opcode),
        .ALUOP (aluop),
        .WRITEENABLE (writeenable),
        .IMM_SEL (imm_sel),
        .NEG_SEL (neg_sel),
        .JUMP (jump),
        .BRANCH_EQ (branch_eq),
        .BRANCH_NEQ (branch_neq),
        .SHIFT_SEL (shift_sel),
        .MEM_READ(mem_read),
        .MEM_WRITE(mem_write),
        .MEM_TO_REG(mem_to_reg),
        .MEM_ADDR_SEL(mem_addr_sel)
    );

    // Data Memory Integration Routing
    assign READ = mem_read;
    assign WRITE = mem_write;
    assign ADDRESS = mem_addr_sel ? imm : regout2; // MUX for memory address
    assign WRITEDATA = regout1;                    // RT: source for store data
    
    assign reg_in_data = mem_to_reg ? READDATA : alu_result; // MUX for RegFile input data

    // When memory asserts BUSYWAIT:
    // ------------   Stall register file writing 
    wire gated_writeenable = writeenable & ~BUSYWAIT;

    // register unit
    reg_file rf (
        .IN (reg_in_data),  // Driven by MEM_TO_REG mux
        .OUT1 (regout1),
        .OUT2 (regout2),
        .INADDRESS (rd),
        .OUT1ADDRESS (read_reg1_addr), 
        .OUT2ADDRESS (read_reg2_addr), 
        .WRITE (gated_writeenable),
        .CLK (CLK),
        .RESET (RESET)
    );

    // twos complement unit
    twos_comp tc (.DATA (regout2), .RESULT (twos_result));

    //pc adder
    pc_adder pca (.PC_IN (PC), .PC_NEXT (pc_next));

    // branch/jump target adder
    bj_adder bja (.PC_NEXT (pc_next), .OFFSET (extended_offset), .TARGET (bj_target));
    
    // ALU unit
    alu main_alu (
        .DATA1 (regout1),
        .DATA2 (alu_data2),
        .RESULT (alu_result),
        .ZERO (zero),       
        .SELECT(aluop),
        .SHIFT_SEL(shift_sel)
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
        if (neg_sel) mux_sub_out = twos_result;
        else mux_sub_out = regout2;
    end

    // MUX 2: Immediate Selection
    always @(*) begin
        if (imm_sel) alu_data2 = imm;
        else alu_data2 = mux_sub_out;
    end

    // PC multiplexer Logic
    assign pc_src = jump | (branch_eq & zero) | (branch_neq & ~zero);

    // PC Update Logic
    // BUSYWAIT halting is equipped

    always @(posedge CLK) begin
        if (RESET)
            #1 PC <= 32'b0;

        // The next instruction should not be fetched until BUSYWAIT is deasserted
        else if (!BUSYWAIT) begin
            if (pc_src)
                #1 PC <= bj_target;
            else
                #1 PC <= pc_next;
        end
    end
endmodule