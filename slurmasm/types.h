#pragma once

#include <iostream>
#include <iomanip>

enum class Register : uint32_t
{
    r0 = 0,
    r1,
    r2,
    r3,
    r4,
    r5,
    r6,
    r7,
	r8,
	r9,
	r10,
	r11,
	r12,
	r13,
	r14,
	r15,
    None = 0xff
};

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
	DEC,
	IMM,
	IN,
	INC,
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
	RSF,		/* restore flags */
	MUL, /* multiply */
	MULU, /* upper 16 bits of multiply */
	/* more branches */
	BNE,
	BEQ,
	BGE,
	BGT,
	BLE,
	BLT,
	LDB,	/* Load byte */
	STB		/* Store byte */
};

enum class UniqueOpCode
{


};

enum class PseudoOp : uint32_t
{
    ORG,
    ALIGN,
    DW,
    DD,
	DB,
	PADTO,
    None
};

inline std::ostream& operator << (std::ostream& os, const Register& r)
{
    if (r == Register::None)
        os << "nil";
    else
    {
        if ((uint32_t)r < 16)
            os << "r" << std::dec << std::setw(2) << std::setfill('0') << (uint32_t)r;
        else
            os << "s" << std::dec << std::setw(2) << std::setfill('0') << ((uint32_t)r - 16);
    }
	return os;
}
