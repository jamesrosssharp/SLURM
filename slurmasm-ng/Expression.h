
#pragma once

#include "ExpressionNode.h"
#include <map>
#include <string>

#include "SymTab_t.h"

struct Expression {

	int lineNum;
	ExpressionNode* root = nullptr;

	void reset();

	bool evaluate(SymTab_t &tab, int &value);
	bool reduce_to_label_plus_const(SymTab_t &tab);

	bool is_const = false;
	bool is_label_plus_const = false;

	int getValue();

	bool isString();
	char* getString();	

};

void simplify_expression(ExpressionNode* exp);
void print_expression(struct ExpressionNode* item);

std::ostream& operator << (std::ostream& os, const Expression& e);
std::ostream& operator << (std::ostream& os, const ExpressionNode*& e);
