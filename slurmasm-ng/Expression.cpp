
#include "Expression.h"
#include <stdio.h>
#include <sstream>
#include "SymbolTable.h"

void Expression::reset()
{
	lineNum = 0;
	root = nullptr;	
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

static int recurse_evaluate_with_symbol_table(struct ExpressionNode* item, SymTab_t& tab, bool& success)
{
	switch (item->type)
	{
		case ITEM_SYMBOL:
		{
			Symbol* s;

			std::string n = item->val.name;
			//s = &tab[n];

			if (tab.find(n) == tab.end())
			{
				std::stringstream ss;
				ss << "Undefined symbol: " << item->val.name  << std::endl;

				throw std::runtime_error(ss.str());
			}
			s = &tab[n];

			if (! s->reduced)
			{
				if (s->type == SymbolType::SYMBOL_CONSTANT)
				{
					std::stringstream ss;
					ss << "Referencing another EQU which has not been evaluated yet: " << item->val.name  << std::endl;

					throw std::runtime_error(ss.str());
				}	
				else
					success = false;	
			}
		
			return s->value;

		}
		case ITEM_NUMBER:
			return item->val.value;
		case ITEM_LSHIFT:
			return recurse_evaluate_with_symbol_table(item->left, tab, success) << recurse_evaluate_with_symbol_table(item->right, tab, success);
		case ITEM_RSHIFT:
			return recurse_evaluate_with_symbol_table(item->left, tab, success) >> recurse_evaluate_with_symbol_table(item->right, tab, success);
		case ITEM_ADD:
			return recurse_evaluate_with_symbol_table(item->left, tab, success) + recurse_evaluate_with_symbol_table(item->right, tab, success);
		case ITEM_SUBTRACT:
			return recurse_evaluate_with_symbol_table(item->left, tab, success) - recurse_evaluate_with_symbol_table(item->right, tab, success);
		case ITEM_MULT:
			return recurse_evaluate_with_symbol_table(item->left, tab, success) * recurse_evaluate_with_symbol_table(item->right, tab, success);
		case ITEM_DIV:
			return recurse_evaluate_with_symbol_table(item->left, tab, success) / recurse_evaluate_with_symbol_table(item->right, tab, success);
		case ITEM_UNARY_NEG:
			return - recurse_evaluate_with_symbol_table(item->left, tab, success);
	}
	return 0;
}

bool Expression::evaluate(SymTab_t &tab, int &value)
{

	bool success = true;

	try {
		value = recurse_evaluate_with_symbol_table(root, tab, success);
	} 
	catch (const std::runtime_error& e)
	{
		std::stringstream ss;
		ss << "Expression on line " << lineNum << " could not be evaluated: " << e.what() << std::endl;

		throw std::runtime_error(ss.str());
	}

	return success;
}

static void recurse_replace_evaluated_symbols(struct ExpressionNode* item, SymTab_t& tab)
{

	if (item == nullptr)
		return;

	switch (item->type)
	{
		case ITEM_SYMBOL:
		{
			Symbol* s;

			std::string n = item->val.name;
			s = &tab[n];

			if (s->evaluated)
			{
				item->type = ITEM_NUMBER;
				item->val.value = s->value; 
			}
		
		}
	}
	
	recurse_replace_evaluated_symbols(item->left, tab);
	recurse_replace_evaluated_symbols(item->right, tab);

}

bool recurse_verify_symbol_has_simple_addition(ExpressionNode* n, bool simple)
{
	if (n == nullptr)
		return true;

	switch (n->type)
	{
		case ITEM_SYMBOL:
			return simple;
		case ITEM_NUMBER:
			return true;
		case ITEM_ADD:
		case ITEM_SUBTRACT:
			return recurse_verify_symbol_has_simple_addition(n->left, simple) &&
			       recurse_verify_symbol_has_simple_addition(n->right, simple);
		default:
			return recurse_verify_symbol_has_simple_addition(n->left, false) &&
			       recurse_verify_symbol_has_simple_addition(n->right, false);

	}	

}

bool Expression::reduce_to_label_plus_const(SymTab_t &tab)
{

	if (root == nullptr)
		return true;	// True, because expression doesn't exist so is already effectively reduced!

	// Replace all evaluated symbols in expression

	recurse_replace_evaluated_symbols(root, tab);

	// Traverse expression tree, to find unreplaced symbols.
	
	std::map<char*, int> map;

	recurse_find_symbols(root, map);
	
	int symbols = 0;
	char* last_sym = nullptr;

	for (const auto& kv : map)
	{
		symbols += kv.second;
		last_sym = kv.first;
	}

	if (symbols == 0)
	{
		bool success;

		int v0 = recurse_evaluate_with_symbol_table(root, tab, success);
		root->type = ITEM_NUMBER;
		root->val.value = v0;
		is_const = true;	
		return true;
	}
	else if (symbols == 1)
	{
		// Expression, after replacement, consists of a single unevaluated symbol and one or more operators with constants.
		// First, verify that all operators up the tree from the symbol are either + or -.
		if (!recurse_verify_symbol_has_simple_addition(root, true))
		{
			std::stringstream ss;
			ss << "Expression on line " << lineNum << " cannot be reduced to a single relocation (label + const) as more "
				" complicated operations are performed on the label's address: " << *this  << std::endl;

			throw std::runtime_error(ss.str());

		}

		// Now, evaluate the expression with the symbol = 0 and symbol = 1
		Symbol sym;
		sym.evaluated = true;
		sym.reduced = true;
		sym.type = SymbolType::SYMBOL_CONSTANT;
		sym.value = 0;
		SymTab_t testTab = {{last_sym, sym}};		
		bool success;
		int v0 = recurse_evaluate_with_symbol_table(root, testTab, success);
		std::string lsym = last_sym;
		testTab[lsym].value = 1;
		int v1 = recurse_evaluate_with_symbol_table(root, testTab, success);

		// If the symbol = 1 case was 1 more than the symbol = 0 case, we can reduce the expression.
		if (v1 - v0 == 1)
		{
			ExpressionNode* n1 = new ExpressionNode;
			n1->type = ITEM_ADD;
		
			ExpressionNode* n2 = new ExpressionNode;
			n2->type = ITEM_SYMBOL;
			n2->val.name = last_sym;

			ExpressionNode* n3 = new ExpressionNode;
			n3->type = ITEM_NUMBER;
			n3->val.value = v0;

			n1->left = n2;
			n1->right = n3;

			root = n1;

			is_label_plus_const = true; 

			return true;
		}
		else
		{
			std::stringstream ss;
			ss << "Expression on line " << lineNum << " cannot be reduced to a single relocation (label + const). "  << std::endl;

			throw std::runtime_error(ss.str());

		}

	}
	else
	{
		std::stringstream ss;
		ss << "Expression on line " << lineNum << " consists of multiple unevaluated symbols, and cannot be reduced to a single relocation (label + const). "  << std::endl;

		throw std::runtime_error(ss.str());
	
	}

	return false;
}

std::ostream& operator << (std::ostream& os, const ExpressionNode& e)
{
	switch (e.type)
	{
		case ITEM_UNARY_NEG:
			os << "-";
			break;
		case ITEM_NUMBER:
			os << e.val.value;
			return os;
		case ITEM_SYMBOL:
			os << e.val.name;
			return os;
	}

	os << "(";

	if (e.left != nullptr)
		os << *e.left;


	switch (e.type)
	{
		case ITEM_LSHIFT:
			os << " << " ;
			break;
		case ITEM_RSHIFT:
			os << " >> ";
			break;
		case ITEM_ADD:
			os << " + ";
			break;
		case ITEM_SUBTRACT:
			os << " - ";
			break;
		case ITEM_MULT:
			os << " * ";
			break;
		case ITEM_DIV:
			os << " / ";
			break;
	}

	if (e.right != nullptr)
		os << *e.right;

	os << ")";

	return os;

}

std::ostream& operator << (std::ostream& os, const Expression& e)
{
	if (e.root != nullptr)
		os << *e.root;
	return os;
}

int Expression::getValue()
{
	if (is_const)
	{
		return root->val.value;
	}	
	return 0;
}
