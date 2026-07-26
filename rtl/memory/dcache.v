/*
Module  : Data Cache
Completed from skeleton provided by Isuru Nawinne, Kisaru Liyanage

Description:

The data cache will act as an Direct mapped Write back
intermediary unit between CPU and data memory

Specs: 

    Total Cache size   : 32 B (8 blocks x 4 bytes)
    Block size         : 4 bytes  (match to the data memory 4 B block )


CPU requested Memory Address splitting:

    ADDRESS[7:5] -> TAG    - 3 bits
    ADDRESS[4:2] -> INDEX  - 3 bits : to select a cache line (1-8)
    ADDRESS[1:0] -> OFFSET - 2 bits : to select byte block in the cache line (1-4)


Main Memory accessing address:

    Lab 6 data_memory module expects 6-bit ADDRESS
    This is provided by concatanating {TAG,INDEX}, which is then sent to the data memory.

Timing (using timescale 1ns/100ps):

    - Indexing                  : #1
        - stored block/tag/valid/dirty extraction: #1

    - Tag comparison            : #0.9
        - hit/miss decision, starts right after indexing is performed   

    - Word selection            : #1
        - from the block based on OFFSET
        - Begins immediately after indexing completes so it overlaps with tag comparison

    ** Hit is known #1.9 after ADDRESS change

*/

