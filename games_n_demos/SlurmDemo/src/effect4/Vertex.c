/*

	SlurmDemo : A demo to show off SlURM16

Vertex.c : vertex routines

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

#include "Vertex.h"

#include <bool.h>

extern short dot4_8_8(short* a, short* b, short ainc, short binc);
extern short mult_div_8_8(short a, short m, short d);

void vertex_multiply_matrix(struct Vertex* v, struct Matrix4* mat)
{

	short x1 = dot4_8_8(&mat->x1, &v->x, 2, 2);
	short y1 = dot4_8_8(&mat->x2, &v->x, 2, 2);
	short z1 = dot4_8_8(&mat->x3, &v->x, 2, 2);
	short w1 = dot4_8_8(&mat->x4, &v->x, 2, 2);

	v->x = x1;
	v->y = y1;
	v->z = z1;
	v->w = w1;

}

short _mult_div_8_8(short a, short m, short d)
{

	bool neg = false;
	short v;

	if (a < 0)
	{
		neg = !neg;
		a = -a;
	}
	if (m < 0)
	{
		neg = !neg;
		m = -m;
	}
	if (d < 0)
	{
		neg = !neg;
		d = -d;
	}

	v = mult_div_8_8(a, m, d);

	if (neg)
		v = -v;

	return v;

}

void vertex_project(struct Vertex* v)
{

	/*
	self.screen.x = (self.pos.x / self.pos.w) * width / 2 + width / 2
        self.screen.y = (self.pos.y / self.pos.w) * height / 2 + height / 2
	*/

	#define W_DIV_2 0x800 // 12:4 fixed point format
	#define H_DIV_2 0x400

	// Screen coordinates are in 12:4 fixed point format 
	v->sx = _mult_div_8_8(v->x, W_DIV_2, v->w) + W_DIV_2;
	v->sy = _mult_div_8_8(v->y, H_DIV_2, v->w) + H_DIV_2;

}


