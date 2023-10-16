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

#include "GFXConst.h"
#include <string.h>


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

void BackgroundCore::render(std::uint16_t y, std::uint16_t y_actual, uint16_t* mem)
{

    uint32_t address = 0;
    uint16_t tilesize = 0;

    if (!m_enable)
    {
        memset(&m_texture[(y_actual * TOTAL_X)], 0, TOTAL_X);
        return;
    }

    switch (m_tile_size)
    {
        case TILESIZE_16:
            address = (m_tilemap_address<<1) + (m_tilemap_x>>4) + ((m_tilemap_y + y)>>4)*64;
            tilesize = 16;
            break;
        case TILESIZE_8:
            address = (m_tilemap_address<<1) + (m_tilemap_x>>3) + ((m_tilemap_y + y)>>3)*64;
            tilesize = 8;
            break;
    }

    uint8_t* tilemap = &((uint8_t*)mem)[address];
    uint8_t* line = &m_texture[(y_actual * TOTAL_X) + tilesize - (m_tilemap_x & (tilesize - 1))];  

    uint16_t x = 0;
    while (x < TOTAL_X - tilesize)
    {
        uint8_t tile = *tilemap;
        
        uint16_t tile_x = 0;
        uint16_t tile_y = 0;

        switch (m_tile_size)
        {
            case TILESIZE_16:
                tile_x = tile & 15;
                tile_y = tile >> 4;
                break;
            case TILESIZE_8:
                tile_x = tile & 31;
                tile_y = tile >> 5;
                break;
        }

 
        uint16_t* tile_data = &mem[m_tileset_address + (tile_x)*(tilesize>>2) + (tile_y)*64*tilesize + 64*((m_tilemap_y + y) & (tilesize - 1))];

        for (int i = 0; i < (tilesize>>2); i ++)
        {
            uint16_t tdat = *tile_data++;
            
            for (int j = 0; j < 4; j++)
            {
                uint8_t dat = tdat & 0xf;
                if (dat == 0)
                    *line++ = 0;
                else
                    *line++ = (m_pal_hi<<4) | dat;
                tdat >>= 4;
            }
        } 

        x += tilesize;
        tilemap++;        
    }
}

