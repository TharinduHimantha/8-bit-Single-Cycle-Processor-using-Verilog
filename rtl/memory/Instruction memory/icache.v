/*
Module  : Instruction Cache
Author  : (built for Lab 7, following the same structure as dcache.v)

Description:
Direct-mapped, READ-ONLY instruction cache between the CPU (PC) and
the Lab 7 instruction memory based on 16-byte blocks.

Since the CPU does not write into instruction memory: 
+ no dirty bit or write-back policy
+ evicted blocks are simply deallocated,
+ new fetches if a future read requirement occurs
    :only be at clean misses


Module Specification:

cache size    = 128 Bytes => 8 blocks x 16 bytes
block size    = 16 Bytes  => 4 instruction words that are 4 bytes each)
mapping       = directly mapped

instruction memory size = 256 words => 1024 Bytes
        : accessed with a 10 bit word address => PC[9:0]
        : PC[1:0] is always zero 
        : double aligned instruction words

CPU adress splitting:

ADDRESS[9:7] +> TAG     - 3 bits
ADDRESS[6:4] +> INDEX   - 3 bits  -  selects one of 8 cache lines
ADDRESS[3:2] +> WOFFSET - 2 bits  -  selects one of 4 words in a 16-byte block(in a cache line)
ADDRESS[1:0] +> always 00

The memory side address:
+ formed by concatenating {TAG, INDEX} (ADDRESS[9:4])
    yields a 6 bit block address

Timing: 

timescale 1ns/100ps

Delays: 
+ Indexing : # 1
    retrieve stored tag and valid for the accessed line

+ Tag comparison : # 0.9 
    hit/miss decision
    starts right after indexing

+  hit status resolving : #1.9 after ADDRESS was changed

+ Word select: #1 
    use WOFFSET
    choose which of the 4 words in the block to output
    overlaps with tag comparison and starts just after indexing

---------------------
On a miss, mem_read is asserted immediately - asynchronously
    BUSYWAIT is held until the 16-byte block has been fetched
    16 5 = 80 cycle
    
    written into the cache with #1 latency
    Hence 81 cycle miss penalty
*/

`timescale 1ns/100ps

module icache (
    input  wire         clock,
    input  wire         reset,

    // CPU-facing interface
    input  wire [9:0]   address,       // word aligned PC[9:0] 
    output wire [31:0]  instruction,   // to send instruction word to CPU
    output reg          busywait,

    // Instruction memory interface
    output reg          mem_read,
    output reg  [5:0]   mem_address,
    input  wire [127:0] mem_readinst,
    input  wire         mem_busywait
);

    // Cache line count
    localparam NUM_LINES = 8;

    wire [2:0] tag     = address[9:7];
    wire [2:0] index   = address[6:4];
    wire [1:0] woffset = address[3:2];


    // Cache arrays
    // to store necessary components in each cache line as needed
    reg [127:0] cache_data  [0:NUM_LINES-1];
    reg [2:0]   cache_tag   [0:NUM_LINES-1];
    reg         cache_valid [0:NUM_LINES-1];

    integer k;
    always @(posedge reset) begin
        if (reset) begin
            for (k = 0; k < NUM_LINES; k = k + 1) begin
                cache_valid[k] = 1'b0;
                cache_tag[k]   = 3'b000;
                cache_data[k]  = 128'b0;
            end
        end
    end

    // ====================================================================================
    // Indexing
    // 
    // Reading curret indexed lines content
    // Artificial latency: #1
    // ====================================================================================
    
    reg [127:0] indexed_data;
    reg [2:0]   indexed_tag;
    reg         indexed_valid;
    always @(*) begin
        #1;
        indexed_data  = cache_data[index];
        indexed_tag   = cache_tag[index];
        indexed_valid = cache_valid[index];
    end

    // ====================================================================================
    // Tag Comparrisson
    // 
    // Happens afterwards indexing
    // Artificial latency: #0.9
    // ====================================================================================

    reg hit;
    always @(*) begin
        #0.9;

        // Hit resolving
        // hit is known after #1.9 from address changes
        hit = indexed_valid && (indexed_tag == tag);
    end

    // ====================================================================================
    // Word Selection
    // 
    // Happens afterwards indexing finishes
    // Overlap with tag comparison
    // Artificial latency: #1
    // ====================================================================================

    // block based on WOFFSET.
    reg [31:0] word_selected;
    always @(*) begin
        #1;
        case (woffset)
            2'b00: word_selected = indexed_data[31:0];
            2'b01: word_selected = indexed_data[63:32];
            2'b10: word_selected = indexed_data[95:64];
            2'b11: word_selected = indexed_data[127:96];
        endcase
    end

    // ====================================================================================
    // Instruction Sending to CPU
    //
    // Send Instruction word to CPU 
    // asynchronous  and driven continuously
    // CPU only considers if only buywait is low
    // ====================================================================================

    assign instruction = word_selected;

    // ====================================================================================
    // FSM
    //
    // Deals with Instruction fetching between cache and memory
    // only Two states are utilized since cache is read only
    // no write backs 
    // 
    // States: IDLE, READFILL
    // ====================================================================================

    localparam IDLE     = 1'b0,
               READFILL = 1'b1;

    reg state, next_state;

    // State transitions operations (combinational)
    always @(*) begin
        case (state)
            IDLE:      next_state = (!hit) ? READFILL : IDLE;
            READFILL:  next_state = (!mem_busywait) ? IDLE : READFILL;
            default:   next_state = IDLE;
        endcase
    end

    // combinational output logic
    always @(*) begin
        mem_read    = 1'b0;
        mem_address = 6'dx;
        busywait    = 1'b0;

        case (state)
            IDLE: begin
                if (!hit) begin
                    // Miss detected => assert READ memory signal
                    // => asynchronous CPU stalling
                    busywait    = 1'b1;
                    mem_read    = 1'b1;
                    mem_address = {tag, index};
                end
                else begin
                    busywait = 1'b0; // if hit +> no stall
                end
            end

            READFILL: begin
                busywait    = 1'b1;
                mem_read    = 1'b1;
                mem_address = {tag, index}; //memory adress block to be fetched
                // build through concatanating needed {tag, index} part
            end
        endcase
    end

    // ----------------------------------------------------
    // Sequential componets
    // + State transitionning
    // + Updating cache array
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;

            // Fetched block arrives
            // Write into indexed cache line, update tag/valid
            // Artificial latency #1
            
            //The original fetch is then completed by the async circuitry above once `hit` goes high again
            // no extra state is required

            if (state == READFILL && !mem_busywait) begin
                cache_data[index]  <= #1 mem_readinst;
                cache_tag[index]   <= #1 tag;
                cache_valid[index] <= #1 1'b1;
            end
        end
    end

endmodule
