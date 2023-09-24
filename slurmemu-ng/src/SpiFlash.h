/* vim: set et ts=4 sw=4: */

/*
		slurmemu-ng : Next-Generation SlURM16 Emulator

    SpiFlash.h: Emulate the SlURM16 SPI Flash peripheral

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

#include <cstdint>
#include <cstddef>

enum FlashState
{
    Flash_Idle,
    Flash_WakeFlash,
    Flash_PerformDMA,
}

class SpiFlash {

    public:
    
        SpiFlash(const char* flash_file);
        ~SpiFlash();

        std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val); 
   
        bool /* returns true if interrupt */ step(std::uint16_t* mem);

    private:

        uint16_t* m_flashMem;
        std::size_t m_flashSize; 

        std::uint16_t m_flash_address_lo;
        std::uint16_t m_flash_address_hi;
        std::uint32_t m_flash_address2;

        bool m_go;
        bool m_wake;
        
        enum FlashState m_state;

        std::uint16_t m_dma_address;
        std::uint16_t m_dma_count;

        std::uint16_t m_dma_address2;
        std::uint16_t m_dma_count2;

        bool m_done;

        std::uint16_t m_data_reg;

        std::uint32_t m_dummy_cycles;
    
};

