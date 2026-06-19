`timescale 1ns/100ps

// Functional Units Setup..............


/* ==================================================================
Function: FORWARD
Description: Forwards DATA2 into RESULT
Supported Instructions: loadi, move
SELECT Input: 000
Unit's Delay: #1
*/

module forward_unit (
    // required input output setup
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT
);
    // Get triggered whenever DATA2 changes
    always @(DATA2)
    begin
        #1 RESULT = DATA2; 
        // Artificial delay of 1 time unit
    end
endmodule

/*====================================================================
Function: ADD
Description: Adds DATA1 and DATA2.
Supported Instructions: add, sub
SELECT Input: 001
Unit's Delay: #2
*/

module add_unit (
    // required input output setup
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT
);
    // Execute whenever operands DATA1 or DATA2 get change
    always @(DATA1 or DATA2)
    begin
        #2 RESULT = DATA1 + DATA2;
        // Artificial delay of 2 time units as required
    end
endmodule


/* =====================================================================
Function: AND
Description: Performs bitwise AND on DATA1 and DATA2.
Supported Instructions: and
SELECT Input: 010
Unit's Delay: #1
*/

module and_unit (
    // required input output setup
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT
);
    // Execute whenever operands DATA1 or DATA2 get change
    always @(DATA1 or DATA2)
    begin
        #1 RESULT = DATA1 & DATA2;
        // Artificial delay of 1 time unit
    end
endmodule

/* ====================================================================
Function: OR
Description: Performs bitwise OR on DATA1 and DATA2
Supported Instructions: or
SELECT Input: 011
Unit's Delay: #1
*/

module or_unit (
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT
);
    // Execute whenever operands DATA1 or DATA2 get change
    always @(DATA1 or DATA2)
    begin
        #1 RESULT = DATA1 | DATA2;
        // Artificial delay of 1 time unit
    end
endmodule


// ==================================================================
// New Unit: Multiplier (Shift & Add Array)
// Shifting units not used 
// using wire by wire concatanate instaed of shifting
// Delay: #2
// ==================================================================
module mult_unit (
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT
);
    wire [7:0] p0, p1, p2, p3, p4, p5, p6, p7;
    
    assign p0 = DATA2[0] ? DATA1 : 8'd0;
    assign p1 = DATA2[1] ? {DATA1[6:0], 1'b0} : 8'd0;
    assign p2 = DATA2[2] ? {DATA1[5:0], 2'b00} : 8'd0;
    assign p3 = DATA2[3] ? {DATA1[4:0], 3'b000} : 8'd0;
    assign p4 = DATA2[4] ? {DATA1[3:0], 4'b0000} : 8'd0;
    assign p5 = DATA2[5] ? {DATA1[2:0], 5'b00000} : 8'd0;
    assign p6 = DATA2[6] ? {DATA1[1:0], 6'b000000} : 8'd0;
    assign p7 = DATA2[7] ? {DATA1[0], 7'b0000000} : 8'd0;

    always @(DATA1 or DATA2) begin
        #2 RESULT = p0 + p1 + p2 + p3 + p4 + p5 + p6 + p7;
    end
endmodule

// ==================================================================
// New Unit: Universal Shifter (SLL, SRL, SRA, ROR)
// Delay: #1
// ==================================================================
module shift_unit (
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    input  wire [1:0] SHIFT_SEL,
    output reg  [7:0] RESULT
);
    wire [2:0] shamt = DATA2[2:0];

    // Left Shift
    wire [7:0] sl1 = shamt[0] ? {DATA1[6:0], 1'b0} : DATA1;
    wire [7:0] sl2 = shamt[1] ? {sl1[5:0], 2'b00} : sl1;
    wire [7:0] sl3 = shamt[2] ? {sl2[3:0], 4'b0000} : sl2;

    // Logical Right Shift
    wire [7:0] sr1 = shamt[0] ? {1'b0, DATA1[7:1]} : DATA1;
    wire [7:0] sr2 = shamt[1] ? {2'b00, sr1[7:2]} : sr1;
    wire [7:0] sr3 = shamt[2] ? {4'b0000, sr2[7:4]} : sr2;

    // Arithmetic Right Shift
    wire [7:0] sa1 = shamt[0] ? {DATA1[7], DATA1[7:1]} : DATA1;
    wire [7:0] sa2 = shamt[1] ? {{2{sa1[7]}}, sa1[7:2]} : sa1;
    wire [7:0] sa3 = shamt[2] ? {{4{sa2[7]}}, sa2[7:4]} : sa2;

    // Rotate Right
    wire [7:0] ro1 = shamt[0] ? {DATA1[0], DATA1[7:1]} : DATA1;
    wire [7:0] ro2 = shamt[1] ? {ro1[1:0], ro1[7:2]} : ro1;
    wire [7:0] ro3 = shamt[2] ? {ro2[3:0], ro2[7:4]} : ro2;

    always @(*) begin
        #1; 
        case (SHIFT_SEL)
            2'b00: RESULT = sl3; // SLL
            2'b01: RESULT = sr3; // SRL
            2'b10: RESULT = sa3; // SRA
            2'b11: RESULT = ro3; // ROR
        endcase
    end
endmodule

// Top level module alu setup..........
module alu (
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT,
    output reg        ZERO,
    input  wire [2:0] SELECT,
    input  wire [1:0] SHIFT_SEL
);  
    // Wires to hold the output results from each functional module unit
    wire [7:0] forward_res, add_res, and_res, or_res, mult_res, shift_res;

    // Instantion of functional units implemented above, as required
    forward_unit fu  (.DATA2(DATA2), .RESULT(forward_res));
    add_unit     au  (.DATA1(DATA1), .DATA2(DATA2), .RESULT(add_res));
    and_unit     andu(.DATA1(DATA1), .DATA2(DATA2), .RESULT(and_res));
    or_unit      ou  (.DATA1(DATA1), .DATA2(DATA2), .RESULT(or_res));
    mult_unit    mu  (.DATA1(DATA1), .DATA2(DATA2), .RESULT(mult_res));
    shift_unit   su  (.DATA1(DATA1), .DATA2(DATA2), .SHIFT_SEL(SHIFT_SEL), .RESULT(shift_res));

    // MUX implementation for SELECT lines
    always @(*) begin

         // By using a case structure
        case (SELECT)
            3'b000:  RESULT = forward_res;
            3'b001:  RESULT = add_res;
            3'b010:  RESULT = and_res;
            3'b011:  RESULT = or_res;
            3'b100:  RESULT = mult_res;
            3'b101:  RESULT = shift_res;
            default: RESULT = 8'b00000000;
        endcase
        
        // Update the ZERO flag dynamically 
        if (RESULT == 8'b00000000)
            ZERO = 1'b1;
        else
            ZERO = 1'b0;
    end
endmodule