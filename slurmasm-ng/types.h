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

inline std::ostream& operator << (std::ostream& os, const Register& r)
{
	if (r == Register::None)
		os << "nil";
	else
	{
		os << "r" << std::dec << (uint32_t)r;
	}
	return os;
}
