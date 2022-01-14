SLURM16 SoC - SLightly Useful RISC Machine, 16 bit, system-on-chip
==================================================================

Video console system-on-chip made for the iCE40 UP5K FPGA.

64k x 16bit memory, shared between CPU and gfx / sound / flash DMA. Split into 4 banks so CPU, GPU, sound core, and flash dma can access the (single port) memory banks simultaneously.

Peripherals are on an IO bus, which is separate from the main memory space (so there is no
memory hole, and there is no penalty for accessing IO memory).

Peripherals include UART, GFX core (sprites, tiled background, and framebuffer, collision detection), audio mixer (I2S - TODO), SPI flash DMAC, GPIO, RGB LED driver, debug trace port (TODO: for simulation).

Interrupts (TODO): Vblank, Hblank, Audio interrupt, SPI flash DMA complete. 


SLURM16 CPU
===========

SLURM16 is a 16 bit core, with 16x 16-bit registers. R15 = link 
register (LR), R14 = interrupt link register (ILR), R13 = stack pointer (SP), R0-R12 are general purpose. Although unintended, the architecture bears a strong resemblance to
Jan Gray's XR16 RISC machine.

Five stage pipeline. 

Penalties for accessing memory (bubble inserted into pipeline), especially when out of execution bank.

Instruction Set
===============

All instructions are 16 bits wide. With bit 15 low, The highest 4 bits are the instruction class. With bit 15, high, the top three bits are the instruction class / 2.

Interrupt Vectors
=================

Vector table is located at address 0x0000, which is in boot memory, but can be reprogrammed using an IO port.

| Vector| Vector offset| Purpose|
|--------|---------------|----------------|
|   0    |      0x0      |   Reset        |
|   1    |      0x4      |   Hsync        |
|   2    |      0x8      |   Vsync        |
|   3    |      0xC      |   Audio        |
|   4    |      0x10     |   Timer1?      |
|   5    |      0x14     |   Timer2?      |
|   6    |      0x18     |   SPI flash DMA|
|   7-15 |               |   Reserved     |	


Class 0: General purpose
------------------------

Class 0 has 4 sub-classes, bits 9 - 8 of the opcode.

0. NOP - No operation

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
    |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|---|
    |0  | 0  | 0  | 0  | 0  | 0  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

1. Return instructions

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0  |
    |---|----|----|----|----|----|---|---|---|---|---|---|---|---|---|----|
    |0  | 0  | 0  | 0  | 0  | 0  | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | RT |

        RT : 0 = RET (return) (restore PC from link register and branch)
             1 = IRET (interrupt return) (restore PC from interrupt link register and branch)

2. Reserved 

3. Reserved

4. Single register ALU operation

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 4 | 3 - 0 |
    |---|----|----|----|----|----|---|---|-------|-------|
    |0  | 0  | 0  | 0  | 0  | 1  | 0 | 0 | ALU OP| REG   |

	ALU OP:
		ALU Op is 5 bits, with MSB set to 1

 		16 - asr : arithmetic shift right REG
        17 - lsr : logical shift right REG
        18 - lsl : logical shift left REG
        19 - rolc
        20 - rorc
        21 - rol
        22 - ror
        23 - cc : clear carry
        24 - sc : set carry
        25 - cz : clear zero
        26 - sz : set zero
        27 - cs : clear sign
        28 - ss : set sign
        29 - bswap : byte swap
        30 - 31 : reserved

5. Interrupt

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 4 | 3 - 0 |
    |---|----|----|----|----|----|---|---|-------|-------|
    |0  | 0  | 0  | 0  | 0  | 1  | 0 | 1 | xxxxx | INT   |

	INT: interrupt vector (0-15)

	Branches to interrupt vector specified by INT, linking to
	interrupt link register, r14.

	Vector table is located at address 0x0000.


6. Set / clear interrupts

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 1 |   0   |
    |---|----|----|----|----|----|---|---|-------|-------|
    |0  | 0  | 0  | 0  | 0  | 1  | 1 | 0 |   x   | Flag  |

	Flag: 1 = interrupts enabled, 0 = interrupts disabled


Class 1:  Immediate load
------------------------

|15 | 14 | 13 | 12 | 11 - 0 |
|---|----|----|----|--------|
|0  | 0  | 0  | 1  | IMM_HI |

    IMM_HI: the upper 12 bits of the immediate register, available to the following instruction
    to construct a 16 bit immediate value for branches and alu operations

Class 2: Register to register ALU operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7  - 4 | 3  - 0 |
|---|----|----|----|--------|--------|--------|
|0  | 0  | 1  | 0  | ALU OP |  DEST  |   SRC  |


    ALU OP + ALU OP HI: 5 bits ALU operation
        0 - mov : DEST <- SRC
        1 - add : DEST <- DEST + SRC
        2 - adc : DEST <- DEST + SRC + Carry
        3 - sub : DEST <- DEST - SRC
        4 - sbb : DEST <- DEST - SRC - Carry
        5 - and : DEST <- DEST & SRC
        6 - or  : DEST <- DEST | SRC
        7 - xor : DEST <- DEST ^ SRC
        8-15 - reserved
    
	DEST: destination and operand (alu A input)
    SRC:  source and second operand (alu B input)

