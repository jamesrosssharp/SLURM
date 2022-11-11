#pragma once

enum ExpressionNodeType {
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

struct ExpressionNode {

	enum ItemType type;

	union val {
		int value;
		char* name;
	}; 

	ExpressionNode* left;
	ExpressionNode* right;

};

