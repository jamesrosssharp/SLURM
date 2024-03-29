/*

SectionsStatement.h : SLURM16 Linker Abstract Syntax Tree (from parsing linker scripts)

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#pragma once

#include <iostream>
#include "SectionBlockStatement.h"
#include "Expression.h"
#include "Assignment.h"

enum SectionsStatementType {
	SECTIONS_STATEMENT_TYPE_SECTION_BLOCK,
	SECTIONS_STATEMENT_TYPE_ASSIGNMENT,
	SECTIONS_STATEMENT_TYPE_PROVIDE
};

struct SectionsStatement {

	int line_num;
	enum SectionsStatementType type;

	std::string memory_name;
	std::string section_block_name;
	std::vector<SectionBlockStatement> statements;
	
	std::string provide_symbol;
	Expression provide_expression;

	Assignment assignment;
	 
};

std::ostream& operator << (std::ostream& os, const SectionsStatement& s);
