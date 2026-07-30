
// ***************************************************
// Block 0: Addresses 0x00 to 0x0C (PC: 0, 4, 8, 12)
// I-Cache: PC 0x00 causes I-Cache MISS (Fetches instructions 0x00-0x0F)
// D-Cache: Initial stores cause D-Cache Write Misses / Write Hits


// Setup & Initialization
// ----------------------------------------------------

// R2 = F(0) = 0
loadi 2 0x00                            // PC 0x00 | ICache: MISS (Loading 0 block into Cache)

// R3 = F(1) = 1
loadi 3 0x01                            // PC 0x04 | ICache: HIT

// R0 = loop counter (i = 0)
loadi 0 0x00                            // PC 0x08 | ICache: HIT

// R1 = target N (4 iterations)
loadi 1 0x04                            // PC 0x0C | ICache: HIT



// =**********************************************************
// Block 1: Addresses 0x10 to 0x1C (PC: 16, 20, 24, 28)
// I-Cache: PC 0x10 causes ICache MISS (Fetches instructions 0x10-0x1F)

//

// R5 = 1 (increment constant)
loadi 5 0x01                                // PC 0x10 | ICache: MISS 
                                            // Loads Block = 1 into Cache)

// Store initial values to memory

swi 2 0x00                                  // PC 0x14 | ICache: HIT
                                            // DataCache: WRITE MISS at address 0x00 => Fetches block, updates R2

swi 3 0x01                                  // PC 0x18 | ICache: HIT
                                            // DataCache: WRITE HIT at address 0x01 - Same 4-Byte block already in cache


// ----------------------------------------------------
// Loop Start (Target of Jump)
// ----------------------------------------------------

// Check if loop counter i == N

beq 0x14 0 1    // PC 0x1C | Cache: HIT





// ***********************************************
// Block 2: Addresses 0x20 to 0x2C (PC: 32, 36, 40, 44)
// I-Cache: PC 0x20 causes I-Cache MISS on 1st iteration (Fetches 0x20-0x2F)


// R4 = R3 + R2  (F_next = F_curr + F_prev)
add 4 3 2                                       // PC 0x20 | I-Cache: MISS in 1st iteration
                                                // I-Cache: HIT in subsequent iterations

// for the next iteration, term shifting
mov 2 3                                         // PC 0x24 | ICache: HIT
mov 3 4                                         // PC 0x28 | ICache: HIT

// Increment loop counter (i = i + 1)
add 0 0 5                                       // PC 0x2C | ICache: HIT





// **************************************
// Block 3: Addresses 0x30 onwards
// 

// Loop back
// Jump back 24 bytes (-0x18 = 0xE8) to repeat loop (PC 28)

j 0xE8                                          // PC 0x30 | I-Cache: MISS on 1st iteration (Fetches 0x30-0x3F)
                                                // Jumps back to PC 0x1C (`beq 0x14 0 1`)





// ============================================================================
// Loop Summary Across Iterations:
// - Iteration 1:
//     * Instruction fetches at 0x00, 0x10, 0x20, 0x30 cause 4 I-Cache MISSES.
//     * `swi 2 0x00` causes 1 D-Cache WRITE MISS (stall CPU to fetch block).
// - Iterations 2 to 7:
//     * ALL I-Cache fetches inside the loop (0x1C to 0x30) are 100% I-Cache HITS!
//     * Zero memory stalls during loop execution.
// ============================================================================