/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

AudioCore.cpp: Audio core emulation


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

class AudioCore {

    public:

        AudioCore();
        ~AudioCore();

        std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val); 
   
        bool step(std::uint16_t* mem, bool& emitAudio, int16_t &audioLeft, int16_t &audioRight);

    private:

        bool          m_run;

        static constexpr int AUDIO_RAM_SIZE = 512;

        std::int16_t m_left_ram[AUDIO_RAM_SIZE];
        std::int16_t m_right_ram[AUDIO_RAM_SIZE];
        std::uint16_t m_left_read_pointer;
        std::uint16_t m_right_read_pointer;
        std::uint32_t m_ticks;
        bool m_prev_left_read_high;
        std::int16_t m_left_accu;
        std::int16_t m_right_accu;
        std::uint16_t m_max_ticks;
};
