#pragma once

#include <cstdint>
#include <ostream>

struct ExReg {
	uint8_t r;

	void parse(int lineNum, const char* exreg);
};

std::ostream& operator << (std::ostream& os, const ExReg& e);