// Time unit setup as required
`timescale 1ns/100ps

module dcache (
    input  wire         clock,
    input  wire         reset,

    // I/O related to CPU - Cache interface
    input  wire         read,
    input  wire         write,
    input  wire [7:0]   address,
    input  wire [7:0]   writedata,
    output wire [7:0]   readdata,
    output reg          busywait,

    // I/O related to Cache - Main memory interface
    output reg          mem_read,
    output reg          mem_write,
    output reg  [5:0]   mem_address,
    output reg  [31:0]  mem_writedata,
    input  wire [31:0]  mem_readdata,
    input  wire         mem_busywait
);

    // ----------------------------------------------------------------

    // Number of cache lines
    localparam NUM_LINES = 8;

    // Segmenting CPU side address

    wire [2:0] tag    = address[7:5];
    wire [2:0] index  = address[4:2];
    wire [1:0] offset = address[1:0];

    // access signal for debug easiness
    wire access = read | write;

    // ----------------------------------------------------------------
    // Cache data storing registers

    reg [31:0] cache_data  [0:NUM_LINES-1];
    reg [2:0]  cache_tag   [0:NUM_LINES-1];
    reg        cache_valid [0:NUM_LINES-1];
    reg        cache_dirty [0:NUM_LINES-1];


    // -------------------------------------------------------------------
    // Cache Line Reset operation
    // to be used when needed

    integer k;

    always @(posedge reset) begin
        if (reset) begin
            for (k = 0; k < NUM_LINES; k = k + 1) begin
                cache_valid[k] = 1'b0;
                cache_dirty[k] = 1'b0;
                cache_tag[k]   = 3'b000;
                cache_data[k]  = 32'b0;
            end
        end
    end

    // ###################################################################################################

    // Indexing, Tag comparison and Word selection
    // Asynchronous - combinational operations

    // ======================================================================================

    // Indexing

    // latency: #1

    reg [31:0] indexed_data;
    reg [2:0]  indexed_tag;
    reg        indexed_valid;
    reg        indexed_dirty;

    always @(*) begin
        #1;                 // Indexing latency
        indexed_data  = cache_data[index];
        indexed_tag   = cache_tag[index];
        indexed_valid = cache_valid[index];
        indexed_dirty = cache_dirty[index];
    end

    // ======================================================================================

    // Tag comparison
    // latency: #0.9

    reg hit;
    always @(*) begin
        #0.9;

        // Hit detection -------------------------------------------------------
    
        hit = indexed_valid && (indexed_tag == tag);
    end

    // Note: hit status is known after #1.9 from adress change


    // ======================================================================================
    // Word selection 
    // Performed based on OFFSET, from the indexed block

    // latency: #1 

    reg [7:0] word_selected;
    always @(*) begin
        #1;
        case (offset)
            2'b00: word_selected = indexed_data[7:0];
            2'b01: word_selected = indexed_data[15:8];
            2'b10: word_selected = indexed_data[23:16];
            2'b11: word_selected = indexed_data[31:24];
        endcase
    end

    // Note: Since both tag comparrisson and word selection start as indexing finishes:
    //  operation get overlapped

    // Data sent to the CPU (asynchronous). The CPU only looks at this
    // while READ is asserted and BUSYWAIT is low, so it is safe to just
    // continuously drive it with the (combinationally selected) word.
    assign readdata = word_selected;



    // ############################################################################################################

    // FSM

    parameter IDLE      = 3'b000,
              WRITEBACK = 3'b001,   // writing dirty block on cache back to memory
              GAP       = 3'b010,   // 1 Cycle gap is present between writeback & fetch
              READFILL  = 3'b011;   // Fetch missing block to the cache from memory

    reg [2:0] state, next_state;

    // =========================================================================
    // NEXt State Logic 
    // Performs combinationally

    always @(*) begin
        case (state)
            IDLE:
                if (access && !hit) begin
                    if (indexed_dirty)
                        next_state = WRITEBACK;
                    else
                        next_state = READFILL;
                end
                else
                    next_state = IDLE;

            WRITEBACK:
                if (!mem_busywait)
                    next_state = GAP;
                else
                    next_state = WRITEBACK;

            GAP:
                next_state = READFILL;

            READFILL:
                if (!mem_busywait)
                    next_state = IDLE;
                else
                    next_state = READFILL;

            default:
                next_state = IDLE;
        endcase
    end

    // ===============================================================================
    // Output logic
    always @(*) begin
        
        // Initial default values
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        mem_address   = 6'dx;
        mem_writedata = 32'dx;
        busywait      = 1'b0;

        case (state)
            IDLE: begin
                if (access && !hit) begin
                    // Miss detected: -----------------------------------------------------------------------
                    // Appropriate memory control signal is asserted immediately (in asynchronously)
                    // and CPU is stalled.
                    busywait = 1'b1;

                    // ------------------------------------------------------------------------------
                    // Writing the dirty block on cache, back to memory updating
                    // location: {old tag, same index}

                    if (indexed_dirty) begin                       

                        mem_write     = 1'b1;
                        mem_address   = {indexed_tag, index};
                        mem_writedata = indexed_data;
                    end
                    else begin
                        // Fetching the new block needed by Cache
                        mem_read    = 1'b1;
                        mem_address = {tag, index};
                    end
                end
                else begin
                    // One of two scenes:
                    // idle - no access
                    // hit - no stall
                    busywait = 1'b0;
                end
            end

            WRITEBACK: begin
                busywait      = 1'b1;
                mem_write     = 1'b1;
                mem_address   = {indexed_tag, index};
                mem_writedata = indexed_data;
            end

            GAP: begin
                // // 1 cycle gap: ---------------------------------------------------------------------------
                // READ is asserted here so the fetch begins on the edge leaving this state
                // Nevertheless, no transfer takes place during this cycle. 
                busywait    = 1'b1;
                mem_read    = 1'b1;
                mem_address = {tag, index};
            end

            READFILL: begin
                busywait    = 1'b1;
                mem_read    = 1'b1;
                mem_address = {tag, index};
            end
        endcase
    end

    // =================================================================================================
    // State transition and cache array updates
    // Sequential and Synchronous
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;

            // -------------------------------------------------------
            // Write-hit: 
            // Commit the CPU's write into the cache line at the beginning of the next clock cycle (write-back policy).
            // Also handles the write-miss case, where after the missing block has been fetched
            // and the FSM has returned to IDLE with `hit' now set,
            // on the next clock edge the same condition fires to do the deferred CPU write.
            // -------------------------------------------------------

            if (state == IDLE && write && hit) begin
                case (offset)
                    2'b00: cache_data[index][7:0]   <= #1 writedata;
                    2'b01: cache_data[index][15:8]  <= #1 writedata;
                    2'b10: cache_data[index][23:16] <= #1 writedata;
                    2'b11: cache_data[index][31:24] <= #1 writedata;
                endcase
                cache_dirty[index] <= #1 1'b1;
                cache_valid[index] <= #1 1'b1;
            end

            // -------------------------------------------------------
            // Fetched block is recieved:
            // Write into indexed cache line, update tag, valid, dirty. Artificial latency #1.
            // Then the asynchronous circuitry above finishes the original read or write access once `hit' goes high again
            // no extra state needed for reads
            // deferred writes are handled by the write-hit block above on the cycle after that
            // -------------------------------------------------------
            if (state == READFILL && !mem_busywait) begin
                cache_data[index]  <= #1 mem_readdata;
                cache_tag[index]   <= #1 tag;
                cache_valid[index] <= #1 1'b1;
                cache_dirty[index] <= #1 1'b0;
            end
        end
    end

endmodule
