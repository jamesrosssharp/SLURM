/*

	SlurmDemo : A demo to show off SlURM16

copper.h: Copper routines 

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

#ifndef COPPER_H
#define COPPER_H

void copper_control(short enable);
void copper_set_y_flip(short enable, short flip_y);
void copper_set_x_pan(short xpan);
void copper_set_bg_color(unsigned short color);
void copper_set_alpha(unsigned short alpha);

#define COPPER_JUMP(x)  (0x1000 | x)    // Jump to copper instruction address
#define COPPER_VWAIT(x) (0x2000 | x)    // Wait until V = x
#define COPPER_HWAIT(x) (0x3000 | x)	// Wait until H = x
#define COPPER_VSKIP(x) (0x4000 | x)	// Skip next instruction if V greater than
#define COPPER_HSKIP(x) (0x5000 | x)	// Skip next instruction if H greater than
#define COPPER_BG_WAIT(x) (0x6000 | x)  // Set BG color and wait next scanline
#define COPPER_VWAIT_N(x) (0x7000 | x)  // Wait for N scanlines
#define COPPER_HWAIT_N(x) (0x8000 | x)  // Wait for N columns
#define COPPER_WRITE_REG(x) (0x9000 | x) // Write register x (register data follows)
#define COPPER_XPAN(x)	  (0xa000 | x)   // set x panning register
#define COPPER_XPAN_WAIT(x) (0xb000 | x) // set x panning register and wait next scanline
#define COPPER_BG(x)	(0xc000 | x)     // Set BG color
#define COPPER_ALPHA(x)	(0xd000 | x)     // Write global alpha register 

#endif
