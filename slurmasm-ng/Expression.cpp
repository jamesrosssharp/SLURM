
#include "Expression.h"
#include <stdio.h>

void Expression::reset()
{
	lineNum = 0;
	root = nullptr;	
}

static int recurse_items(struct ExpressionNode* item)
{
	switch (item->type)
	{
		case ITEM_NUMBER:
			return item->val.value;
		case ITEM_LSHIFT:
			return recurse_items(item->left) << recurse_items(item->right);
		case ITEM_RSHIFT:
			return recurse_items(item->left) >> recurse_items(item->right);
		case ITEM_ADD:
			return recurse_items(item->left) + recurse_items(item->right);
		case ITEM_SUBTRACT:
			return recurse_items(item->left) - recurse_items(item->right);
		case ITEM_MULT:
			return recurse_items(item->left) * recurse_items(item->right);
		case ITEM_DIV:
			return recurse_items(item->left) / recurse_items(item->right);
		case ITEM_UNARY_NEG:
			return - recurse_items(item->left);
	}
	return 0;
}

static int recurse_items_with_symbol_value(struct ExpressionNode* item, int v)
{
	switch (item->type)
	{
		case ITEM_SYMBOL:
			return v;
		case ITEM_NUMBER:
			return item->val.value;
		case ITEM_LSHIFT:
			return recurse_items_with_symbol_value(item->left, v) << recurse_items_with_symbol_value(item->right, v);
		case ITEM_RSHIFT:
			return recurse_items_with_symbol_value(item->left, v) >> recurse_items_with_symbol_value(item->right, v);
		case ITEM_ADD:
			return recurse_items_with_symbol_value(item->left, v) + recurse_items_with_symbol_value(item->right, v);
		case ITEM_SUBTRACT:
			return recurse_items_with_symbol_value(item->left, v) - recurse_items_with_symbol_value(item->right, v);
		case ITEM_MULT:
			return recurse_items_with_symbol_value(item->left, v) * recurse_items_with_symbol_value(item->right, v);
		case ITEM_DIV:
			return recurse_items_with_symbol_value(item->left, v) / recurse_items_with_symbol_value(item->right, v);
		case ITEM_UNARY_NEG:
			return - recurse_items_with_symbol_value(item->left, v);
	}
	return 0;
}

static void recurse_find_symbols(ExpressionNode* n, std::map<char*, int>& m)
{
	if (n == nullptr) return;
	if (n->type == ITEM_SYMBOL) 
	{
		std::map<char*, int>::iterator it;
		it = m.find(n->val.name);
		if (it != m.end())
			m[n->val.name]++;
		else
			m.emplace(n->val.name, 1);
	}
	recurse_find_symbols(n->left, m);
	recurse_find_symbols(n->right, m);
}


void simplify_expression(ExpressionNode* exp) {

	// First, replace with evaluated symbols

	// Traverse expression tree, to find symbols.
	
	std::map<char*, int> map;

	recurse_find_symbols(exp, map);
	
	int symbols = 0;
	char* last_sym = nullptr;

	for (const auto& kv : map)
	{
		symbols += kv.second;
		last_sym = kv.first;
	}

	if (symbols == 0)
	{
		// There are no symbols. We can evaluate the whole expression and reduce it to just a number.
		int value = recurse_items(exp);

		// Here we should free all the nodes to prevent a memory leak

		//m_stack.pop_back();
		//push_number(value);

		// TODO: Fix this

	}
	else if (symbols == 1)
	{
		/*
		 *	Notes about alegbraically reducing the expressions:
		 *
		 *	Instead of applying some kind of recursive algebraic manipulation
		 *	to reduce the expressions, we make sure there is only 1 instance of 
		 *	a single irreducible symbol in the expression, then evaluate for 
		 *	sym = 0,1,2. We need the sym = 2 case to prevent statements of the 
		 *	form X = (1 << sym) + ... from accientally passing the test.
		 *	We *hope* there are no other corner cases. If the evaluated values 
		 *	are what we expect, we can reduce the expression to sym + a constant,
		 *	and hence embed them in elf files. If not, we have to raise an 
		 *	error. 
		 *
		 *	OOPS: THIS IS BROKEN FOR BITWISE OPERATORS. NEED TO FIX
		 *
		 */


		int v1 = recurse_items_with_symbol_value(exp, 0);
		int v2 = recurse_items_with_symbol_value(exp, 1);
		int v3 = recurse_items_with_symbol_value(exp, 2);

		if ((v2 - v1 == 1) && (v3 - v1 == 2))
		{
		//	m_stack.pop_back();
		//	push_symbol(last_sym);
		//	push_number(v1);
		//	push_add();
		
			// TODO: fix this

		}
		else {
			printf("Expression cannot be simply reduced to a label plus a constant.");
		}
	}
	else {
		printf("Expression cannot be simply reduced to a label plus a constant.");

	}

}

void print_expression(struct ExpressionNode* item)
{
	if (item == nullptr)
		return;

	switch (item->type)
	{
		case ITEM_UNARY_NEG:
			printf("-");
			break;
		case ITEM_NUMBER:
			printf("%d", item->val.value);
			return;
		case ITEM_SYMBOL:
			printf("%s", item->val.name);
			return;
	}

	printf("(");
	
	print_expression(item->left);
	
	switch (item->type)
	{
		case ITEM_LSHIFT:
			printf(" << " );
			break;
		case ITEM_RSHIFT:
			printf(" >> ");
			break;
		case ITEM_ADD:
			printf(" + ");
			break;
		case ITEM_SUBTRACT:
			printf(" - ");
			break;
		case ITEM_MULT:
			printf(" * ");
			break;
		case ITEM_DIV:
			printf(" / ");
			break;
	}

	print_expression(item->right);

	printf(")");
}


