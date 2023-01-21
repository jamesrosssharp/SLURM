#pragma once

#include "ExpressionNode.h"
#include "SymbolTable.h"
#include "Statement.h"
#include "types.h"
#include "OpCode.h"

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

		void eval_stack();

		void reduce_stack();

		void addEqu(int linenum, char* name); 
		void addLabel(int linenum, char* name);

		void addOneRegisterAndExpressionOpcode(int linenum, char* opcode, char* reg);
   		void addExpressionOpcode(int linenum, char* opcode); 

		/* print out AST */
		void print();


		void buildSymbolTable();
		void reduceSymbolTable();
		void printSymbolTable();

		void reduceAllExpressions();

	private:

		OpCode convertOpCode(char* opcode);
		Register convertReg(char* reg);
		void push_binary(enum ItemType type);

		std::string m_currentSection = ".text";
	
		std::deque<ExpressionNode*> m_stack;

		Statement m_currentStatement;

		std::map<std::string, std::vector<Statement>> m_sectionStatements;

		SymbolTable m_symbolTable; 
		std::vector<Symbol*> m_symbolList;  // a vector of symbols in order found in file for correct evaluation

};

std::ostream& operator << (std::ostream& os, const Statement& s);

