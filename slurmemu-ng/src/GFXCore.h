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

#pragma once

#include <cstdint>
#include <thread>
#include <semaphore>

#include "Copper.h"
#include "BackgroundController.h"
#include "GFXConst.h"
#include "SpriteController.h"

class GFXCore {

    public:

        GFXCore();
        ~GFXCore();

        std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val); 
   
        void step(std::uint16_t* mem, bool& hs_int, bool& vs_int);

        std::uint8_t* getCopperBG() { return m_copper.getCopperBG(); }
        std::uint8_t* getBG0Texture() { return m_bg.getBG0Texture(); }
        std::uint8_t* getBG1Texture() { return m_bg.getBG1Texture(); }
        std::uint16_t* getPaletteTexture() { return m_paletteTexture; }

        static constexpr int kVideoMode320x240 = 1;
        static constexpr int kVideoMode640x480 = 0;

        const BackgroundController& getBGCon() const { return m_bg; }
        const SpriteController& getSpCon() const { return m_sp; }
        const Copper& getCopper() const { return m_copper; }

        float getVideoMode() const { if (m_videoMode == kVideoMode320x240) return 1.0; else return 0.0; }  

    private:

        static void bg0_render_th(void* gfx);
        static void bg1_render_th(void* gfx);
        void bg0_render_loop();
        void bg1_render_loop();

        std::uint16_t m_x;
        std::uint16_t m_y;

        Copper m_copper; 
   
        int m_videoMode;  

        std::thread m_bg0_renderer;
        std::binary_semaphore m_bg0_sem;
        std::thread m_bg1_renderer;
        std::binary_semaphore m_bg1_sem;

        std::uint16_t m_y_thread;
        std::uint16_t m_y_thread_actual;
        std::uint16_t* m_mem_thread;

        BackgroundController m_bg;

        static constexpr int kPaletteSize = 256;
        std::uint16_t m_palette[kPaletteSize];
        std::uint16_t m_paletteTexture[TOTAL_Y * kPaletteSize];

        SpriteController m_sp;

};
