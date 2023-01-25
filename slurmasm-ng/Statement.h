#pragma once

#include <vector>
#include <cstdint>
#include <string>

#include "Expression.h"
#include "types.h"
#include "OpCode.h"

#include "SymTab_t.h"
#include "Relocation.h"

enum class StatementType
{
	None,
	LABEL,
	EQU,
	ONE_REGISTER_OPCODE_AND_EXPRESSION,
	OPCODE_WITH_EXPRESSION
};

struct Statement
{
	int		lineNum;

	PseudoOp    pseudoOp;
	OpCode      opcode;

	Register    regSrc;
	Register    regSrc2;
	Register    regDest;

	Register    regInd;
	Register    regOffset;

	Expression expression;

	StatementType type;

	char*		label;

	std::vector<uint8_t> assembledBytes;

	Statement* timesStatement = nullptr;
	int32_t repetitionCount = 1;

	void assemble();

	void reset();

	void annotateLabel(SymTab_t& m_symbolTable, std::string section, int address);

	bool createRelocation(Relocation& rel, SymTab_t &symtab, std::string sec, int address);

private:

	void _assemble_one_reg_opcode_and_expression(int expressionValue);
	void _assemble_opcode_and_expression(int expressionValue);

};
