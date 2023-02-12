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
#include <string>
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

void Linker::consumeFileSections(LinkerSection& lsec, ElfFile* e, const std::vector<std::string>& sections)
{

	// Iterate over all sections

		// Iterate over all sections in e

		// Match wildcard?
		
		// Consume section data
	
		// Add section symbols to symbol table - move to new offset

		// Add relocations 


}

bool Linker::matchStringToWildcard(const std::string& str, const std::string& wildcard)
{
	// Sanity check wildcard: Kleene (?) stars are only allowed at the beginning or the end
	int i = 0;
	int nKleene = 0;
	for (auto& c : wildcard)
	{
		if (c == '*')
		{
			if ((i != 0 && i != wildcard.size() - 1) || (nKleene != 0))
			{
				throw std::runtime_error("Cannot match to wildcard: a single Kleene star only supported at the start or at the end");
			}
			nKleene ++;
		}

		i++;
	}

	if (wildcard[0] == '*')
	{
		return true;
	}
	else if (wildcard[wildcard.size() - 1] == '*')
	{
		if (str.substr(0, wildcard.size() - 1) == wildcard.substr(0, wildcard.size() - 1))
			return true;
	}
	else {
		if (str == wildcard)
			return true;
	}

	return false;

}

bool Linker::matchPathToWildcard(const std::string& path, const std::string& wildcard)
{
	// Find basename of path

	std::string basename = path.substr(path.find_last_of("/") + 1);

	// Match basename to wildcard

	return matchStringToWildcard(basename, wildcard);
}

void Linker::consumeSections(LinkerSection& lsec, const SectionBlockStatementSectionList& seclist) 
{
	// Match the file wildcards to generate a list of files to consume sections from

	std::cout << "\t\t\tConsuming pattern " << seclist.file_name << std::endl;

	for (const auto& p : m_files)
	{
		std::string fpath = p.first;

		if (matchPathToWildcard(fpath, seclist.file_name))
		{
			//std::cout << "Fpath: " << fpath << " matched to wildcard: " << seclist.file_name << std::endl;
			consumeFileSections(lsec, p.second, seclist.sections);
		}
	}
}

void Linker::processSectionBlock(const SectionsStatement& stat)
{
	std::cout << "\tCreating output section " << stat.section_block_name << std::endl;

	LinkerSection s;

	s.name = stat.section_block_name;

	// Iterate over all statements in the section block	

	for (const auto& blockStat : stat.statements)
	{
		std::cout << "\t\tProcessing " << blockStat << std::endl;

		switch (blockStat.type)
		{
			case SECTION_BLOCK_STATEMENT_TYPE_SECTION_LIST:
			case SECTION_BLOCK_STATEMENT_TYPE_KEEP:
				consumeSections(s, blockStat.section_list);
				break;
			case SECTION_BLOCK_STATEMENT_TYPE_ASSIGNMENT:

				break;
		}

	}

	m_outputSections.push_back(std::move(s));

}

void Linker::link(const char* outFile)
{
	// Process SECTIONS statements, one by one, to create the output sections.
	// Build up symbol table and sections relocation table.	

	for (const auto& s : m_ast->getSectionsStatements())
	{
		switch (s.type)
		{
			case SECTIONS_STATEMENT_TYPE_SECTION_BLOCK:
				processSectionBlock(s);
				break;
			case SECTIONS_STATEMENT_TYPE_ASSIGNMENT:
			case SECTIONS_STATEMENT_TYPE_PROVIDE:

				break;
		}
	}

	// Perform linking of symbols
	

	// Write relocations.
	
	// Create linked output file.

}
	
