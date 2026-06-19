// Setting up the time step
`timescale 1ns/100ps

/*
Module: reg_file
Description: 8x8 Register File:
             1 synchronous write port
             2 asynchronous read ports
*/

module reg_file (

    //input output port setup
    input  wire [7:0] IN,
    output reg  [7:0] OUT1,
    output reg  [7:0] OUT2,
    input  wire [2:0] INADDRESS,
    input  wire [2:0] OUT1ADDRESS,
    input  wire [2:0] OUT2ADDRESS,
    input  wire WRITE,
    input  wire CLK,
    input  wire RESET
);


    // Register Storage Declaration
    reg [7:0] registers [0:7];
    
    // Iterator as a helper for reset loops
    integer i;


    // Write and Reset triggeres on the positive edge of the clock
    always @(posedge CLK) 
    begin
        if (RESET) begin  // if RESET is 1
        
            #1;  // Used delay for realistic latency
            for (i = 0; i < 8; i = i + 1)
            begin
                // Synchronous reset: clear all registers to 0
                registers[i] <= 8'b00000000;
            end
        end 
        
        else if (WRITE) begin
            // load IN data to specified INADDRESS with a #1 delay
            // Synchronus writing is used
            #1 registers[INADDRESS] <= IN;
            // Used delay for realistic latency
        end
    end



    // Read Logic for Outputs
    // Asynchronus
    // Updates whenever the address or target register data changes
    always @(*)
    begin
    // Artificial delay of 2 time units for realistic reading latency
    #2;
    OUT1 = registers[OUT1ADDRESS];
    OUT2 = registers[OUT2ADDRESS];
    end

endmodule