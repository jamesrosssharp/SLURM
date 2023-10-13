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

#pragma once

#include <cstdint>

enum {
    TILESIZE_16 = 0,
    TILESIZE_8  = 1
}; 

class BackgroundCore {

    public:

        BackgroundCore();

        void render(std::uint16_t y, std::uint16_t y_actual, uint16_t* mem);

        std::uint8_t* get_texture() { return m_texture; }

        void set_tilemap_x(std::uint16_t x) { m_tilemap_x = x; }
        void set_tilemap_y(std::uint16_t y) { m_tilemap_y = y; }
        void set_tilemap_address(std::uint16_t addr) { m_tilemap_address = addr; }
        void set_tileset_address(std::uint16_t addr) { m_tileset_address = addr; }
        void set_tilemap_stride(std::uint16_t stride) { m_tilemap_stride = stride; }
        void set_tile_size(std::uint16_t size) { m_tile_size = size; }
        void set_pal_hi(std::uint8_t pal_hi) { m_pal_hi = pal_hi; }
        void set_enable(bool en) { m_enable = en; }

    private:

        std::uint8_t m_texture[800*525];

        std::uint16_t m_tilemap_x;
        std::uint16_t m_tilemap_y;
        std::uint16_t m_tilemap_address;
        std::uint16_t m_tileset_address;
        std::uint16_t m_tilemap_stride;
        std::uint16_t m_tile_size;
        std::uint8_t  m_pal_hi;
        bool          m_enable;
};

class BackgroundController {

    public:
        std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val);

        void render_bg0(std::uint16_t y, std::uint16_t y_actual, uint16_t* mem) { m_bg0.render(y, y_actual, mem); }
        void render_bg1(std::uint16_t y, std::uint16_t y_actual, uint16_t* mem) { m_bg1.render(y, y_actual, mem); }

        std::uint8_t* getBG0Texture(){ return m_bg0.get_texture(); }
        std::uint8_t* getBG1Texture(){ return m_bg1.get_texture(); }

    private:
        BackgroundCore m_bg0;
        BackgroundCore m_bg1;
};
