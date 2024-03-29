/*

	SlurmDemo : A demo to show off SlURM16

raycast.h : raycasting demo renderer

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

#ifndef RAYCAST_H
#define RAYCAST_H

void raycast_render(unsigned short fb, unsigned short* px, unsigned short* py, unsigned short pang);

/* raycast.asm routines */
extern void mul_1616_1616_div65536(short*, short, short);
extern void add_1616_1616(short *a, short *b);
extern unsigned short calculate_distance(unsigned short phi, unsigned short* px, unsigned short* py, short* x1, short* y1);			 
 
extern void draw_vline(unsigned short fb, unsigned short y1, unsigned short y2, unsigned short col);
extern void draw_textured_vline(unsigned short fb, unsigned short y1, unsigned short y2, unsigned short texture_u, unsigned short texture_p);

extern unsigned short height_table[];

#endif
