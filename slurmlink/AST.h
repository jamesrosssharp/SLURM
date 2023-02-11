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

		void eval_stack();

		void reduce_stack();

		void addAssign(int linenum, char* name); 

		void addMemoryOrigin(int line_num);
		void addMemoryLength(int line_num);
		void addMemoryStatement(int line_num, char* name, char* attr);
		void finaliseMemoryBlock(int line_num);

		/* we have had an assigment outside of a sections block - consume this as
 		 * a global assignment
 		 */
		void consumeGlobalAssignment();

		/* Print out parsed AST */
		void print();
 
	private:
		void push_binary(enum ItemType type);
		
		/* Parse stacks for expressions, assignments, memory statement nodes, etc */
		std::deque<ExpressionNode*> m_stack;
		std::deque<MemoryStatementNode*> m_memoryStack;
		std::deque<Assignment> m_assignmentStack;


		/* Vectors of memory statements, global assignments, etc */
		std::vector<MemoryStatement> m_memoryStatements;
		std::vector<Assignment> m_globalAssignments;
};

