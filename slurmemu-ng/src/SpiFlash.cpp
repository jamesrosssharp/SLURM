/* vim: set et ts=4 sw=4: */

/*
		slurmemu-ng : Next-Generation SlURM16 Emulator

    SpiFlash.cpp: Emulate the SlURM16 SPI Flash peripheral


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

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <cstdio>
#include <stdexcept>

#include "SpiFlash.h"

SpiFlash::SpiFlash(const char* flash_file)
{

    // Get size of flash_file

    struct stat my_stat;

    if (::stat(flash_file, &my_stat) < 0)
    {
        throw std::runtime_error("Could not stat flash_file\n");
    }

    printf("Flash file size is: %ld bytes\n", my_stat.st_size);

    m_flashMem = new uint16_t[my_stat.st_size];

    FILE* f;

    f = fopen(flash_file, "rb");

    if (fread(m_flashMem, 1, my_stat.st_size, f) != my_stat.st_size)
    {
        fclose(f);
        throw std::runtime_error("Could not read from flash_file\n");
    }

    fclose(f);

}

SpiFlash::~SpiFlash()
{
    delete [] m_flashMem;
}

