#pragma once

#include "Symbol.h"

struct Relocation {

	Symbol* sym = nullptr;
	int offset = 0;

	int address = 0;
	std::string section;

};

std::ostream& operator << (std::ostream& os, const Relocation& r);
