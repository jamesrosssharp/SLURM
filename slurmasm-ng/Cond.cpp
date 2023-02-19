
#include "Cond.h"

#include <map>
#include <string>

std::map<std::string, Cond> condMap = {
	{"EQ",	Cond::EQ},
	{"Z", 	Cond::Z},
	{"NZ", 	Cond::NZ},
	{"NE", 	Cond::NE},
	{"S", 	Cond::S},
	{"NS", 	Cond::NS},
	{"C", 	Cond::C},
	{"LTU", Cond::LTU},
	{"NC", 	Cond::NC},
	{"GEU", Cond::GEU},
	{"V", 	Cond::V},
	{"NV", 	Cond::NV},
	{"LT", 	Cond::LT},
	{"LE", 	Cond::LE},
	{"GT", 	Cond::GT},
	{"GE", 	Cond::GE},
	{"LEU", Cond::LEU},
	{"GTU", Cond::GTU},
	{"A", 	Cond::A},
	{"L", 	Cond::L},
};

Cond Cond_convertCond(std::string opcode)
{
	return condMap[opcode];
}

std::ostream& operator << (std::ostream& os, const Cond& c)
{
	for (const auto& kv : condMap)
	{
		if (kv.second == c)
		{ 
			os << kv.first;
			return os;
		}
	}

	return os;
}

