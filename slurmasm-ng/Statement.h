#pragma once

#include <vector>
#include <cstdint>
#include <string>

#include "Expression.h"
#include "types.h"
#include "OpCode.h"
#include "PseudoOp.h"
#include "Cond.h"

#include "SymTab_t.h"
#include "Relocation.h"

enum class StatementType
{
	None,
	LABEL,
	EQU,
	ONE_REGISTER_OPCODE_AND_EXPRESSION,
	OPCODE_WITH_EXPRESSION,
	STANDALONE_OPCODE,
	TWO_REGISTER_OPCODE,
	TWO_REGISTER_COND_OPCODE,
	THREE_REGISTER_COND_OPCODE,
	ONE_REGISTER_OPCODE,
	ONE_REGISTER_INDIRECT_OPCODE,
	ONE_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION,
	TWO_REGISTER_INDIRECT_OPCODE_A,
	TWO_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION_A,
	TWO_REGISTER_INDIRECT_OPCODE_B,
	TWO_REGISTER_INDIRECT_OPCODE_AND_EXPRESSION_B,
	PSEUDO_OP,
	PSEUDO_OP_WITH_EXPRESSION,
};

struct Statement
{
	int	lineNum;

	PseudoOp    pseudoOp;
	OpCode      opcode;
	Cond	    cond;

	Register    regSrc;
	Register    regSrc2;
	Register    regDest;

	Register    regInd;

	Expression expression;

	StatementType type;

	char*		label;

	std::vector<uint8_t> assembledBytes;
	
	bool hasTimes = false;
	Expression timesExpression;
	int32_t repetitionCount = 1;

	void assemble();

	void reset();

	void annotateLabel(SymTab_t& m_symbolTable, std::string section, int address);

	bool createRelocation(Relocation& rel, SymTab_t &symtab, std::string sec, int address);

private:

	void _assemble_one_reg_opcode_and_expression(int expressionValue);
	void _assemble_opcode_and_expression(int expressionValue);
	void _assemble_standalone_opcode();
	void _assemble_two_register_opcode();
	void _assemble_two_register_cond_opcode();
	void _assemble_three_register_cond_opcode();
	void _assemble_one_register_opcode();
	void _assemble_one_register_indirect_opcode_and_expression(int expressionValue);
	void _assemble_two_register_indirect_opcode_and_expression_A(int expressionValue);
	void _assemble_two_register_indirect_opcode_and_expression_B(int expressionValue);
	void _assemble_pseudo_op_and_expression(int expressionValue);
};


std::ostream& operator << (std::ostream& os, const Statement& s);
