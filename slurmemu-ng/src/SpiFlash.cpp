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

    //printf("Flash file size is: %ld bytes\n", my_stat.st_size);

    m_flashMem = new uint16_t[my_stat.st_size];
    m_flashSize = my_stat.st_size;
    
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

std::uint16_t SpiFlash::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{

    if (write)
    {
        switch (port & 0xf)
        {
            case 0:
                m_flash_address_lo = wr_val;
                break;
            case 1:
                m_flash_address_hi = wr_val;
                break;
            case 2:
                if (wr_val & 0x1)
                    m_go = true;
                else
                    m_go = false;

                if (wr_val & 2)
                    m_wake = true;
                else
                    m_wake = false;
        
                break;
            case 5:
                m_dma_address = wr_val; 
                break;
            case 6:
                m_dma_count = wr_val;
                break;
        }
    }
    else
    {
        switch (port & 0xf)
        {
            case 3:
                return m_data_reg;
            case 4:
                if (m_done) return 1;
        }
    }
    return 0;
} 

bool SpiFlash::step(std::uint16_t* mem)
{
    bool intrpt = false;

    switch (m_state)
    {
        case Flash_Idle:
        {
            if (m_go)
            {
                m_state = Flash_PerformDMA;
                m_go = false;
                m_dummy_cycles = 25 / 3 * 24;
                m_flash_address2 = ((((uint32_t)m_flash_address_hi) << 16)  | ((uint32_t)m_flash_address_lo)) - 1024*1024/2;  
                m_dma_address2 = m_dma_address;
                m_dma_count2 = m_dma_count + 1;
            }
            else if (m_wake)
            {
                m_state = Flash_WakeFlash;
                m_wake = false;
                m_dummy_cycles = 25 / 3 * 24;
                m_done = false;
            }
        }
        break;
        case Flash_WakeFlash:
        {
            m_dummy_cycles -= 1;

            if (m_dummy_cycles == 0)
            {
                m_done = true;
                m_state = Flash_Idle;
                intrpt = true;
            }
        }
        break;
        case Flash_PerformDMA:
        {

            m_dummy_cycles -= 1;

            if (m_dummy_cycles == 0)
            {
                m_dummy_cycles = 25 / 3 * 16;

                std::uint16_t data = 0;

                if (m_flash_address2 < m_flashSize)
                    data = m_flashMem[m_flash_address2];
                else
                    data = 0xffff;

                mem[m_dma_address2] = data;
                m_flash_address2 += 1;
                m_dma_address2 += 1;
                m_dma_count -= 1;

                if (m_dma_count == 0)
                {
                    m_done = true;
                    m_state = Flash_Idle;
                    intrpt = true;
                }

            }

        }
        break;
    }

    return intrpt;
}

