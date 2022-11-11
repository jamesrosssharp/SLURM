#pragma once

#include <vector>
#include <cstdint>

#include "Expression.h"




enum class StatementType
{
	None,
	LABEL,
	EQU,
};

struct Statement
{
	int		lineNum;

	Expression	expression;

	StatementType type;

	char*		label;

	bool		postIncrement = false;
	bool		postDecrement = false;

	std::vector<uint16_t> assembledWords;
	uint32_t address;
	
	std::vector<uint8_t> assembledBytes;
	bool useBytes;

	Statement* timesStatement = nullptr;
	int32_t repetitionCount = 1;

	void firstPassAssemble(uint32_t &curAddress, SymbolTable& syms);
	void assemble(uint32_t &curAddress);

	void reset();

};
