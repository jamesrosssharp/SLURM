#pragma once

#include "Symbol.h"

struct Relocation {

	Symbol* sym = nullptr;
	
	/* addend */
	int offset = 0;

	/* address in section */
	int address = 0;
	std::string section;

};

std::ostream& operator << (std::ostream& os, const Relocation& r);
