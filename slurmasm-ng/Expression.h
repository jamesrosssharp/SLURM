
#pragma once

#include "ExpressionNode.h"
#include <map>
#include <string>

#include "SymTab_t.h"

struct Expression {

	int lineNum;
	ExpressionNode* root;

	void reset();

	bool evaluate(SymTab_t &tab, int &value);

};

void simplify_expression(ExpressionNode* exp);
void print_expression(struct ExpressionNode* item);
