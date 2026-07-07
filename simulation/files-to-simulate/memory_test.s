loadi 1 0x10  // R1 = 0x10 (used as memory address for direct addressing later)
loadi 2 0x55  // R2 = 0x55 (Test data #1)
loadi 3 0xAA  // R3 = 0xAA (Test data #2)
swi 2 0x2A    // Store value of R2 (0x55) into memory address 0x2A
lwi 4 0x2A    // Load value from memory address 0x2A into R4. (R4 should become 0x55)
swd 3 1       // Store value of R3 (0xAA) into memory address given by R1 (0x10)
lwd 5 1       // Load value from memory address given by R1 (0x10) into R5. (R5 should become 0xAA)
add 6 4 5     // R6 = R4 + R5 (0x55 + 0xAA = 0xFF). Proves RegFile handles post-load operations normally