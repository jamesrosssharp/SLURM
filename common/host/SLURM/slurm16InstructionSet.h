#pragma once

// Instruction Class 0

#define SLRM_NOP_INSTRUCTION      0b0000000000000000
#define SLRM_NOP_INSTRUCTION_MASK 0b1111111111111111

#define SLRM_RET_INSTRUCTION	  0b0000000100000000
#define SLRM_RET_INSTRUCTION_MASK 0b1111111111111111

#define SLRM_IRET_INSTRUCTION	   0b0000000100000001
#define SLRM_IRET_INSTRUCTION_MASK 0b1111111111111111

#define SLRM_STI_INSTRUCTION			0b0000011000000001
#define SLRM_STI_INSTRUCTION_MASK		0b1111111111111111

#define SLRM_CLI_INSTRUCTION			0b0000011000000000
#define SLRM_CLI_INSTRUCTION_MASK		0b1111111111111111

#define SLRM_SLEEP_INSTRUCTION			0b0000011100000000
#define SLRM_SLEEP_INSTRUCTION_MASK		0b1111111111111111

#define SLRM_ALU_SINGLE_REG_INSTRUCTION	   	  0b0000010000000000
#define SLRM_ALU_SINGLE_REG_INSTRUCTION_MASK  0b1111111100000000

// Instruction Class 1

#define SLRM_IMM_INSTRUCTION	   0b0001000000000000
#define SLRM_IMM_INSTRUCTION_MASK  0b1111000000000000

// Instruction Class 2

#define SLRM_ALU_REG_REG_INSTRUCTION		0b0010000000000000
#define SLRM_ALU_REG_REG_INSTRUCTION_MASK 	0b1111000000000000

// Instruction Class 3

#define SLRM_ALU_REG_IMM_INSTRUCTION		0b0011000000000000
#define SLRM_ALU_REG_IMM_INSTRUCTION_MASK	0b1111000000000000

// Instruction Class 4

#define SLRM_BRANCH_INSTRUCTION			0b0100000000000000
#define SLRM_BRANCH_INSTRUCTION_MASK		0b1111000000000000

// Instruction Class 5 reserved

#define SLRM_CONDITIONAL_MOV_INSTRUCTION	0b0101000000000000
#define SLRM_CONDITIONAL_MOV_INSTRUCTION_MASK	0b1111000000000000

// Instruction Class 6 reserved

// Instruction Class 7 reserved

// Instruction Class 8

#define SLRM_IMMEDIATE_PLUS_REG_MEMORY_BYTE_INSTRUCTION_SX	0b1000000000000000
#define SLRM_IMMEDIATE_PLUS_REG_MEMORY_BYTE_INSTRUCTION_SX_MASK	0b1111000000000000

// Instruction Class 9 - three register conditional opcode

#define SLRM_THREE_REG_COND_ALU_INSTRUCTION	 0b1001000000000000
#define SLRM_THREE_REG_COND_ALU_INSTRUCTION_MASK 0b1111000000000000

// Instruction Class 10/11

#define SLRM_IMMEDIATE_PLUS_REG_MEMORY_BYTE_INSTRUCTION  	0b1010000000000000
#define SLRM_IMMEDIATE_PLUS_REG_MEMORY_BYTE_INSTRUCTION_MASK	0b1110000000000000

// Instruction Class 12 / 13

#define SLRM_IMMEDIATE_PLUS_REG_MEMORY_INSTRUCTION  	0b1100000000000000
#define SLRM_IMMEDIATE_PLUS_REG_MEMORY_INSTRUCTION_MASK	0b1110000000000000

// Instruction Class 14/15 : port

#define SLRM_PORT_INSTRUCTION  		0b1110000000000000
#define SLRM_PORT_INSTRUCTION_MASK	0b1110000000000000

