/*

slurm-disasm : SLURM16 Disassembler

License: MIT License

Copyright 2022 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <unistd.h>
#include <string.h>
#include <iostream>

#include <host/ELF/ElfFile.h>

void printUsage(char* arg0)
{
	std::cout << "slurm-objdump (C) 2023 J.R.Sharp" << std::endl;
	std::cout << "Usage: " << arg0 << " <file.o>" << std::endl;
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

	exit(EXIT_SUCCESS);
}

