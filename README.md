SLURM - Simple-Logic Micro RISC Machine
======================================

A simple microcontroller core, with emphasis on simplicity of instruction set and verilog implementation. 

Goal: synthesize SLURM for multiple targets, e.g. FPGAs, ASIC, or discrete 74 series logic gates.

Most components in the design are parameterizable, e.g. configurable number of registers, and bus width etc.

SLURM16
=======

SLURM16 is the 16 bit core, with 8 16-bit registers. R7 = program counter (PC), R6 = link 
register (LR), R5 = interrupt link register (ILR), R4 = stack pointer (SP), R0-R3 are general purpose. 

Instruction Set
===============

All instructions are 16 bits wide. The highest 4 bits are the instruction class.

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

2. Increment multiple


    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 - 0 |
    |---|----|----|----|----|----|---|---|---|---|-------|
    |0  | 0  | 0  | 0  | 0  | 0  | 1 | 0 | 0 | 0 | REGS  |

        REGS: if any bits are zero, the register will be incremented

3.  Decrement multiple

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 - 0 |
    |---|----|----|----|----|----|---|---|---|---|-------|
    |0  | 0  | 0  | 0  | 0  | 0  | 1 | 1 | 0 | 0 | REGS  |

        REGS: if any bits are zero, the register will be decremented

Class 1:  Immediate load
------------------------

|15 | 14 | 13 | 12 | 11 - 0 |
|---|----|----|----|--------|
|0  | 0  | 0  | 1  | IMM_HI |

    IMM_HI: the upper 12 bits of the immediate register, available to the following instruction
    to construct a 16 bit immediate value for branches and alu operations

Class 2: Register to register ALU operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7   | 6 - 4 |      3    | 2 - 0 |
|---|----|----|----|--------|-----|-------|-----------|-------|
|0  | 0  | 1  | 0  | ALU OP | SDb | DEST  | ALU OP HI |  SRC  |


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
        16 - asr : arithmetic shift right SRC and store to DEST
        17 - lsr : logical shift right SRC and store to DEST
        18 - lsl : logical shift left SRC and store to DEST
        19 - rolc
        20 - rorc
        21 - rol
        22 - cc : clear carry
        23 - sc : set carry
        24 - cz : clear zero
        25 - sz : set zero
        26 - cs : clear sign
        27 - ss : set sign
        28 - 31 : reserved
 
    SDb:  if low, store result to DEST register, otherwise discard result (used for tst, cmp)
    DEST: destination and operand (alu A input)
    SRC:  source and second operand (alu B input)

Class 3: immediate to register ALU operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7   | 6 - 4 |   3  - 0    |
|---|----|----|----|--------|-----|-------|-------------|
|0  | 0  | 1  | 1  | ALU OP | SDb | DEST  |    IMM LO   |


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
 
    SDb:  if low, store result to DEST register, otherwise discard result (used for tst, cmp)
    DEST: destination and operand (alu A input)
    IMM LO : 4 bit immediate which can be combined with the immediate register to produce a 
        16 bit value

Class 4: branch operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 | 10 - 8 | 7   | 6- 4 |   3 - 0     |
|---|----|----|----|----|--------|-----|------|-------------|
|0  | 1  | 0  | 0  |  R | BRNCH  | REL | REG  | IMM LO      |

    R: if 0, branch to immediate address
       if 1, branch to address pointed to by REG
    BRNCH:
        0 - BZ, branch if zero
        1 - BNZ, branch if not zero
        2 - BS, branch if sign
        3 - BNS, branch if not sign
        4 - BC, branch if carry
        5 - BNC, branch if not carry
        6 - BA, branch always
        7 - BL, branch and link
    REL: if 0, branch is absolute
         if 1, branch is relative: PC <- PC + REG (R = 1) or PC - IMM:IMMLO (R = 0)
    REG: index register for register branch
    IMM LO: 4 bit immediate for immediate branch

Class 5: index register memory operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 | 10 | 9  | 8  | 7 | 6- 4 | 3 | 2 - 0 |
|---|----|----|----|----|----|----|--- |---|------|---|-------|
|0  | 1  | 0  | 1  |  x | PD | PI | LS | x | REG  | x | IDX   |

    PD: 1 = no post decrement, 0 = post decrement
    PI: 1 = no post increment, 0 = post increment (increment takes precedence over decrement)
    LS: 0 = load, 1 = store
    REG: source for store, destination for load
    IDX: index register, holds address of memory location

Class 6: immediate memory operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 | 10 | 9  | 8  | 7 | 6- 4 | 3 - 0 |
|---|----|----|----|----|----|----|--- |---|------|-------|
|0  | 1  | 1  | 0  |  x | x  | x  | LS | x | REG  | IMM   |

    LS: 0 = load, 1 = store
    REG: source for store, destination for load
    IMM: immediate address of memory location
    
Class 7: immediate + register memory operation
-----------------------------------------------

|15 | 14 | 13 | 12 | 11 - 9  | 8  | 7 | 6 - 4 | 3 - 0 |
|---|----|----|----|---------|----|---|-------|-------|
|0  | 1  | 1  | 1  |    IDX  | LS | x | REG   | IMM   |

    LS: 0 = load, 1 = store
    IDX: index register, holds address of memory location
    REG: source for store, destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM

Class 8: 16 bit unsigned multiply with 32 bit result
----------------------------------------------------

|15 | 14 | 13 | 12 | 11 - 9  | 8  - 6 | 5 - 3 | 2 - 0 |
|---|----|----|----|---------|--------|-------|-------|
|1  | 0  | 0  | 0  |  DEST2  |  DEST1 | SRC2  | SRC1  |

    For versions of slurm16 with 16x16 multiplier

    DEST2:DEST1 = SRC1 x SRC2

Class 9: 16 bit signed multiply with 32 bit result
----------------------------------------------------

|15 | 14 | 13 | 12 | 11 - 9  | 8  - 6 | 5 - 3 | 2 - 0 |
|---|----|----|----|---------|--------|-------|-------|
|1  | 0  | 0  | 1  |  DEST2  |  DEST1 | SRC2  | SRC1  |

    For versions of slurm16 with 16x16 multiplier

    DEST2:DEST1 = SRC1 x SRC2


Class 10: ALU operations 0-7 with separate destination register
----------------------------------------------------------------

|15 | 14 | 13 | 12 | 11 - 9  | 8  - 6 | 5 - 3 | 2 - 0 |
|---|----|----|----|---------|--------|-------|-------|
|1  | 0  | 1  | 0  |  ALU OP |  DEST  | SRC2  | SRC1  |

     ALU OP : 3 bits ALU operation
        0 - mov : DEST <- SRC1
        1 - add : DEST <- SRC2 + SRC1
        2 - adc : DEST <- SRC2 + SRC1 + Carry
        3 - sub : DEST <- SRC2 - SRC1
        4 - sbb : DEST <- SRC2 - SRC1 - Carry
        5 - and : DEST <- SRC2 & SRC1
        6 - or  : DEST <- SRC2 | SRC1
        7 - xor : DEST <- SRC2 ^ SRC1
     
Classes 11 - 15 are reserved for future expansion





