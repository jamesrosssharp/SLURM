/* vim: set et ts=4 sw=4: */

/*
		slurmemu-ng : Next-Generation SlURM16 Emulator

Copper.h : Emulate copper

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

enum CopperState {
	COPPER_IDLE,
	COPPER_BEGIN,
	COPPER_EXECUTE,
	COPPER_WAITV,
	COPPER_WAITH,
	COPPER_WRITEREG,
};

class Copper {

public:

    Copper();

    std::uint16_t port_op(std::uint16_t port, bool write, std::uint16_t wr_val); 
   
    void step(std::uint16_t* mem, uint16_t x1, uint16_t y1, uint16_t x_in, uint16_t y_in, uint16_t& x, uint16_t& y, bool vs);

    std::uint8_t* getCopperBG() { return m_copperBG; }

private:

    void execute(int x, int y); 
    void begin();
    void wait_hv(std::uint16_t hv);

    bool m_enable;

    static constexpr int kCopperListSize = 512;
    std::uint16_t m_copperList[kCopperListSize];

    std::uint16_t m_copper_pc;
    enum CopperState m_state;

    /* background color */
    std::uint8_t m_r, m_g, m_b;

    std::uint16_t m_regAddr;
    std::uint16_t m_hvWait;
    std::uint16_t m_yFlip;
    bool          m_yFlipEn;

    std::uint16_t m_xPan;

    std::uint8_t  m_globalAlpha;
    bool          m_alphaOverride; 

    std::uint8_t m_copperBG[800*525*4];
};

