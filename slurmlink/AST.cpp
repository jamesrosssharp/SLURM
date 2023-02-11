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

void AST::addAssign(int line_num, char* label)
{
//	std::cout << "Linenum: " << line_num << " label: " << label << std::endl;

	Assignment a;

	a.symbol = label; 	
	a.line_num = line_num;
	pop_stack(&a.expression.root);
	m_assignmentStack.push_back(a);
}

void AST::consumeGlobalAssignment()
{
	m_globalAssignments.push_back(m_assignmentStack.back());
	m_assignmentStack.pop_back();
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

	if (attr != NULL)
		m.permissions = attr;

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
	//std::cout << "Memory block line num:" << line_num << std::endl;
}



void AST::print()
{

	std::cout << std::endl << "AST:" << std::endl; 

	// Print global assignments

	std::cout << "\tGlobal assignments: " << std::endl;

	for (const auto& a : m_globalAssignments)
	{
		std::cout << "\t\t" << a << std::endl;
	}

	// Print memory statements

	std::cout << "\tMemory statements: " << std::endl;

	for (const auto& m : m_memoryStatements)
	{
		std::cout << "\t\t" << m << std::endl;
	}

}

void AST::finaliseSectionsBlock(int line_num)
{
	std::cout << "SECTIONS block line " << line_num << std::endl;
}

/* pop section block of the stack and create a section block statement in the vector of SECTIONS statements */
void AST::consumeSectionBlock(int line_num)
{
	SectionsStatement s;

	s.type = SECTIONS_STATEMENT_TYPE_SECTION_BLOCK;
	s.line_num = line_num;
	
	s.section_block_name = m_currentSectionBlockName;
	
	for (const auto& statement : m_sectionBlockStatementStack)
		s.statements.push_back(std::move(statement));
	
	m_sectionBlockStatementStack.clear();

	m_sectionsStatements.push_back(s);

}
	
/* consume an assigment from the stack and create an assignment statement in the vector of SECTIONS statements */
void AST::consumeSectionsAssignment(int line_num)
{
	SectionsStatement s;
	
	s.type = SECTIONS_STATEMENT_TYPE_ASSIGNMENT;
	s.line_num = line_num;
	s.assignment = m_assignmentStack.back();
	m_assignmentStack.pop_back();

	m_sectionsStatements.push_back(s);
	
}

/* add a provide statement */
void AST::addProvide(int line_num, char* symbol)
{
	SectionsStatement s;
	
	s.type = SECTIONS_STATEMENT_TYPE_PROVIDE;
	s.line_num = line_num;
	s.provide_symbol = symbol;
	pop_stack(&s.provide_expression.root);

	m_sectionsStatements.push_back(s);
}

void AST::setCurrentSectionBlockName(char* name)
{
	m_currentSectionBlockName = name;
}

/* consume an assigment from the stack and create as assignment statement in the current section block */
void AST::addSectionBlockAssignment()
{
	SectionBlockStatement s;
	
	s.type = SECTION_BLOCK_STATEMENT_TYPE_ASSIGNMENT;
	s.assignment = std::move(m_assignmentStack.back());
	m_assignmentStack.pop_back();
	m_sectionBlockStatementStack.push_back(s); 

}

/* consume the current SectionBlockStatementSectionList and create a KeepSectionBlockStatement */
void AST::addKeepSectionBlockStatement(int line_num)
{
	SectionBlockStatement s;

	s.type = SECTION_BLOCK_STATEMENT_TYPE_KEEP;
	s.section_list = std::move(m_sectionBlockStatementSectionListStack.back());
	m_sectionBlockStatementSectionListStack.pop_back();
	m_sectionBlockStatementStack.push_back(s); 

}

/* consume the current SectionBlockStatementSectionList and create a SectionBlockStatement */ 
void AST::addSectionBlockStatement(int line_num)
{
	SectionBlockStatement s;

	s.type = SECTION_BLOCK_STATEMENT_TYPE_SECTION_LIST;
	s.section_list = std::move(m_sectionBlockStatementSectionListStack.back());
	m_sectionBlockStatementSectionListStack.pop_back();
	m_sectionBlockStatementStack.push_back(s); 
}

/* add a SectionBlockStatementSectionList to the stack */	
void AST::addSectionBlockStatementSectionList(char* file_name)
{
	/* whoa! what a mouthful */
	SectionBlockStatementSectionList s;

	s.file_name = file_name;
	
	/* take all the section name strings on the stack */
	for (auto& ss : m_sectionNameStack)
	{
		s.sections.push_back(std::move(ss));
	}

	m_sectionNameStack.clear(); 
	m_sectionBlockStatementSectionListStack.push_back(s);	
}

/* add a section name to the SectionBlockStatementSectionList stack */
void AST::pushSectionName(char *section_name)
{
	m_sectionNameStack.push_back(section_name);
}

/* set the memory for the last section block statement */
void AST::setMemoryForLastSectionBlockStatement(char* memory_name)
{
	m_sectionsStatements.back().memory_name = memory_name;
}
	
