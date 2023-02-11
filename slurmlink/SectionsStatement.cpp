/*

SectionsStatement.cpp : SLURM16 Linker Abstract Syntax Tree (from parsing linker scripts)

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "SectionsStatement.h"

std::ostream& operator << (std::ostream& os, const SectionsStatement& s)
{
	switch (s.type)
	{
		case SECTIONS_STATEMENT_TYPE_SECTION_BLOCK:
			os << s.section_block_name << " line: " << s.line_num << " memory:" << s.memory_name << " ";
	
			// print statements
			for (const auto& ss :  s.statements)
				os << ss;
	 
			break;
		case SECTIONS_STATEMENT_TYPE_ASSIGNMENT:
			os << s.assignment;

			break;
		case SECTIONS_STATEMENT_TYPE_PROVIDE:
			os << "PROVIDE " << s.provide_symbol << " = " << s.provide_expression;

			break;
	}


	return os;
}
