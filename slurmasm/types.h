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
    None = 0xff
};

enum class OpCode : uint32_t
{
	ADC,
	ADD,
	AND,
	BA,
	BC,
	BL,
	BNC,
	BNS,
	BNZ,
	BS,
	BZ,
	CC,
	CS,
	CZ,
	DECM,
	IMM,
	INCM,
	IRET,
	LD,
	LSL,
	LSR,
	MOV,
	NOP,
	OR,
	RET,
	ROL,
	ROLC,
	RORC,
	SBB,
	SC,
	SS,
	ST,
	SUB,
	SZ,
	XOR
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
}
