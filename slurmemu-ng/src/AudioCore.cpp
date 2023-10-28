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

#include "AudioCore.h"
#include <cstdio>

AudioCore::AudioCore()  :
    m_run(false)
{

}

AudioCore::~AudioCore()
{

}

std::uint16_t AudioCore::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    if (write)
    {
        if ((port & 0xfff) == 0x400)
        {
            printf("Audio write: %x\n", wr_val);
            m_run = !!(wr_val & 1); 
        }
        else if ((port & 0xe00) == 0x000) {
            m_left_ram[port & 0x1ff] = wr_val;
        }
        else if ((port & 0xe00) == 0x200) {
            m_right_ram[port & 0x1ff] = wr_val;
        }
    }
    else
    {
        if ((port & 0xf00) == 0x400)
        {
            switch (port & 0xf)
            {
                case 1:
                    return m_left_read_pointer;
                case 2:
                    return m_right_read_pointer;
            }
        }
    }

    return 0;
} 
   
bool AudioCore::step(std::uint16_t* mem, bool & emitAudio, int16_t &audioLeft, int16_t &audioRight)
{
    bool intrpt = false;

    emitAudio = false;

    if (m_run)
    {
        m_ticks ++;

        if (m_ticks == 1024 /*512*/)
        {
            m_ticks = 0;
            emitAudio = true;

            m_left_accu = m_left_ram[m_left_read_pointer];
            m_right_accu = m_right_ram[m_right_read_pointer];

            //m_left_accu /= 2;
            //m_right_accu /= 2;

            audioLeft = m_left_accu;
            audioRight = m_right_accu;

            m_left_read_pointer ++;
            m_right_read_pointer ++;

            m_left_read_pointer &= AUDIO_RAM_SIZE - 1;
            m_right_read_pointer &= AUDIO_RAM_SIZE - 1;

            bool new_left_read_high = (m_left_read_pointer & (AUDIO_RAM_SIZE >> 1)) == (AUDIO_RAM_SIZE >> 1);

            if (m_prev_left_read_high != new_left_read_high)
                intrpt = true;

            m_prev_left_read_high = new_left_read_high;

        }


    }
    else
    {
        m_ticks ++;

        if (m_ticks == 1024 /*512*/)
        {
            m_ticks = 0;
            emitAudio = true;
            audioLeft = 0;
            audioRight = 0;
        } 
    }

    return intrpt;
}

