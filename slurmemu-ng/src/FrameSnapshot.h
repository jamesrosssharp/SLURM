/* vim: set et ts=4 sw=4: */

/*
	slurmemu-ng : Next-Generation SlURM16 Emulator

FrameSnapshot.h: everything the renderer needs to draw one frame, copied
from the SoC at vsync so the emulator can carry on while it is drawn.

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
#include "GFXConst.h"

struct BGLayerSnapshot {
    float tilemap_addr;
    float tileset_addr;
    float pal_hi;
    float tile_size;
    float tilemap_x;
    float tilemap_y;
    float row_tiles;
    float enable;
};

struct FrameSnapshot {
    std::uint16_t   mem[65536];
    float           sprites[256 * 9];               /* SpriteController::getSpriteTexture() */
    BGLayerSnapshot bg[2];
    std::uint32_t   copperBG[TOTAL_X * TOTAL_Y];
    std::uint16_t   palette[TOTAL_Y * 256];         /* the palette on each line */
    float           alphaOverride[TOTAL_Y * 2];
    float           xpan[TOTAL_Y];
    float           yFlip;
    float           videoMode;
};
