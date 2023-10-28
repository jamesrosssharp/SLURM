/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

PortController.h: Emulate the SlURM16 Port Controller

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
#include "SpiFlash.h"
#include "InterruptController.h"
#include "Timer.h"
#include "GFXCore.h"
#include "AudioCore.h"
#include "ScratchPad.h"
#include "GPIO.h"

class PortController {

    public:

        PortController(const char* flash_file);
        ~PortController();

        void     port_wr(std::uint16_t port, std::uint16_t value);
        uint16_t port_rd(std::uint16_t port);

        int /* returns IRQ */ step(std::uint16_t* mem, bool& emitAudio, std::int16_t& left, std::int16_t& right, bool& hs, bool& vs);

        GFXCore* getGfxCore() { return &m_gfx; }

        const GPIO& getGPIO() const { return m_gpio; }

    private:

        void    uart_wr(std::uint16_t port, std::uint16_t value);
        uint16_t uart_rd(std::uint16_t port);

        SpiFlash m_flash;
        InterruptController m_intcon;
        Timer    m_tim;
        GFXCore  m_gfx;
        AudioCore m_audio;
        ScratchPad m_scratch;
        GPIO m_gpio;
};

