
#include "AST.h"
#include <exception>
#include <stdexcept>

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
	item->value = number;
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

static int recurse_items(struct ExpressionNode* item)
{
	switch (item->type)
	{
		case ITEM_NUMBER:
			return item->value;
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

void AST::addEqu(int linenum, char* name)
{

	printf("Adding EQU line %d: %s\n", linenum, name);
	eval_stack();

}

void AST::addLabel(int linenum, char* name)
{
	printf("Adding Label line %d %s\n", linenum, name);
}	
