/* vim: set et ts=4 sw=4: */

/*
		slurmemu-ng : Next-Generation SlURM16 Emulator

ElfDebug.cpp: Wrapper around ELF library, so that symbols can be 
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

#include "ElfDebug.h"

ElfDebug::ElfDebug(const std::string& elf_file) :
   m_null_name("UNKNOWN") 
{
    ElfFile e;

/*    e.load(elf_file.c_str());

    for (const auto& sym : e.getSymbols())
    {
        uint8_t bind, type;

        sym.get_bind_type(bind, type);

        if (type & STT_FUNC)
        {
            ElfFunc f;

           // printf("Found func: %s\n", sym.name.c_str());

            f.name = sym.name;
            f.offset = sym.value;
            f.size = sym.size;
        
            m_funcs.push_back(f);
        } 

    }
*/
    m_funcs.emplace_back("Applet", 0x5000, 0x3000);

}

const std::string& ElfDebug::addr2Sym(std::uint16_t addr)
{
    return m_null_name;
}

std::uint16_t ElfDebug::sym2addr(const std::string& name)
{
    return 0;
}

const std::string& ElfDebug::addr2func(std::uint16_t addr)
{
    
    for (const auto &f : m_funcs)
    {

        if ((addr >= f.offset) && (addr <= f.offset + f.size))
            return f.name;

    }

    return m_null_name;
}

