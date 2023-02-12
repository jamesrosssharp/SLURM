/*

AST.h : SLURM16 Linker Abstract Syntax Tree (from parsing linker scripts)

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#pragma once

#include <deque>
#include <vector>
#include "ExpressionNode.h"
#include "MemoryStatement.h"
#include "Expression.h"
#include "Assignment.h"
#include "SectionBlockStatementSectionList.h"
#include "SectionBlockStatement.h"
#include "SectionsStatement.h"

class AST
{
	public:
		AST();
		~AST();
	
		void push_stack(ExpressionNode* item);
		bool pop_stack(ExpressionNode** item); /* return false if stack is empty */

		void push_number(int number);

		void push_symbol(char *symbol);

		void push_lshift();
		void push_rshift();
		void push_add();
		void push_subtract();
		void push_mult();
		void push_div();
		void push_unary_neg();	
		void push_align();

		void eval_stack();

		void reduce_stack();

		void addAssign(int linenum, char* name); 

		/* we have had an assigment outside of a sections block - consume this as
 		 * a global assignment
 		 */
		void consumeGlobalAssignment();

		/* MEMORY statements */
		void addMemoryOrigin(int line_num);
		void addMemoryLength(int line_num);
		void addMemoryStatement(int line_num, char* name, char* attr);
		void finaliseMemoryBlock(int line_num);

		/* SECTIONS statements */

		/*
		 *	The terminology used here is confusing, but example of SECTIONS block:
		 *	
		 *	1 : SECTIONS {
		 * 	2 :	.text : {
		 *	3 :		KEEP(*(.vectors .vectors.*))
		 *	4 :		*( .text )
		 *	5 :		} > ram
		 *      6 :
		 *	7 :	.data : {
		 *	8 :		. = ALIGN(2);
		 *	9 :		_sdata = .;
		 *	10:		*( .data )
		 *	11:		} > ram
		 *	12:
   		 *	13:	_end = . ;
		 *	14: }
		 *
		 *	Lines 1-14 are the "SectionsBlock"
		 *
		 *	Lines 2-5 and 7-11 are "SectionBlocks"
		 *
		 *	Line 13 is a "SectionsAssignment"
		 *
		 *	Lines 8 and 9 are "SectionBlockAssignments"
		 *
		 *	Lines 3, 4, 10 are "SectionBlockStatements", made up of a filename with wildcard and a "SectionBlockStatementSectionList"
		 */
		
		/* finalise the sections block */
		void finaliseSectionsBlock(int line_num);

		/* pop section block of the stack and create a section block statement in the vector of SECTIONS statements */
		void consumeSectionBlock(int line_num);

		/* consume an assigment from the stack and create an assignment statement in the vector of SECTIONS statements */
		void consumeSectionsAssignment(int line_num);

		/* add a provide statement */
		void addProvide(int line_num, char* symbol);

		/* set the name of the current section block */
		void setCurrentSectionBlockName(char* name); 

		/* consume an assigment from the stack and create as assignment statement in the current section block */
		void addSectionBlockAssignment(); 

		/* consume the current SectionBlockStatementSectionList and create a KeepSectionBlockStatement */
		void addKeepSectionBlockStatement(int line_num);

		/* consume the current SectionBlockStatementSectionList and create a SectionBlockStatement */ 
		void addSectionBlockStatement(int line_num);

		/* add a SectionBlockStatementSectionList to the stack */	
		void addSectionBlockStatementSectionList(char* file_name);

 		/* add a section name to the SectionBlockStatementSectionList stack */
		void pushSectionName(char *section_name);

		/* set the memory for the last section block statement */
		void setCurrentSectionBlockMemory(char* memory_name); 

		/* Print out parsed AST */
		void print();

		std::vector<SectionsStatement>& getSectionsStatements() { return m_sectionsStatements; }
 
	private:
		void push_binary(enum ItemType type);
		
		/* Parse stacks for expressions, assignments, memory statement nodes, etc */
		std::deque<ExpressionNode*> 	 m_stack;
		std::deque<MemoryStatementNode*> m_memoryStack;
		std::deque<Assignment> 		 m_assignmentStack;
		std::deque<std::string> 	 m_sectionNameStack;
		std::deque<SectionBlockStatementSectionList> m_sectionBlockStatementSectionListStack;
		std::deque<SectionBlockStatement> m_sectionBlockStatementStack;
	
		std::string m_currentSectionBlockName;
		std::string m_currentSectionBlockMemory;

		/* Vectors of memory statements, global assignments, etc */
		std::vector<MemoryStatement> m_memoryStatements;
		std::vector<Assignment> m_globalAssignments;
		std::vector<SectionsStatement> m_sectionsStatements;
};

