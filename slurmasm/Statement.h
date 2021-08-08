#pragma once

#include <vector>
#include <cstdint>

#include "types.h"
#include "Expression.h"

#include "Symbol.h"

enum class StatementType
{
    None,

	/* register only operations */
	ONE_REGISTER_OPCODE,
    TWO_REGISTER_OPCODE,
	THREE_REGISTER_OPCODE,
    INDIRECT_ADDRESSING_OPCODE,
    INDIRECT_ADDRESSING_OPCODE_WITH_POSTINCREMENT,
    INDIRECT_ADDRESSING_OPCODE_WITH_POSTDECREMENT,
    STANDALONE_OPCODE,
    PC_RELATIVE_REG_OPCODE,
    
	/* operations with expressions */
	ONE_REGISTER_OPCODE_AND_EXPRESSION,
    OPCODE_WITH_EXPRESSION,
  	INDIRECT_ADDRESSING_OPCODE_WITH_EXPRESSION,
  	INDIRECT_ADDRESSING_OPCODE_WITH_INDEX_AND_EXPRESSION,
	PC_RELATIVE_EXPRESSION_OPCODE,

	/* pseudo operations etc. */
	PSEUDO_OP_WITH_EXPRESSION,
    LABEL,
    TIMES,
    EQU,
};

struct Statement
{
    int          lineNum;

    PseudoOp    pseudoOp;
    OpCode      opcode;

    Register    regSrc;
    Register    regSrc2;
    Register    regDest;

    Register    regInd;
    Register    regOffset;

    Expression  expression;

    StatementType type;

    char*       label;

	bool 		postIncrement = false;
	bool 		postDecrement = false;

    std::vector<uint16_t> assembledWords;
    uint32_t address;

    Statement* timesStatement = nullptr;
    int32_t repetitionCount = 1;

    void firstPassAssemble(uint32_t &curAddress, SymbolTable& syms);
    void assemble(uint32_t &curAddress);

    void reset();

};
