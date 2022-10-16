#pragma once

enum ItemType {
	ITEM_LSHIFT,
	ITEM_RSHIFT,
	ITEM_ADD,
	ITEM_SUBTRACT,
	ITEM_MULT,
	ITEM_DIV,
	ITEM_UNARY_NEG,
	ITEM_NUMBER,
	ITEM_LABEL
};

struct StackItem {

	enum ItemType type;

	int value;

	StackItem* left;
	StackItem* right;

};

#include <deque>

class AST {
	
	public:
		AST();
		~AST();
	
		void push_stack(StackItem* item);
		bool pop_stack(StackItem** item); /* return false if stack is empty */

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

	private:
		void push_binary(enum ItemType type);
	
		std::deque<StackItem*> m_stack;
};


