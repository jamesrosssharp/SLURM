/*

	SlurmDemo : A demo to show off SlURM16

copper.c: Copper routines 

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

#include "copper.h"

#define COPPER_CTL 	0x5d20
#define COPPER_Y_FLIP 	0x5d21
#define COPPER_BGCOLOR  0x5d22
#define COPPER_XPAN	0x5d23
#define COPPER_ALPHA	0x5d24
#define COPPER_LIST_RAM 0x5400

/* Set copper control settings */
void copper_control(short enable)
{
	__out(COPPER_CTL, enable);
}

void copper_set_y_flip(short enable, short flip_y)
{
	__out(COPPER_Y_FLIP, (enable << 15) | (flip_y));   
}

void copper_set_x_pan(short xpan)
{
	__out(COPPER_XPAN, xpan);
}

void copper_set_bg_color(unsigned short color)
{
	__out(COPPER_BGCOLOR, color);
}

void copper_set_alpha(unsigned short alpha)
{
	__out(COPPER_ALPHA, alpha);
}

