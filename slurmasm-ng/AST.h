#pragma once

#include "ExpressionNode.h"

#include <deque>


class AST {
	
	public:
		AST();
		~AST();
	
		void push_stack(ExpressionNode* item);
		bool pop_stack(ExpressionNode** item); /* return false if stack is empty */

		void push_number(int number);
		void push_lshift();
		void push_rshift();
		void push_add();
		void push_subtract();
		void push_mult();
		void push_div();
		void push_unary_neg();	

		void eval_stack();

		void addEqu(int linenum, char* name); 
		void addLabel(int linenum, char* name);

	private:
		void push_binary(enum ItemType type);
	
		std::deque<ExpressionNode*> m_stack;
};


