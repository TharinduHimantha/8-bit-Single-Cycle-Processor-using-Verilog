

// loadi 1 0xB6
// loadi 2 0x6D
// and 3 1 2
// or 4 1 2
// add 5 4 1
// mov 6 3
// sub 4 5 2

//loadi 5 0x01    // Load 1 (0x01) into Register 5
//j 0x02          // Jump forward 2 instructions. Target = PC_NEXT (8) + (2 * 4) = 16.
//loadi 5 0xFF    // This instruction should be SKIPPED.
//loadi 6 0xFF    // This instruction should also be SKIPPED.
//mov 7 5         // Execution lands here. Copy R5 into R7

// Setup initial values
loadi 1 0x8D    // r1 = 141 (binary: 10001101)
loadi 2 0x02    // r2 = 2   (binary: 00000010)

// 1. Multiply
mult 3 1 2      // r3 = r1 * r2   result = 0x1A

// 2. Logical Shift Left
sll 4 1 0x02    // r4 = r1 << 2	   result = 0x34

// 3. Logical Shift Right
srl 5 1 0x02    // r5 = r1 >> 2 (Logical)    result = 0x23

// 4. Arithmetic Shift Right
sra 6 1 0x02    // r6 = r1 >> 2 (Arithmetic)   result = 0xE3

// 5. Rotate Right
ror 7 1 0x02    // r7 = r1 rotated right by 2   result = 0x63

// 6. Branch Not Equal
bne 0x02 1 2    // r1 (0x8D) != r2 (0x02), so branch forward by 2 instructions
loadi 1 0x00    // (SKIPPED) 
loadi 2 0x00    // (SKIPPED)

// Target of the branch
loadi 0 0xFF    // r0 = 255 (binary: 11111111)