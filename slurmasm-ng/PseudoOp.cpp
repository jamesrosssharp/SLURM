
#include "PseudoOp.h"

#include <map>
#include <string>

std::map<std::string, PseudoOp> pseudoOpMap = {
	{".ALIGN", 	PseudoOp::ALIGN},
	{"DB", 		PseudoOp::DB},
	{"DW", 		PseudoOp::DW},
	{"DD", 		PseudoOp::DD},
	{".SECTION", 	PseudoOp::SECTION},
	{".GLOBAL", 	PseudoOp::GLOBAL},
	{".FUNCTION", 	PseudoOp::FUNCTION},
	{".ENDFUNC",	PseudoOp::ENDFUNC},
	{".EXTERN",	PseudoOp::EXTERN},
	{".WEAK",	PseudoOp::WEAK}
};

PseudoOp PseudoOp_convertPseudoOp(std::string pseudoop)
{
	return pseudoOpMap[pseudoop];
}

std::ostream& operator << (std::ostream& os, const PseudoOp& o)
{
	for (const auto& kv : pseudoOpMap)
	{
		if (kv.second == o) os << kv.first;
	}

	return os;
}

