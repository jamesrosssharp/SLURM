#pragma once

#include "ExpressionNode.h"
#include "SymbolTable.h"
#include "Statement.h"
#include "types.h"
#include "OpCode.h"
#include "PseudoOp.h"
#include "Cond.h"
#include "RelocationTable.h"

#include <deque>
#include <map>
#include <vector>

class AST {
	
	public:
		AST();
		~AST();
	
		void push_stack(ExpressionNode* item);
		bool pop_stack(ExpressionNode** item); /* return false if stack is empty */

		void push_number(int number);

		void push_symbol(char *symbol);

		void push_lshift();
		void push_rshift();
		void push_add();
		void push_subtract();
		void push_mult();
		void push_div();
		void push_unary_neg();	
		void push_char_literal(char *string);
		void push_bitwise_complement();

		void eval_stack();

		void reduce_stack();

		void addEqu(int linenum, char* name); 
		void addLabel(int linenum, char* name);

		void addOneRegisterAndExpressionOpcode(int linenum, char* opcode, char* reg);
   		void addExpressionOpcode(int linenum, char* opcode); 
		void addStandaloneOpcode(int linenum, char* opcode);
 		void addThreeRegCondOpcode(int line_num, char* cond, char* regdest, char* regsrc1, char* regsrc2);
		void addTwoRegisterOpcode(int line_num, char* opcode, char* regdest, char* regsrc);
		void addTwoRegisterCondOpcode(int line_num, char* cond, char* regdest, char* regsrc);
		void addOneRegisterOpcode(int line_num, char* opcode, char* regdest);
		void addOneRegisterIndirectOpcode(int line_num, char* opcode, char* regidx);
		void addOneRegisterIndirectOpcodeWithExpression(int line_num, char* opcode, char* regidx);

		void addTwoRegisterIndirectOpcodeA(int line_num, char* opcode, char* regdest, char* regidx);
		void addTwoRegisterIndirectOpcodeWithExpressionA(int line_num, char* opcode, char* regdest, char* regidx);
		void addTwoRegisterIndirectOpcodeB(int line_num, char* opcode, char* regidx, char* regdest);
		void addTwoRegisterIndirectOpcodeWithExpressionB(int line_num, char* opcode, char* regidx, char* regdest);

		void addPseudoOp(int line_num, char *pseudo_op);
		void addPseudoOpWithExpression(int line_num, char *pseudo_op);
		void addTimes(int line_num);

		void addRegisterToExtendedRegisterALUOp(int line_num, char* opcode, char* extended_reg, char* reg); 
		void addExtendedRegisterToRegisterALUOp(int line_num, char* opcode, char* reg, char* extended_reg);

		void addPseudoOpWithStringLiteral(int line_num, char* opcode, char* string); 

 
		/* print out AST */
		void print();

		void buildSymbolTable();
		void reduceSymbolTable();
		void printSymbolTable();
		void printRelocationTable();

		void reduceAllExpressions();

		void assemble();	
		
		void resolveSymbols();
		void generateRelocationTables();

		void generateTimesMacros();
		void handleAlignStatements();
		void handleGlobalAndWeakSymbols();
		void determineFunctionsAndLengths();

		void writeElfFile(char* outputFile);

	private:

		OpCode convertOpCode(std::string opcode);
		PseudoOp convertPseudoOp(std::string pseudoOp);
		Cond   convertCond(std::string cond);		

		Register convertReg(char* reg);
		void push_binary(enum ItemType type);

		std::string m_currentSection = ".text";
		std::string m_prevSection;
	
		std::deque<ExpressionNode*> m_stack;

		Statement m_currentStatement;

		std::map<std::string, std::vector<Statement>> m_sectionStatements;

		SymbolTable m_symbolTable; 
		std::vector<Symbol*> m_symbolList;  // a vector of symbols in order found in file for correct evaluation

		RelocationTable m_relocationTable;

};


