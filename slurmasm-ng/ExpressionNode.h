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
	ITEM_SYMBOL
};

struct ExpressionNode {

	enum ItemType type;

	union {
		int value;
		char* name;
	} val; 

	ExpressionNode* left;
	ExpressionNode* right;

};

