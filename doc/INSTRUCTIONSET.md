Instruction Set
===============

All instructions are 16 bits wide. Instructions are separated into "classes", with the "class" given by the high byte. 

Class 0: General purpose
------------------------

Class 0 has 16 sub-classes, bits 11 - 8 of the opcode.

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

2. Load interrupt context to register 

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 4 | 3 - 0  |
    |---|----|----|----|----|----|---|---|-------|--------|
    |0  | 0  | 0  | 0  | 0  | 0  | 1 | 0 |   x   |  REG   |

	When an interrupt is serviced, the CPU saves the imm
	register and the flags into a set of interrupt shadow
	registers. When implementing an RTOS, it is necessary
	to access these shadow registers.

	REG: the register to load the interrupt context into

	Format:

    |15  - 4 | 3 | 2 | 1 | 0 |
    |--------|---|---|---|---|
    | IMM HI | Z | C | S | V |

	MNEMONIC: STIX (STore Interrupt conteXt)

3. Restore interrupt context from register

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 4 | 3 - 0  |
    |---|----|----|----|----|----|---|---|-------|--------|
    |0  | 0  | 0  | 0  | 0  | 0  | 1 | 1 |   x   |  REG   |

	This can be used to restore a saved context to the interrupt
	shadow registers, which will be copied to the immediate register
	and the flags on an IRET instruction. Useful for implementing
	an RTOS or supporting nested interrupts.

	REG: The register to load the saved context from

	MNEMONIC: RSIX (ReStore Interrupt conteXt)

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
        29 - stf : store flags
        30 - rsf: restore flags
        31 : reserved

5. Reserved 

6. Set / clear interrupts

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 1 |   0   |
    |---|----|----|----|----|----|---|---|-------|-------|
    |0  | 0  | 0  | 0  | 0  | 1  | 1 | 0 |   x   | Flag  |

	Flag: 1 = interrupts enabled, 0 = interrupts disabled

7. Sleep

    |15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 - 0 |
    |---|----|----|----|----|----|---|---|-------|
    |0  | 0  | 0  | 0  | 0  | 1  | 1 | 1 |   x   |

	Halts execution. Will wake on interrupt.

Class 1:  Immediate load
------------------------

|15 | 14 | 13 | 12 | 11 - 0 |
|---|----|----|----|--------|
|0  | 0  | 0  | 1  | IMM_HI |

    IMM_HI: the upper 12 bits of the immediate register, available to the following instruction
    to construct a 16 bit immediate value for branches and alu operations. Also used for extended
    instructions.

Class 2: Register to register ALU operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7  - 4 | 3  - 0 |
|---|----|----|----|--------|--------|--------|
|0  | 0  | 1  | 0  | ALU OP |  DEST  |   SRC  |


    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- SRC
        1 - add : DEST <- DEST + SRC
        2 - adc : DEST <- DEST + SRC + Carry
        3 - sub : DEST <- DEST - SRC
        4 - sbb : DEST <- DEST - SRC - Carry
        5 - and : DEST <- DEST & SRC
        6 - or  : DEST <- DEST | SRC
        7 - xor : DEST <- DEST ^ SRC
    	8 - mul : DEST <- DEST * SRC (LO)
        9 - mulu : DEST <- DEST * SRC (HI)
        10: - rrn : rotate nibble right
	11: - rln : rotate nibble left
        12: cmp 
        13: test
        14 - umulu : DEST <- (UNSIGNED) DEST * (UNSIGNED) SRC (HI) 
        15 - bswap : DEST <- bytes swapped SRC
 
        DEST: destination and operand (alu A input)
        SRC:  source and second operand (alu B input)

