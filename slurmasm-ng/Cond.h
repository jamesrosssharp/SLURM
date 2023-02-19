#pragma once

#include <cstdint>
#include <string>
#include <ostream>

enum class Cond : uint32_t {
	EQ  = 0,	/* 0 - Equal */
	Z   = 0,  /* 0 - Zero */
	NZ  = 1,	/* 1 - Not-Zero */
	NE  = 1,	/* 1 - Not-equal */
	S   = 2,	/* 2 - Sign */
	NS  = 3,  /* 3 - Not-sign */
	C   = 4,  /* 4 - Carry set */
	LTU = 4,  /* 4 - Less-than, unsigned */
	NC  = 5,	/* 5 - Carry not set */
	GEU = 5,  /* 5 - Greater-than or equal, unsigned */
	V   = 6,  /* 6 - Signed Overflow */ 
	NV  = 7,  /* 7 - No signed overflow */	
	LT  = 8,  /* 8 - signed less than */
	LE  = 9,  /* 9 - signed less than or equal */	
	GT  = 10,  /* 10 - signed greater than */
	GE  = 11,  /* 11 - signed greater than or equal */
	LEU = 12,  /* 12 - less than or equal unsigned */
	GTU = 13,  /* 13 - greater than unsigned */
	A   = 14,  /* 14 - always pass */
	L   = 15,  /* 15 - link (for branch and link) */	
	None = 16  /* No condition */
};


Cond Cond_convertCond(std::string cond);

std::ostream& operator << (std::ostream& os, const Cond& c);
