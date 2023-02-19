#pragma once

#include <cstdint>

enum class OpCode : uint32_t
{
	None,
	ADC,
	ADD,
	AND,
	ASR,
	BA,
	BC,
	BL,
	BNC,
	BNS,
	BNZ,
	BS,
	BSWAP,
	BZ,
	CC,
	CS,
	CZ,
	IMM,
	IN,
	IRET,
	LD,
	LSL,
	LSR,
	MOV,
	NOP,
	OR,
	OUT,
	RET,
	ROL,
	ROLC,
	ROR,	
	RORC,
	SBB,
	SC,
	SS,
	ST,
	SUB,
	SZ,
	XOR,
	CMP,
	TEST,
	STI,
	CLI,
	SLEEP,
	STF,	/* store flags */
	RSF,	/* restore flags */
	MUL,	/* multiply */
	MULU,	/* upper 16 bits of multiply */
	UMULU,  /* unsigned upper 16 bits of multiply */
	/* more branches */
	BNE,
	BEQ,
	BGE,
	BGT,
	BLE,
	BLT,
	BLEU,
	BLTU,
	BGEU,
	BGTU,
	BV,
	BNV,
	LDB,	/* Load byte */
	LDBSX,	/* Load byte, sign extend */
	STB,	/* Store byte */
	RRN,	/* rotate right nibble */
	RLN,	/* rotate left nibble */
};

#include <string>

OpCode OpCode_convertOpCode(std::string opcode);

std::ostream& operator << (std::ostream& os, const OpCode& o);

