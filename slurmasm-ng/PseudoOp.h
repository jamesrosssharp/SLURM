#pragma once

#include <cstdint>

enum class PseudoOp : uint32_t
{
	ALIGN,
	DB,
	DW,
	DD,
	SECTION,
	GLOBAL,
	FUNCTION,
	ENDFUNC,
	EXTERN,
	WEAK,
	None
};

#include <string>

PseudoOp PseudoOp_convertPseudoOp(std::string pseudoop);

std::ostream& operator << (std::ostream& os, const PseudoOp& o);

