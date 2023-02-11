/*

Linker.cpp : SLURM16 Linker

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <iostream>
#include <sstream>
#include "Linker.h"

Linker::Linker(AST* ast) : m_ast(ast) 
{

}

Linker::~Linker()
{
	// Destroy ELF map and free elf files

}

void Linker::loadElfFile(const char* name)
{
	std::cout << "\tLoading Elf: " << name << std::endl;

	if (m_files.find(name) != m_files.end())
	{
		std::stringstream ss;
		ss << "Error: file already loaded: " << name << std::endl;
		throw std::runtime_error(ss.str());  
	}

	ElfFile* e = new ElfFile();

	e->load(name);

	m_files.emplace(name, e);

}

void Linker::link(const char* outFile)
{
	// Process SECTIONS statements, one by one, to create the output sections.
	// Build up symbol table and sections relocation table.	


	// Perform linking of symbols
	

	// Write relocations.
	
	// Create linked output file.

}
	
