/*

AST.cpp : SLURM16 Linker Abstract Syntax Tree (from parsing linker scripts)

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "AST.h"
#include <iostream>
#include <sstream>

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
	item->type = ITEM_SYMBOL;
	item->val.name = symbol;
	item->left = item->right = NULL;
	push_stack(item);
}

void AST::addAssign(int linenum, char* label)
{
	std::cout << "Linenum: " << linenum << " label: " << label << std::endl;
}


void AST::addMemoryOrigin(int line_num)
{
	//std::cout << "Memory origin line " << line_num << std::endl;

	MemoryStatementNode* n = new MemoryStatementNode();
	n->type = MEMORY_ITEM_ORIGIN;
	pop_stack(&n->expression.root);
	m_memoryStack.push_back(n);	
}

void AST::addMemoryLength(int line_num)
{
	//std::cout << "Memory length line " << line_num << std::endl;

	MemoryStatementNode* n = new MemoryStatementNode();
	n->type = MEMORY_ITEM_LENGTH;
	pop_stack(&n->expression.root);
	m_memoryStack.push_back(n);
}

void AST::addMemoryStatement(int line_num, char* name, char* attr)
{
	//std::cout << "Memory statement " << line_num << " " << name << " " << attr << std::endl;

	bool gotOrigin = false;
	bool gotLength = false;

	MemoryStatement m;

	m.name = name; 	

	for (const auto& elem : m_memoryStack)
	{
		switch (elem->type)
		{
			case MEMORY_ITEM_ORIGIN:
			{

				if (gotOrigin)
				{
					std::stringstream ss;
					ss << "Error: Memory statement on line " << line_num << " : origin already specified" << std::endl;
					throw std::runtime_error(ss.str());  
				}	
	
				m.origin_expr = elem->expression;

				gotOrigin = true;

			}
			break;
			case MEMORY_ITEM_LENGTH:
			{
				if (gotLength)
				{
					std::stringstream ss;
					ss << "Error: Memory statement on line " << line_num << " : length already specified" << std::endl;
					throw std::runtime_error(ss.str());  
				}	
	
				m.length_expr = elem->expression;

				gotLength = true;
			}
			break;
			default:
				break;
		}
	}

	if (!gotOrigin || !gotLength)
	{
		std::stringstream ss;
		ss << "Error: Memory statement on line " << line_num << " requires origin and length " << std::endl;
		throw std::runtime_error(ss.str());  
	}

	m.line_num = line_num;
	
	m_memoryStack.clear();

	m_memoryStatements.push_back(m);

}

void AST::finaliseMemoryBlock(int line_num)
{
	std::cout << "Memory block line num:" << line_num << std::endl;
}

void AST::print()
{

	std::cout << std::endl << "AST:" << std::endl; 

	// Print memory statements

	std::cout << "\tMemory statements: " << std::endl;

	for (const auto& m : m_memoryStatements)
	{
		std::cout << "\t\t" << m << std::endl;
	}

}
	