Class 3: immediate to register ALU operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7  - 4 |   3  - 0    |
|---|----|----|----|--------|--------|-------------|
|0  | 0  | 1  | 1  | ALU OP |  DEST  |    IMM LO   |


    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- IMM
        1 - add : DEST <- DEST + IMM
        2 - adc : DEST <- DEST + IMM + Carry
        3 - sub : DEST <- DEST - IMM
        4 - sbb : DEST <- DEST - IMM - Carry
        5 - and : DEST <- DEST & IMM
        6 - or  : DEST <- DEST | IMM
        7 - xor : DEST <- DEST ^ IMM
        8 - mul : DEST <- DEST * IMM (LO)
        9 - mulu : DEST <- DEST * IMM (HI)
        10 - 11 : reserved
        12 - cmp : compare
        13 - test : bit test
        14 - umulu : DEST <- (UNSIGNED) DEST * (UNSIGNED) IMM (HI)
        15 - reserved
  
    DEST: destination and operand (alu A input)
    IMM LO : 4 bit immediate which can be combined with the immediate register to produce a 
        16 bit value

Class 4: branch operation
-------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8 | 7   - 4 |   3 - 0     |
|---|----|----|----|--------|---------|-------------|
|0  | 1  | 0  | 0  | BRNCH  |   REG   | IMM LO      |

    BRNCH:
        0  - BZ, BEQ branch if zero
        1  - BNZ, BNE branch if not zero
        2  - BS, branch if sign
        3  - BNS, branch if not sign
        4  - BC, BLTU branch if carry or unsigned less than
        5  - BNC, BGEU branch if not carry or unsigned greater than or equal
        6  - BV, branch if overflow     
        7  - BNV, branch if not overflow
        8  - BLT, branch if (signed) less than
        9  - BLE, branch if (signed) less than or equal
        10 - BGT, branch if (signed) greater than
        11 - BGE, branch if (signed) greater than or equal
        12 - BLEU, branch if (unsigned) less than or equal
        13 - BGTU, branch if (unsigned) greater than
        14 - BA, branch always
        15 - BL, branch and link
    REG: index register for register branch
    IMM LO: 4 bit immediate for immediate branch
	PC <- [REG] + IMM

Class 5:
-------- 

Conditional move reg to reg

|15 | 14 | 13 | 12  | 11 - 8  | 7  - 4 | 3 - 0 |
|---|----|----|-----|---------|--------|-------|
| 0 | 1  | 0  |  1  |   COND  |  DEST  | SRC   |

	COND: as per branch
	
	if COND, DEST <= SRC


Class 6: extended register ALU operation
----------------------------------------

Encoded as two words, first word being an immediate value

|31 | 30 | 29 | 28  |      27  - 20     | 19 - 16  |
|---|----|----|-----|-------------------|----------|
| 0 | 0  | 0  | 1   |         x         |  ALU OP  |

|15 | 14 | 13 | 12  |  11 |  10  - 4   | 3 - 0  |
|---|----|----|-----|-----|------------|--------|
| 0 | 1  | 1  | 0   | DIR |  	RX     |  RL    |

  DIR: if 0, DEST = RX, SRC = RL
          1, DEST = RL, SRC = RX

  ALU OP: 4 bits ALU operation
        0 - mov : DEST <- SRC
        1 - add : DEST <- DEST + SRC
        2 - adc : DEST <- DEST + SRC + Carry
        3 - sub : DEST <- DEST - SRC
        4 - sbb : DEST <- DEST - SRC - Carry
        5 - and : DEST <- DEST & SRC
        6 - or  : DEST <- DEST | SRC
        7 - xor : DEST <- DEST ^ SRC
    	8 - mul : DEST <- DEST * SRC (LO)
        9 - mulu : DEST <- DEST * SRC (HI)
        10: - rrn : rotate nibble right
	11: - rln : rotate nibble left
        12: cmp 
        13: test
        14 - umulu : DEST <- (UNSIGNED) DEST * (UNSIGNED) SRC (HI) 
        15 - bswap : DEST <- bytes swapped SRC
 
This instruction can perform ALU operations between a low (r0 - r15) and an extended (x16 - x127) register

	e.g. add x127, r3

Imm (bits 31-16) may be omitted, which will encode to a mov between a low to an extended register.

  
Class 7: upper bank memory operations
-----------------------------------

