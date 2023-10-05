/* vim: set et ts=4 sw=4: */

/*
	
	slurmemu-ng : Next-Generation SlURM16 Emulator

Slurm16SoC.cpp: Top level SoC class

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

#include "Slurm16SoC.h"

#include <cstdio>
#include <stdexcept>

Slurm16SoC::Slurm16SoC(const char* boot_rom_file, const char* flash_rom_file)   :
    m_pcon(flash_rom_file)
{

    m_memory = new uint16_t[65536]; 

    // Load boot rom into memory 

    FILE* b = fopen(boot_rom_file, "rb");
    if (fread(m_memory, 2, 256, b) == 0) 
    {
        throw std::runtime_error("Could not read from rom file.\n");
    }
    fclose(b); 

}

Slurm16SoC::~Slurm16SoC()
{
    delete [] m_memory;
}

void Slurm16SoC::executeOneCycle(bool& emitAudio, std::int16_t &left, std::int16_t &right, ElfDebug& edbg, bool& hs, bool& vs)
{
   // static int tick = 0;

    int irq = m_pcon.step(m_memory, emitAudio, left, right, hs, vs);

   // tick ++;

   // if (tick < 7)
        m_cpu.execute_one_instruction(&m_pcon, m_memory, irq, edbg);
   // if (tick == 10)
   //     tick = 0;
}

