/* vim: set et ts=4 sw=4: */

/*
    slurmemu-ng : Next-Generation SlURM16 Emulator

SpriteController.cpp: Sprite controller emulation

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

#include "SpriteController.h"

#include <stdio.h>

void SpriteController::write_xram(std::uint16_t idx, std::uint16_t value)
{
    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelX]      = (float)(value & 0x3ff);
    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelEn]     = (float)(value & 0x400) ? 1.0 : 0.0;
    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelPalHi]  = (float)((value & 0x7800) >> 11);
    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelStride] = (value & 0x8000) ? 256.0 : 320.0;  

}

void SpriteController::write_yram(std::uint16_t idx, std::uint16_t value)
{

    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelY]      = (float)(value & 0x3ff);
    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelW]      = (float)((value & 0xfc00) >> 10);
}

void SpriteController::write_hram(std::uint16_t idx, std::uint16_t value)
{

    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelEndY]      = (float)(value & 0x3ff);
    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannel5bpp]      = (value & 0x8000) ? 1.0 : 0.0;
}

void SpriteController::write_aram(std::uint16_t idx, std::uint16_t value)
{

    m_sprite_texture[idx*kNumSpriteDataChannels + kSpriteDataChannelAddress]      = (float)(value);
}

std::uint16_t SpriteController::port_op(std::uint16_t port, bool write, std::uint16_t wr_val)
{

    if (write)
    {
        switch (port & 0xf00)
        {   
            case 0x000:
                write_xram(port & 0xff, wr_val);
                break;
            case 0x100:
                write_yram(port & 0xff, wr_val); 
                break;
            case 0x200:    
                write_hram(port & 0xff, wr_val);
                break;
            case 0x300:
                write_aram(port & 0xff, wr_val);
                break;
        }
    }
    else if ((port & 0xf00) == 0x700)
    {
        return m_collisionMap[port & 0xff];
    }

    return 0;    
}

