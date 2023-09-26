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

AudioCore::AudioCore()  :
    m_count(0),
    m_run(0)
{

}

AudioCore::~AudioCore()
{

}

std::uint16_t AudioCore::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    if (write)
    {
        if (port & 0xfff == 400)
            m_run = wr_val & 1; 
    }


    return 0;
} 
   
bool AudioCore::step(std::uint16_t* mem, uint16_t &audioLeft, uint16_t &audioRight)
{
    bool intrpt = false;

    if (m_run)
        m_count ++;

    if (m_count == 1023)
    {
        intrpt = true;
        m_count = 0;
    }

    return intrpt;
}

