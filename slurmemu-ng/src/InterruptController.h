/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

InterruptController.h: Interrupt controller

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

class InterruptController {

    public:

        InterruptController();
        ~InterruptController();

        int step(bool flash_int, bool vs, bool hs, bool timer, bool gpio, bool audio);    
        std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val);

    private:

        static constexpr std::uint8_t HSYNC_INTERRUPT = 1;
        static constexpr std::uint8_t VSYNC_INTERRUPT = 2;
        static constexpr std::uint8_t AUDIO_INTERRUPT = 3;
        static constexpr std::uint8_t FLASH_INTERRUPT = 4;
        static constexpr std::uint8_t GPIO_INTERRUPT  = 5;
        static constexpr std::uint8_t TIMER_INTERRUPT = 6;
        static constexpr std::uint8_t NUM_INTERRUPTS  = 6;


        std::uint8_t m_interrupt_pending;
        std::uint8_t m_interrupt_enabled;
  
};
