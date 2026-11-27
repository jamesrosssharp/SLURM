/* vim: set et ts=4 sw=4: */

/*
	
	slurmemu-ng : Next-Generation SlURM16 Emulator

Slurm16SoC.cpp: Top level SoC class

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

#include "Slurm16SoC.h"

#include <cstdio>
#include <stdexcept>
#include <cstring>

Slurm16SoC::Slurm16SoC(const char* boot_rom_file, const char* flash_rom_file)   :
    m_pcon(flash_rom_file)
{

    m_memory = new uint16_t[65536]; 

    // Load boot rom into memory 

    FILE* b = fopen(boot_rom_file, "rb");
    if (fread(m_memory, 2, 256, b) == 0) 
    {
        throw std::runtime_error("Could not read from rom file.\n");
    }
    fclose(b); 

}

Slurm16SoC::~Slurm16SoC()
{
    delete [] m_memory;
}

void Slurm16SoC::executeOneCycle(bool& emitAudio, std::int16_t &left, std::int16_t &right, ElfDebug& edbg, bool& hs, bool& vs)
{
    int irq = m_pcon.step(m_memory, emitAudio, left, right, hs, vs);
    m_cpu.execute_one_instruction(&m_pcon, m_memory, irq, edbg);
}


static void snapshot_layer(BGLayerSnapshot& l, const BackgroundCore& bg)
{
    l.tilemap_addr = bg.get_tilemap_address();
    l.tileset_addr = bg.get_tileset_address();
    l.pal_hi = bg.get_pal_hi() / 16.0;
    l.tile_size = bg.get_tile_size();
    l.tilemap_x = bg.get_tilemap_x();
    l.tilemap_y = bg.get_tilemap_y();
    l.row_tiles = bg.get_tilemap_row_tiles();
    l.enable = bg.get_enable();
}

void Slurm16SoC::snapshot(FrameSnapshot& s)
{
    GFXCore* gfx = m_pcon.getGfxCore();
    const Copper& copper = gfx->getCopper();

    memcpy(s.mem, m_memory, sizeof(s.mem));
    memcpy(s.sprites, gfx->getSpCon().getSpriteTexture(), sizeof(s.sprites));
    snapshot_layer(s.bg[0], gfx->getBGCon().getBG0());
    snapshot_layer(s.bg[1], gfx->getBGCon().getBG1());
    memcpy(s.copperBG, gfx->getCopperBG(), sizeof(s.copperBG));
    memcpy(s.palette, gfx->getPaletteTexture(), sizeof(s.palette));
    memcpy(s.alphaOverride, copper.getAlphaOverride(), sizeof(s.alphaOverride));
    memcpy(s.xpan, copper.getXPanTexture(), sizeof(s.xpan));
    s.yFlip = copper.getYFlip();
    s.videoMode = gfx->getVideoMode();
}
