/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

Copper.cpp : Emulate copper

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

#include "Copper.h"
//#include <stdio.h>

Copper::Copper()    :
    m_enable(false),
    m_copper_pc(0),
    m_state(COPPER_IDLE),
    m_r(255), m_g(0), m_b(0),
    m_regAddr(0),
    m_hvWait(0),
    m_yFlip(0),
    m_yFlipEn(false),
    m_xPan(0),
    m_globalAlpha(255),
    m_alphaOverride(true)
{


}

std::uint16_t Copper::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    if (write)
    {
        switch (port & 0xfff)
        {
            case 0xd20:
                m_enable = !!(wr_val & 1);
                break;
            case 0xd21:
                m_yFlip = wr_val & 0x1ff;
                m_yFlipEn = !!(wr_val & 0x8000);
                break;
            case 0xd22:
                m_r = ((wr_val & 0xf00) >> 4);
			    m_g = (wr_val & 0x0f0);
				m_b = ((wr_val & 0x00f) << 4);
	            break;
            case 0xd23:
                m_xPan = (wr_val & 0x1ff);
                break;
            case 0xd24:
                m_alphaOverride = !!(wr_val & 0x8000);
                m_globalAlpha = (wr_val & 0xf) << 4;
                break;
            default:
                if (((port & 0xf00) == 0x400) ||
                    ((port & 0xf00) == 0x500)) {
            
                   m_copperList[((port & 0xfff) - 0x400)] = wr_val;
                }
                break;
        }       
    } 
    return 0;
} 

void Copper::execute(int x, int y)
{

    bool inc_pc = true;

    std::uint16_t ins = m_copperList[(m_copper_pc & 0x1ff)];

    switch ((ins & 0xf000) >> 12)
    {
        case 0x1: /* jump */
            inc_pc = false;
		    m_copper_pc = (ins & 0x1ff);
            break;
        case 0x2:   /* V wait */
            m_hvWait = ins & 0x3ff;
			m_state = COPPER_WAITV;
            break;
        case 0x3:   /* H wait */
		    m_hvWait = ins & 0x3ff;
		    m_state = COPPER_WAITH; 
            break;
        case 0x4:   /* skip V */
            if (y >= (ins & 0x3ff)) 
            {
                m_state = COPPER_BEGIN;
                m_copper_pc += 2;
                inc_pc = false;
            }
            break;
        case 0x5:   /* skip H */
            if (x >= (ins & 0x3ff))
            {
                m_state = COPPER_BEGIN;
                m_copper_pc += 2;
                inc_pc = false;
            }    
            break;
        case 0x6:   /* update background color and wait next scanline */
            m_r = (ins & 0xf00) >> 4;
            m_g = (ins & 0x0f0);
            m_b = (ins & 0x00f) << 4;
            m_hvWait = y + 1;
            m_state = COPPER_WAITV;
            break;
        case 0x7:   /* V wait N */
            m_hvWait = y + (ins & 0x3ff);
            m_state = COPPER_WAITV;
            break;
        case 0x8: /* H wait N */
            m_hvWait = x + (ins & 0x3ff);
            m_state = COPPER_WAITH;
            break;
        case 0x9:   /* register write */

            break;
        case 0xa:   /* x pan write */
            m_xPan = ins & 0x3ff;
            break;
        case 0xb:   /* x pan write and v wait next scanline */
            m_xPan = ins & 0x3ff;
            m_hvWait = y + 1;
            m_state = COPPER_WAITV;
            break;
        case 0xc: /* write background color */ 
            m_r = (ins & 0xf00) >> 4;
            m_g = (ins & 0x0f0);
            m_b = (ins & 0x00f) << 4;
            break;
        case 0xd: /* write alpha */ 
			m_globalAlpha = (ins & 0xf) << 4;
            break;
        default: 
            break;
    }

    if (inc_pc)
        m_copper_pc++;

} 

void Copper::begin()
{
    m_state = COPPER_EXECUTE;
}

void Copper::wait_hv(std::uint16_t hv)
{
    /*static std::uint16_t wait = 0;

    if (wait != m_hvWait)
    {
        printf("CPR wait: %d %d\n", m_hvWait, hv);
        wait = m_hvWait;
    }*/

    if (hv >= m_hvWait)
        m_state = COPPER_EXECUTE; 
}
  
void Copper::step(std::uint16_t* mem, uint16_t x1, uint16_t y1, uint16_t x_in, uint16_t y_in, uint16_t& x, uint16_t& y, bool vs)
{

    if (y_in == 0)
    {
        if (m_enable)
        {
            m_state = COPPER_BEGIN;
            m_copper_pc = 0;
        }
        else
        {
            m_state = COPPER_IDLE;
        }
    }
    else
    {
        switch (m_state)
        {
            case COPPER_IDLE: 
                break;
            case COPPER_BEGIN: 
                begin();
                break;
            case COPPER_EXECUTE: 
                execute(x_in, y_in);
                break;
            case COPPER_WAITH:
                wait_hv(x_in);
                break;
            case COPPER_WAITV:
                wait_hv(y_in);
                break;
            case COPPER_WRITEREG:
                break;
        }
    }

    m_xpanTexture[y1] = m_xPan;

    int idx = (x1 + y1*800);
    
    m_copperBG[idx] = m_r + (m_g << 8) + (m_b << 16) + (m_globalAlpha << 24);
   
    m_alphaOverrideTexture[y1][0] = m_alphaOverride ? 1.0 : 0.0;
    m_alphaOverrideTexture[y1][1] = m_globalAlpha / 240.0; 
    
    x = x_in;
    y = y_in;
}

