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
	for (const auto & sec : sections)
	{
		// Iterate over all sections in e

		for (const auto& esec : e->getSections())
		{	
			if (esec.type != SHT_PROGBITS)
				continue;			

			// Match wildcard?
			if (matchStringToWildcard(esec.name, sec))
			{
		
				std::cout << "\t\t\t\t\t" << "Section " << esec.name << " matches wildcard " << sec << std::endl;

				// Consume section data

				/* TODO: The relocation of sections requires more thought. */
				uint32_t address_shift = m_currentOffset;

				for (int i = 0; i < esec.size; i++)
					lsec.data.push_back(esec.data[i]);

				m_currentOffset += esec.size;
	
				// Add section symbols to symbol table - move to new offset

				for (const auto& sym : e->getSymbols())
				{
					if (sym.section == esec.name)
					{
						std::cout << "\t\t\t\t\t\t" << "Adding symbol " << sym.name << " to symbol table : moving to " << (sym.value + address_shift) << std::endl;

						LinkerSymbol lsym;

						if (sym.is_local())
						{
							// Local symbols get prefixed with unique id
							lsym.name = e->getUniqueId() + "." + sym.name;	
						}
						else if (sym.is_weak())
						{
							// Weak symbols get prefixed with ".weak.":
							// We will link them later if there is no GLOBAL with the same (unprefixed) name.
							lsym.name = ".weak." + sym.name;	
						}
						else 
						{
							lsym.name = sym.name;
						}	
					
						lsym.section = lsec.name;
						lsym.value = sym.value + address_shift;
						
						sym.get_bind_type(lsym.bind, lsym.type);

						if (m_symtab.find(lsym.name) != m_symtab.end())
						{
							std::stringstream ss;
							ss << "Error: duplicate symbol '" << lsym.name << "' redefined in " << e->getFileName() << std::endl;
							throw std::runtime_error(ss.str());  
						}


						m_symtab.emplace(lsym.name, lsym);	
					}
				}	

				// Add relocations 
	
				for (const auto& rela : esec.relocation_table)
				{
					int idx = rela.getSymbolIndex();
					std::string sym_name = e->getSymbols()[idx].name;

					if (e->getSymbols()[idx].is_local())
					{
						sym_name = e->getUniqueId() + "." + sym_name;
					}

					std::cout << "\t\t\t\t\t\t " << "Adding relocation " << (rela.offset + address_shift) << " : " << sym_name << " + " << rela.addend << std::endl;

					lsec.relocation_table.emplace_back(rela.offset + address_shift, sym_name, rela.addend);	
				}		

			}
		}
	}
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
			std::cout << "\t\t\t\tChecking file " << fpath << std::endl;
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

	if (m_memoryMap.find(stat.memory_name) == m_memoryMap.end())
	{
		std::stringstream ss;
		ss << "Error: could not find memory " << stat.memory_name << " on line " << stat.line_num << std::endl;
		throw std::runtime_error(ss.str());  
	}

	m_currentOffset = m_memoryMap[stat.memory_name].cur_offset;

	s.load_address = m_currentOffset;

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

	m_memoryMap[stat.memory_name].cur_offset = m_currentOffset;

	m_outputSections.push_back(std::move(s));

}

void Linker::link(const char* outFile)
{
	// Process global assignments. Create symbol table

	for (auto& a : m_ast->getGlobalAssignments())
	{
		int32_t val = 0;
		bool canEval = a.expression.evaluate(m_symtab, val);

		LinkerSymbol s;
		s.section = "ABS";
		s.name = a.symbol;
		s.value = val;
		s.bind = STB_GLOBAL;

		m_symtab.emplace(s.name, s); 
	}

	// Process MEMORY statements to create LinkerMemory structs

	for (auto& m : m_ast->getMemoryStatements())
	{
		LinkerMemory lm;

		lm.name = m.name;
		lm.permissions = m.permissions;
		
		// TODO: Evaluate expressions here
		int val = 0;
		m.origin_expr.evaluate(m_symtab, val);
		lm.origin = val;

		val = 0;
		m.length_expr.evaluate(m_symtab, val);
		lm.length = val;

		lm.cur_offset = lm.origin;

		m_memoryMap.emplace(lm.name, lm);
	}	

	// Emplace a dummy memory
	LinkerMemory nullmem;

	nullmem.name = "";
	nullmem.permissions = "rx";
	nullmem.origin = 0;
	nullmem.length = -1;
	nullmem.cur_offset = 0;

	m_memoryMap.emplace(nullmem.name, nullmem);

	// Process SECTIONS statements, one by one, to create the output sections.
	// Build up symbol table and sections relocation table.	

	m_currentOffset = 0;

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

	// Perform linking of symbols.

	std::cout << "Resolving symbols..." << std::endl;

	// 1. resolve all relocations to actual symbols - resolve weak symbols if they are not overridden. Mark symbol as 
	// referenced if it is referenced.

	for (auto& sec : m_outputSections)
	{
		for (auto& rela : sec.relocation_table)
		{
			if (m_symtab.find(rela.symbol) == m_symtab.end())
			{
				// Look for weak version of symbol.
				std::string weak = ".weak." + rela.symbol;

				if (m_symtab.find(weak) == m_symtab.end())
				{

					std::stringstream ss;
					ss << "Error: symbol '" << rela.symbol << "' could not be resolved. " << std::endl;
					throw std::runtime_error(ss.str());  
				}
				else
				{
					// The symbol exists only as a weak symbol. Rename it for the output writing.
					LinkerSymbol *sym = &(*m_symtab.find(weak)).second; 
					sym->name = sym->name.substr(6);
					rela.resolve(sym);
				}
			}
			else
			{
				rela.resolve(&(*m_symtab.find(rela.symbol)).second);
			}
		}
	}	

	// Garbage collect unused functions.

	std::cout << "Garbage collecting unused functions..." << std::endl;

	for (auto& p : m_symtab)
	{
		auto& sym = p.second;

		if (sym.type == STT_FUNC && !sym.referenced)
		{
			std::cout << "\t - Function '" << sym.name << "' unused. Garbage collecting." << std::endl;
		}

	}

	// Perform relocations

	
	// Create linked output file.

	std::cout << "Creating output file: " << outFile << std::endl;

	ElfFile e;

	for (const auto& sec : m_outputSections)
	{
		e.addSection(sec.name, sec.data, sec.load_address);
	}	

	e.beginSymbolTable();

	for (const auto &p : m_symtab)
	{
		const LinkerSymbol& sym = p.second;
		e.addSymbol(sym.name, sym.section, sym.value, sym.bind, sym.type);
	}

	e.finaliseSymbolTable();

	for (const auto& sec : m_outputSections)
	{
		if (sec.relocation_table.size() != 0)
		{
			e.beginRelocationTable(sec.name);

			for (const auto& rel : sec.relocation_table)
			{
				e.addRelocation(rel.symbol, rel.addend, rel.offset);
			}

			e.finaliseRelocationTable();
		} 
		else
		{
			std::cout << "No relocations for section " << sec.name << std::endl;
		}
	}	

	e.writeOutput(outFile);

}	