|15 | 14 | 13 | 12  | 11 - 8  | 7  - 4 | 3 | 2 - 0  |
|---|----|----|-----|---------|--------|---|--------|
| 0 | 1  | 1  | 1   |   IDX   |   REG  | x |  FLG   |

		Provides access to upper two banks of memory

	IDX: index register
	REG: source or destination register
	FLG:
		3'b000 :  LD
		3'b001 :  LDB
		3'b01x :  LDBSX
		3'b100 :  ST
		3'b11x :  STB



Class 8: immediate + register byte memory operation with sign extend
--------------------------------------------------------------------

|15 | 14 | 13 | 12  | 11 - 8  | 7  - 4 | 3 - 0 |
|---|----|----|-----|---------|--------|-------|
| 1 | 0  | 0  | 0   |   IDX   |  REG   | IMM   |

	Provides bytewise access. Lowest byte of a register is loaded or stored. 
	Lowest bit of address
	indicates either lower or upper byte in memory. Sign extends to 16 bit.

    IDX: index register, holds address of memory location
    REG: source for store, destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM




Class 9: three register conditional ALU operation
-------------------------------------------------

Encoded as two words, first word being an immediate value

|31 | 30 | 29 | 28  | 27 - 24 | 23 - 20 | 19 - 16  |
|---|----|----|-----|---------|---------|----------|
| 0 | 0  | 0  | 1   |   x     |  COND   |  ALU OP  |

|15 | 14 | 13 | 12  | 11 - 8  | 7  - 4 | 3 - 0  |
|---|----|----|-----|---------|--------|--------|
| 1 | 0  | 0  | 1   |   DEST  |SRC1 - A|SRC2 - B|

    ALU OP: 4 bits ALU operation
        0 - mov : DEST <- SRC
        1 - add : DEST <- SRC1 + SRC2
        2 - adc : DEST <- SRC1 + SRC2 + Carry
        3 - sub : DEST <- SRC1 - SRC2
        4 - sbb : DEST <- SRC1 - SRC2 - Carry
        5 - and : DEST <- SRC1 & SRC2
        6 - or  : DEST <- SRC1 | SRC2
        7 - xor : DEST <- SRC1 ^ SRC2
    	8 - mul : DEST <- SRC1 * SRC2 (LO)
        9 - mulu : DEST <- SRC1 * SRC2 (HI)
 	10 - rrn : rotate nibble right
	11 - rln : rotate nibble left
        12 - cmp 
        13 - test
        14 - umulu : DEST <- (UNSIGNED) SRC1 * (UNSIGNED) SRC2 (HI) 
        15 - bswap
 
    COND as per branch
    Result is stored / flags changed if COND


Class A/B: immediate + register byte memory operation
-------------------------------------------------------

|15 | 14 | 13 | 12  | 11 - 8  | 7  - 4 | 3 - 0 |
|---|----|----|-----|---------|--------|-------|
| 1 | 0  | 1  | LS  |   IDX   |  REG   | IMM   |

	Provides bytewise access. Lowest byte of a register is loaded or stored. Lowest bit of address
	indicates either lower or upper byte in memory.

    LS: 0 = load, 1 = store
    IDX: index register, holds address of memory location
    REG: source for store, destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM



Class C/D: immediate + register memory operation
-----------------------------------------------

|15 | 14 | 13 | 12 | 11 - 8  | 7  - 4 | 3 - 0 |
|---|----|----|----|---------|--------|-------|
| 1 | 1  | 0  | LS |  IDX    |  REG   | IMM   |

    LS: 0 = load, 1 = store
    IDX: index register, holds address of memory location
    REG: source for store, destination for load
    IMM: immediate address of memory location, effective address = [IDX] + IMM

Classes E/F: Port IO
-------------------


|15 | 14 | 13 |   12   | 11 - 8 | 7 - 4 | 3 - 0 |
|---|----|----|--------|--------|-------|-------|
|1  | 1  | 1  | RDb/WR |  REGP  | REGV  | IMM   |

    IMM: immediate value
    REGP: port address = IMM + REGP
    REGV: value
    RDb/WR: 0 = port read, 1 = port wr



Assembler Mnemonics
===================
    
    ADC REG_DST, IMM
    ADC REG_DST, REG_SRC
    ADD REG_DST, IMM
    ADD REG_DST, REG_SRC
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
 
