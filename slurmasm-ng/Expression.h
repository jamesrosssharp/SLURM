
#pragma once

#include "ExpressionNode.h"
#include <map>

struct Expression {

	int lineNum;
	ExpressionNode* root;

	void reset();

};


void simplify_expression(ExpressionNode* exp);
void print_expression(struct ExpressionNode* item);
