// Setting up the time step
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


// Top level module alu setup..........

module alu (

    // module definition as given according to the template interface for ALU:
    input  wire [7:0] DATA1,
    input  wire [7:0] DATA2,
    output reg  [7:0] RESULT,
    input  wire [2:0] SELECT
);

    // Wires to hold the output results from each functional module unit
    wire [7:0] forward_res, add_res, and_res, or_res;

    // Instantion of functional units implemented above, as required
    forward_unit fu  (.DATA2(DATA2), .RESULT(forward_res));
    add_unit     au  (.DATA1(DATA1), .DATA2(DATA2), .RESULT(add_res));
    and_unit     andu(.DATA1(DATA1), .DATA2(DATA2), .RESULT(and_res));
    or_unit      ou  (.DATA1(DATA1), .DATA2(DATA2), .RESULT(or_res));


    // MUX implementation for SELECT lines
    always @(*)
    begin
        // By using a case structure
        case (SELECT)
            // FORWARD
            3'b000:  RESULT = forward_res;

            // ADD
            3'b001:  RESULT = add_res;

            // AND
            3'b010:  RESULT = and_res;

            // OR
            3'b011:  RESULT = or_res;
            
            // For Reserved combinations 1XX (tempory)
            default: RESULT = 8'b00000000;

        endcase
    end

endmodule