Class 3: immediate to register ALU operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7  - 4 |   3  - 0    |
|---|----|----|----|--------|--------|-------------|
|0  | 0  | 1  | 1  | ALU OP |  DEST  |    IMM LO   |


    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- SRC
        1 - add : DEST <- DEST + SRC
        2 - adc : DEST <- DEST + SRC + Carry
        3 - sub : DEST <- DEST - SRC
        4 - sbb : DEST <- DEST - SRC - Carry
        5 - and : DEST <- DEST & SRC
        6 - or  : DEST <- DEST | SRC
        7 - xor : DEST <- DEST ^ SRC
        8-15 - reserved
 
    DEST: destination and operand (alu A input)
    IMM LO : 4 bit immediate which can be combined with the immediate register to produce a 
        16 bit value

Class 4: branch operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7   - 4 |   3 - 0     |
|---|----|----|----|--------|---------|-------------|
|0  | 1  | 0  | 0  | BRNCH  |   REG   | IMM LO      |

    BRNCH:
        0  - BZ, branch if zero
        1  - BNZ, branch if not zero
        2  - BS, branch if sign
        3  - BNS, branch if not sign
        4  - BC, branch if carry
        5  - BNC, branch if not carry
        6  - BA, branch always
        7  - BL, branch and link
		8  - BEQ, branch if equal
		9  - BNE, branch if not equal
		10 - BGT, branch if greater than
		11 - BGE, branch if greater than or equal
		12 - BLT, branch if less than
		13 - BLE, branch if less than or equal
		14 - Reserved  
		15 - Reserved
    REG: index register for register branch
    IMM LO: 4 bit immediate for immediate branch
	PC <- [REG] + IMM

Class 5:
-------- 

Class 6:
--------
  
Class 7:
--------

Reserved


Class 8/9: Reserved

Class 10/11: Reserved

Class 12/13: immediate + register memory operation
-----------------------------------------------

|15 | 14 | 13 | 12 - 9  | 8  | 7  - 4 | 3 - 0 |
|---|----|----|---------|----|--------|-------|
| 1 | 1  | 0  |   IDX   | LS |  REG   | IMM   |

    LS: 0 = load, 1 = store
    IDX: index register, holds address of memory location
    REG: source for store, destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM

Classes 14/15: Port IO
-------------------


|15 | 14 | 13 | 12 - 9  |    8   | 7 - 4 | 3 - 0 |
|---|----|----|---------|--------|-------|-------|
|1  | 1  | 1  | REGP    | RDb/WR | REGV  | IMM   |

    IMM: immediate value
    REGP: port address = IMM + REGP
    REGV: value
    RDb/WR: 0 = port read, 1 = port wr



Assembler Mnemonics
===================
    
    ADC REG_DEST, REG_SRC2, REG_SRC1
    ADC REG_DST, IMM
    ADC REG_DST, REG_SRC
    ADD REG_DEST, REG_SRC2, REG_SRC1
    ADD REG_DST, IMM
    ADD REG_DST, REG_SRC
    AND REG_DEST, REG_SRC2, REG_SRC1
    AND REG_DST, IMM
    AND REG_DST, REG_SRC
    ASR REG_DST, REG_SRC
    BA IMM
    BA [REG]
    BA PC + IMM
    BA [PC + REG]
    BC IMM
    BC [REG]
    BC PC +IMM
    BC [PC +REG]
    BL IMM
    BL [REG]
    BL PC + IMM
    BL [PC + REG]
    BNC IMM
    BNC [REG]
    BNC PC + IMM
    BNC [PC + REG]
    BNS IMM
    BNS PC + IMM
    BNS [PC + REG]
    BNS [REG]
    BNZ IMM
    BNZ PC + IMM
    BNZ [PC + REG]
    BNZ [REG]
    BS IMM
    BS PC + IMM
    BS [PC + REG]
    BS [REG]
    BZ IMM
    BZ PC + IMM
    BZ [PC + REG]
    BZ [REG]
    CC
    CS
    CZ
    DEC REG
    IMM
    INC REG
    IRET
    LD REG_DST, [IMM]
    LD REG_DST, [REG_IDX+]
    LD REG_DST, [REG_IDX-]
    LD REG_DST, [REG_IDX]
    LD REG_DST, [REG_IDX + IMM]
    LSL REG_DST, REG_SRC
    LSR REG_DST, REG_SRC
    MOV REG_DST, IMM
    MOV REG_DST, REG_SRC
    NOP
    OR  REG_DEST, REG_SRC2, REG_SRC1
    OR  REG_DST, IMM
    OR  REG_DST, REG_SRC
    RET
    ROLC REG_DST, REG_SRC
    ROL REG_DST, REG_SRC
    RORC REG_DST, REG_SRC
    SBB REG_DEST, REG_SRC2, REG_SRC1
    SBB REG_DST, IMM
    SBB REG_DST, REG_SRC
    SC
    SS
    ST [IMM], REG_DST
    ST [REG_IDX + IMM], REG_SRC
    ST [REG_IDX+], REG_SRC
    ST [REG_IDX-], REG_SRC
    ST [REG_IDX], REG_SRC
    SUB REG_DEST, REG_SRC2, REG_SRC1
    SUB REG_DST, IMM
    SUB REG_DST, REG_SRC
    SZ
    XOR REG_DEST, REG_SRC2, REG_SRC1
    XOR REG_DST, IMM
    XOR REG_DST, REG_SRC
    
