/*

	SlurmDemo : A demo to show off SlURM16

tunnel.h : tunnel effect

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

#ifndef TUNNEL_H
#define TUNNEL_H

void render_tunnel(unsigned short fb, unsigned short frame);

extern void compute_flash_offset(unsigned short* flash_lo, unsigned short* flash_hi, unsigned short x, unsigned short y);
extern void tunnel_render_asm(unsigned short fb, unsigned char* distance_buffer, unsigned char* angle_buffer, unsigned char* shade_buffer, unsigned short shiftU, unsigned short shiftV );

void tunnel_init();

#endif
