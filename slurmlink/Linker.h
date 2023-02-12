/*

Linker.h : SLURM16 Linker

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#pragma once

#include "AST.h"

#include <host/ELF/ElfFile.h>
#include <vector>
#include <map>

#include "LinkerSection.h"
#include "LinkerSymbol.h"
#include "LinkerSymtab.h"
#include "LinkerMemory.h"

class Linker {

	public:

		Linker(AST* ast);
		~Linker();

		void loadElfFile(const char* name);

		/* where the magic happens... link all the loaded files according to linker script */
		void link(const char* outFile);
		
	private:
		/* private methods */
		
		void processSectionBlock(const SectionsStatement& stat);
		void consumeSections(LinkerSection& lsec, const SectionBlockStatementSectionList& seclist);
		void consumeFileSections(LinkerSection& lsec, ElfFile* e, const std::vector<std::string>& sections);

		bool matchStringToWildcard(const std::string& str, const std::string& wildcard);
		bool matchPathToWildcard(const std::string& path, const std::string& wildcard);
		
		AST* m_ast;
		std::map<std::string, ElfFile*> m_files;	

		std::vector<LinkerSection> m_outputSections;
		LinkerSymtab m_symtab;
		std::map<std::string, LinkerMemory> m_memoryMap;

		uint32_t m_currentOffset;

};
