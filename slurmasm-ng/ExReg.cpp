

#include "ExReg.h"
#include <stdlib.h>

#include <sstream>

void ExReg::parse(int lineNum, const char* exreg)
{
	r = atoi(&exreg[1]);

	if (r < 16 || r > 127)
	{
		std::stringstream ss;
		ss << "Unsupported extended register " << exreg << "  on line " << lineNum << std::endl;	
		throw std::runtime_error(ss.str());
	}


}


std::ostream& operator << (std::ostream& os, const ExReg& e)
{
	os << "x" << (int)e.r;

	return os;
}
