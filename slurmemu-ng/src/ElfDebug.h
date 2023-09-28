/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

ElfDebug.h: Wrapper around ELF library, so that symbols can be 
            debugged in debug interface

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#pragma once

#include <vector>
#include <map>
#include <cstdint>
#include <string>

#include <ElfFile.h>

struct ElfFunc {

    std::string name;
    std::uint16_t offset;
    std::uint16_t size; 

};

class ElfDebug {

    public:

        ElfDebug(const std::string& elf_file);

        const std::string& addr2Sym(std::uint16_t addr);
        std::uint16_t sym2addr(const std::string& name);
        const std::string& addr2func(std::uint16_t addr);

    private:

        std::map<std::uint16_t, std::string> m_addr2sym;
        std::map<std::string, std::uint16_t> m_sym2addr;
        std::vector<ElfFunc> m_funcs;
        std::string m_null_name;
};
