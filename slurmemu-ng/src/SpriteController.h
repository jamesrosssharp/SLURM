/* vim: set et ts=4 sw=4: */

/*
	$PROJECT

$FILE: $DESC

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

class SpriteController 
{
    public:    
        std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val);

        const float* getSpriteTexture() const { return &m_sprite_texture[0]; }

    private:

        void write_xram(std::uint16_t idx, std::uint16_t value);
        void write_yram(std::uint16_t idx, std::uint16_t value);
        void write_hram(std::uint16_t idx, std::uint16_t value);
        void write_aram(std::uint16_t idx, std::uint16_t value);


        static constexpr int kSpriteDataChannelX        = 0;
        static constexpr int kSpriteDataChannelEn       = 1;
        static constexpr int kSpriteDataChannelPalHi    = 2;
        static constexpr int kSpriteDataChannelStride   = 3;
        static constexpr int kSpriteDataChannelY        = 4;
        static constexpr int kSpriteDataChannelW        = 5;
        static constexpr int kSpriteDataChannelEndY     = 6;
        static constexpr int kSpriteDataChannelAddress     = 7;

        static constexpr int kNumSpriteDataChannels = 8;

        float m_sprite_texture[256*kNumSpriteDataChannels]; 

};
