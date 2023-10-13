/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

BackgroundController.cpp: emulate the background controller.

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

#include "BackgroundController.h"

BackgroundCore::BackgroundCore()    :
    m_tilemap_x(0),
    m_tilemap_y(0),
    m_tilemap_address(0),
    m_tileset_address(0),
    m_tilemap_stride(0),
    m_tile_size(0),
    m_enable(false)
{


}

std::uint16_t BackgroundController::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{
    (void) wr_val;
    if (write)
    {
        switch (port & 0xf)
        {
            case 0: /* control reg */ 
                m_bg0.set_enable(wr_val & 1);
                m_bg0.set_pal_hi((wr_val & 0xf0) >> 4);
                m_bg0.set_tilemap_stride((wr_val & 0x300) >> 8);
                m_bg0.set_tile_size((wr_val & 0x8000) >> 15);
                break;
            case 1: /* tile map X */ 
                m_bg0.set_tilemap_x(wr_val);
                break;
            case 2: /* tile map Y */  
                m_bg0.set_tilemap_y(wr_val);
                break;
            case 3: /* tile map address */ 
                m_bg0.set_tilemap_address(wr_val);
                break;
            case 4: /* tile set address */ 
                m_bg0.set_tileset_address(wr_val);
                break;
            case 5: /* control reg */ 
                m_bg1.set_enable(wr_val & 1);
                m_bg1.set_pal_hi((wr_val & 0xf0) >> 4);
                m_bg1.set_tilemap_stride((wr_val & 0x300) >> 8);
                m_bg1.set_tile_size((wr_val & 0x8000) >> 15);
                break;
            case 6: /* tile map X */ 
                m_bg1.set_tilemap_x(wr_val);
                break;
            case 7: /* tile map Y */ 
                m_bg1.set_tilemap_y(wr_val);
                break;
            case 8: /* tile map address */ 
                m_bg1.set_tilemap_address(wr_val);
                break;
            case 9: /* tile set address */ 
                m_bg1.set_tileset_address(wr_val);
                break;
            default: break;
        }
    }      
    return 0;
} 
