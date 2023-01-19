
#include "AST.h"
#include <exception>
#include <stdexcept>
#include <map>

AST::AST()
{

}

AST::~AST()
{

}
	
void AST::push_stack(ExpressionNode* item)
{
	m_stack.push_back(item);	
}

bool AST::pop_stack(ExpressionNode** item)
{
	if (m_stack.empty()) return false;
	*item = m_stack.back();
	m_stack.pop_back();
	return true;
}

void AST::push_number(int number)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_NUMBER;
	item->val.value = number;
	item->left = item->right = NULL;
	push_stack(item);
}


void AST::push_binary(enum ItemType type)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = type;

	if (!pop_stack(&item->right))
		throw std::runtime_error("Parse error!");

	if (!pop_stack(&item->left))
		throw std::runtime_error("Parse error!");

	push_stack(item);
}

void AST::push_lshift()
{
	push_binary(ITEM_LSHIFT);
}

void AST::push_rshift()
{
	push_binary(ITEM_RSHIFT);
}

void AST::push_add()
{
	push_binary(ITEM_ADD);
}

void AST::push_subtract()
{
	push_binary(ITEM_SUBTRACT);
}

void AST::push_mult()
{
	push_binary(ITEM_MULT);
}

void AST::push_div()
{
	push_binary(ITEM_DIV);
}

void AST::push_unary_neg()
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_UNARY_NEG;

	if (!pop_stack(&item->left))
		throw std::runtime_error("Parse error!");

	item->right = NULL;

	push_stack(item);

}

void AST::push_symbol(char *symbol)
{
	ExpressionNode* item = new ExpressionNode();
	item->type = ITEM_LABEL;
	item->val.name = symbol;
	item->left = item->right = NULL;
	push_stack(item);
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
		case ITEM_LABEL:
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

void AST::eval_stack()
{
//	printf("Stack items: %d\n", m_stack.size());

	if (m_stack.size() != 1) 
	{
		printf("Stack has more than 1 element. Parse error?");
		return;
	}

	printf("Result: %d\n", recurse_items(m_stack.back()));

	m_stack.clear();	
}

void recurse_find_symbols(ExpressionNode* n, std::map<char*, int>& m)
{
	if (n == NULL) return;
	if (n->type == ITEM_LABEL) 
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


void AST::reduce_stack()
{

	ExpressionNode* exp = m_stack.back();

	// Traverse expression tree, to find symbols.
	
	std::map<char*, int> map;

	recurse_find_symbols(exp, map);
	
	int symbols = 0;
	char* last_sym = NULL;

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

		m_stack.pop_back();
		push_number(value);

	}
	else if (symbols == 1)
	{

		int v1 = recurse_items_with_symbol_value(exp, 0);
		int v2 = recurse_items_with_symbol_value(exp, 1);

		if (v2 - v1 == 1)
		{
			m_stack.pop_back();
			push_symbol(last_sym);
			push_number(v1);
			push_add();
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
	if (item == NULL)
		return;

	switch (item->type)
	{
		case ITEM_UNARY_NEG:
			printf("-");
			break;
		case ITEM_NUMBER:
			printf("%d", item->val.value);
			return;
		case ITEM_LABEL:
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

void AST::addEqu(int linenum, char* name)
{

	printf("Adding EQU line %d: %s\n", linenum, name);
	//eval_stack();
	
	printf("Before: \n");
	print_expression(m_stack.back());

	printf("\n");
	
	reduce_stack();

	printf("After: \n");
	print_expression(m_stack.back());

	printf("\n");
}

void AST::addLabel(int linenum, char* name)
{
	printf("Adding Label line %d %s\n", linenum, name);
}

void AST::addOneRegisterAndExpressionOpcode(int linenum, char* opcode, char* reg)
{
	printf("Adding one register and expression opcode");
}

void AST::addExpressionOpcode(int linenum, char* opcode)
{
	printf("Adding expression opcode");
}

	
