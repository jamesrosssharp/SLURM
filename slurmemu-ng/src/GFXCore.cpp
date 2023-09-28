/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

GFXCore.cpp: GFX core emulation

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

#include "GFXCore.h"
#include <cstdint>

constexpr uint16_t  H_BACK_PORCH   = 48; 
constexpr uint16_t  V_BACK_PORCH   = 33; 
constexpr uint16_t  H_SYNC_PULSE   = 96;
constexpr uint16_t  H_FRONT_PORCH  = 16;
constexpr uint16_t  V_FRONT_PORCH  = 10;
constexpr uint16_t  V_SYNC_PULSE   = 2;
constexpr uint16_t  TOTAL_X        = 800;
constexpr uint16_t  TOTAL_Y        = 525;


GFXCore::GFXCore()  :
    m_x(0),
    m_y(0)
{


}

GFXCore::~GFXCore()
{


}

std::uint16_t GFXCore::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    
    return 0;
} 
   
void GFXCore::step(std::uint16_t* mem, bool& hs_int, bool& vs_int)
{

    hs_int = m_x == (TOTAL_X - H_FRONT_PORCH - H_SYNC_PULSE);
    vs_int = (m_y == (TOTAL_Y - V_FRONT_PORCH - V_SYNC_PULSE)) && (m_x == 0);

    m_x ++;

    if (m_x >= TOTAL_X)
    {
        m_x = 0;
        m_y ++;

        if (m_y >= TOTAL_Y)
            m_y = 0;
    }
}

