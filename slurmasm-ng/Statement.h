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

	// Expressions are binary trees of operators 
	// TODO: what about a ternary operator??
	ExpressionNode*	expression;

	StatementType type;

	char*		label;

	std::vector<uint8_t> assembledBytes;

	Statement* timesStatement = nullptr;
	int32_t repetitionCount = 1;

	void assemble();

	void reset();

};
