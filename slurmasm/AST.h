#pragma once

#include <vector>
#include <iostream>
#include <map>
#include <string>

#include "Statement.h"
#include "Expression.h"
#include "types.h"
#include "Symbol.h"

class AST
{

public:

    void addPlusToCurrentStatementExpression();
    void addMinusToCurrentStatementExpression();
    void addLeftParenthesisToCurrentStatementExpression();
    void addRightParenthesisToCurrentStatementExpression();
    void addDivToCurrentStatementExpression();
    void addMultToCurrentStatementExpression();
    void addShiftLeftToCurrentStatementExpression();
    void addShiftRightToCurrentStatementExpression();
    void addAndToCurrentStatementExpression();
    void addOrToCurrentStatementExpression();
    void addXorToCurrentStatementExpression();
    void addNotToCurrentStatementExpression();

    void addIntToCurrentStatementExpression(int val);
    void addUIntToCurrentStatementExpresion(unsigned int val);
    void addStringToCurrentStatementExpression(char* string);

    void addTwoRegisterOpcode(int linenum, char* opcode, char* regDest, char* regSrc);
    void addOneRegisterAndExpressionOpcode(int linenum, char* opcode, char* regDest);
    void addExpressionOpcode(int linenum, char* opcode);
    void addStandaloneOpcode(int linenum, char* opcode);
    void addIndirectAddressingOpcode(int linenum, char* opcode, char* regDest, char* regIdx, char* regOffset);
    void addIndirectAddressingOpcodeWithExpression(int linenum, char* opcode, char* regDest, char* regIdx);
    void addOneRegisterOpcode(int linenum, char* opcode, char* regDest);

    void addExpressionPseudoOp(int linenum, char* pseudoOp);

    void addStringLiteralToCurrentStatementExpression(char* string);
    void addCharLiteralToCurrentStatementExpression(char* string);

    void addLabel(int linenum, char* label);
    void addTimes(int linenum);
    void addEqu(int linenum, char* label);

    void buildSymbolTable();
    void printSymbolTable();

    OpCode   convertOpCode(char* opcode);
    PseudoOp convertPseudoOp(char* pseudoOp);
    Register convertReg(char* reg);

    void firstPassAssemble();
    void resolveSymbols();
    void evaluateExpressions();
    void assemble();
    void writeBinOutput(std::string path);

    void printAssembly();

    friend std::ostream& operator << (std::ostream&, const AST&);

private:

    int32_t m_orgAddress = 0;

    Statement m_currentStatement;

    std::vector<Statement> m_statements;

    SymbolTable m_symbolTable; // symbol table as a map for fast access when evaluating expressions
    std::vector<Symbol*> m_symbolList;  // a vector of symbols in order found in file for correct evaluation

};

std::ostream& operator << (std::ostream&, const Statement&);
std::ostream& operator << (std::ostream& os, const AST& ast);
std::ostream& operator << (std::ostream& os, const ExpressionElement& e);
std::ostream& operator << (std::ostream& os, const Expression& e);
std::ostream& operator << (std::ostream& os, const OpCode& op);
std::ostream& operator << (std::ostream& os, const PseudoOp& ps);
std::ostream& operator << (std::ostream& os, const Symbol& sym);
