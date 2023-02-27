/*

LinkerSection.h : SLURM16 Linker output section class

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#pragma once

#include <vector>
#include "LinkerRelocation.h"

struct LinkerSection 
{

	LinkerSection() {}

	// Move constructor	
	LinkerSection(LinkerSection&& from)
	{
		name = std::move(from.name);
		data = std::move(from.data);
		load_address = from.load_address;
		relocation_table = std::move(from.relocation_table);
		deleted = from.deleted;
		keep = from.keep;
	}	

	std::string name;
	std::vector<uint8_t> data;
	
	/* TODO: Section relocation needs more thought */
	uint32_t load_address;
	
	std::vector<LinkerRelocation> relocation_table;

	bool keep = false;

	bool deleted = false;
};
