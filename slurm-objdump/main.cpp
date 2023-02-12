/*

slurm-disasm : SLURM16 Disassembler

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <unistd.h>
#include <string.h>
#include <iostream>
#include <iomanip>

#include <host/ELF/ElfFile.h>

#include "Disassembly.h"

void printUsage(char* arg0)
{
	std::cout << "slurm-objdump (C) 2023 J.R.Sharp" << std::endl;
	std::cout << "Usage: " << arg0 << " <file.o>" << std::endl;
}

void section_cb(ElfSection* sec, void* user_data)
{
	// For each progbits section:

	std::cout << "Disassembly of section " << sec->name << ":" << std::endl << std::endl;

	uint32_t offset = 0;

	while (offset < sec->size)
	{

		uint8_t* dptr = &sec->data[offset];
		
		// Are there any symbols at this offset?

		ElfFile* e = (ElfFile*)user_data;

		ElfSymbol* sym = e->findSymbolBySectionAndAddress(sec->name, offset + sec->address);

		if (sym != nullptr)
		{
			std::cout << std::hex << std::setw(8) << std::setfill('0') << sym->value << " <" << sym->name << ">:" << std::endl;
		}

		// Print offset, raw bytes, and disassembly
		std::cout << std::hex << std::setw(4) << std::setfill(' ') << (offset + sec->address) << "\t";

		int consume_size = 2;

		if ((*(dptr+1) & 0xf0) == 0x10)	// imm instruction
			consume_size = 4;

		int j = 0;
		for (int i = 0; i < 8; i++)
		{
			if (i == 0 || i == 2 || (i == 4 && consume_size == 4) || (i == 6 && consume_size == 4))
				std::cout << std::hex << std::setw(2) << std::setfill('0') << (int)dptr[j++];
			else if (i == 1 || i == 3 || (i == 5 && consume_size == 4) || (i == 7 && consume_size == 4))
				std::cout << " ";
			else
				std::cout << "  ";
		}	

		std::cout << "\t";

		// Disassemble?

		if (sec->isExecutableSection())
		{
			std::cout << Disassembly::disassemble(dptr) << "\t";
		}

		// Are there any relocations at this address?

		ElfRelocation* rela = sec->findRelocationAtAddress(offset + sec->address);

		if (rela != nullptr)
		{
			std::cout << "# "; 
			e->printRelocation(rela);
		}
		
		std::cout << std::endl;

		offset += consume_size;

	}
	std::cout << std::endl;

}

int main(int argc, char** argv)
{

	if (argc == 1)
	{
		printUsage(argv[0]);
		exit(EXIT_FAILURE);
	}

	/* Uncomment this code when we need to parse command line switches
 	char c;

	while ((c = getopt (argc, argv, "o:")) != -1)
	{
		switch (c)
		{
			case 'o':
				outputFile = strdup(optarg);
				break;
			default:
				printUsage(argv[0]);
				exit(EXIT_FAILURE);
		}
	}*/

	ElfFile e;

	e.load(argv[1]);

	// Iterate over PROGBITS sections

	e.iterateOverProgbitsSections(section_cb, &e);	

	exit(EXIT_SUCCESS);
}

