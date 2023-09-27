/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

Timer.cpp: Timer emulator

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

#include "Timer.h"

#include <cstdio>

Timer::Timer()  :
    m_en(false),
    m_match_val(0x1234)
{

}

Timer::~Timer()
{

}

std::uint16_t Timer::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    if (write)
    {
        switch (port & 0xf)
        {
            case 0:
                m_en = !!(wr_val & 1);
                break;
            case 1:
                m_match_val = wr_val;
                break;
        }
    }
    
    return m_count_out;
} 
   
bool Timer::step(std::uint16_t* mem)
{
    if (m_en)
        m_count = (m_count + 1) & 0x007fffff;

    m_count_out = (m_count >> 7);

    bool intrpt = (m_en && (m_count_out == m_match_val));

    return intrpt;
}

