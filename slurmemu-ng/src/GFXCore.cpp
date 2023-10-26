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
#include <string.h>

void GFXCore::bg0_render_th(void* gfx)
{
   GFXCore* core = (GFXCore*)gfx;
   core->bg0_render_loop(); 
}

void GFXCore::bg1_render_th(void* gfx)
{
   GFXCore* core = (GFXCore*)gfx;
   core->bg1_render_loop(); 
}



GFXCore::GFXCore()  :
    m_x(0),
    m_y(0),
    m_bg0_sem(0),
    m_bg1_sem(0)
{
//    m_bg0_renderer = std::thread(bg0_render_th, this);
//    m_bg1_renderer = std::thread(bg1_render_th, this);
}

GFXCore::~GFXCore()
{


}

std::uint16_t GFXCore::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    if (port == 0x5f02)
    {
        if (write)
            m_videoMode = wr_val & 1;

    }
    if ((port & 0xff0) == 0xd20)
    {
        return m_copper.port_op(port, write, wr_val);
    }
    else if ((port & 0xf00) <= 0x300)
    {
        return m_sp.port_op(port, write, wr_val);
    }
    else if (((port & 0xf00) == 0x400) || ((port & 0xf00) == 0x500))
    {
        return m_copper.port_op(port, write, wr_val);
    }
    else if ((port & 0xff0) == 0xd00)
    {
        return m_bg.port_op(port, write, wr_val);
    }
    else if ((port & 0xf00) == 0xe00)
    {
        if (write)
            m_palette[port & 0xff] = wr_val;
    }
    return 0;
} 
   
void GFXCore::step(std::uint16_t* mem, bool& hs_int, bool& vs_int)
{

    hs_int = m_x == (TOTAL_X - H_FRONT_PORCH - H_SYNC_PULSE);
    vs_int = (m_y == (TOTAL_Y - V_FRONT_PORCH - V_SYNC_PULSE)) && (m_x == 0);

    std::uint16_t x_out, y_out;

    std::uint16_t xmod = m_x, ymod = m_y;

    if (m_videoMode == kVideoMode320x240)
    {
        xmod = m_x >> 1;
        ymod = m_y >> 1;
    }

    m_copper.step(mem, m_x, m_y, xmod, ymod, x_out, y_out, vs_int);

    m_y_thread = y_out;
    m_y_thread_actual = m_y;
    m_mem_thread = mem;

    if (hs_int)
    {
        memcpy(&m_paletteTexture[kPaletteSize*m_y], m_palette, kPaletteSize); 
        // Wake render threads
        m_bg0_sem.release();
        m_bg1_sem.release();
    }

    m_x ++;

    if (m_x >= TOTAL_X)
    {
        m_x = 0;
        m_y ++;

        if (m_y >= TOTAL_Y)
            m_y = 0;
    }
}

void GFXCore::bg0_render_loop()
{
    while (true)
    {
        m_bg0_sem.acquire();
        m_bg.render_bg0(m_y_thread, m_y_thread_actual, m_mem_thread);
    }
}

void GFXCore::bg1_render_loop()
{
    while (true)
    {
        m_bg1_sem.acquire();
        m_bg.render_bg1(m_y_thread, m_y_thread_actual, m_mem_thread);
    }
}
