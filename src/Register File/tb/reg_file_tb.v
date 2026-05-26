// Setting up time unit
`timescale 1ns/100ps

module reg_file_tb;

    // Testbench Variables
    reg  [7:0] WRITEDATA;
    reg  [2:0] WRITEREG;
    reg  [2:0] READREG1;
    reg  [2:0] READREG2;
    reg  WRITEENABLE;
    reg  CLOCK;
    reg  RESET;  
    wire [7:0] REGOUT1;
    wire [7:0] REGOUT2;


    // Instantiating the uut: reg_file
    reg_file uut (
        .IN(WRITEDATA),
        .OUT1(REGOUT1),
        .OUT2(REGOUT2),
        .INADDRESS(WRITEREG),
        .OUT1ADDRESS(READREG1),
        .OUT2ADDRESS(READREG2),
        .WRITE(WRITENABLE),
        .CLK(CLOCK),
        .RESET(RESET)
    );


    // Clock Signal
    // Period of 4 time units: 2 high, 2 low
    always begin
        #2 CLOCK = ~CLOCK;
    end


    // Test Sequence ....

    initial begin
        //Waveform file creation
        $dumpfile("group13_lab2_part2_waves.vcd");
        $dumpvars(0, reg_file_tb);

        // Initial Setup of input Output ports
        CLOCK = 0;
        WRITENABLE = 0;
        WRITEDATA = 8'h00;
        WRITEREG = 3'b000;
        READREG1 = 3'b000;
        READREG2 = 3'b000;

        // Reset is activated
        RESET = 1;
        #5; 
        RESET = 0; 

        // For inputs hex values were used siince 8 bit operands needs to be given
        
        // 2. to Register 2, Write 0x0A = 10
        #5; 
        WRITENABLE = 1;
        WRITEREG = 3'd2;
        WRITEDATA = 8'h0A;
        
        // 3. to Register 5, Write 0x55 = 85
        #5; 
        WRITEREG = 3'd5;
        WRITEDATA = 8'h55;
        
        // Disable writing
        #5; 
        WRITENABLE = 0;

        // 4. Asynchronous Read Test 
        // Read Register 2 -> OUT1
        // Read Register 5 -> OUT2
        #5;
        READREG1 = 3'd2;
        READREG2 = 3'd5;

        // 5. Read a zeroed register
        // Read Register 7 -> OUT1
        #5;
        READREG1 = 3'd7; 

        // 6. Test Synchronous Reset over written data
        #5;
        RESET = 1;

        // Values must drop to 0x00 at clock edge
        READREG1 = 3'd2; 
        READREG2 = 3'd5;
        
        #5;
        RESET = 0;

        // Terminate simulation
        $finish;
    end

endmodule