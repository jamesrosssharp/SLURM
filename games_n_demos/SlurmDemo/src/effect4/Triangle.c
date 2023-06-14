/*

	SlurmDemo : A demo to show off SlURM16

Triangle.c : triangle rasterization

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

#include "Triangle.h"
#include <bool.h>

void triangle_rasterize(unsigned short framebuffer, struct Vertex* v1, struct Vertex* v2, struct Vertex* v3, unsigned short color)
{

	// Sort vertices
	struct Vertex* t;
	short dxDy12 = 0;
	short dxDy13 = 0;
	short dxDy23 = 0;
	bool midOnLeft  = false;
	short y 	= 0;
	short yPrestep  = 0;	
	short x1 	= 0;
	short x2 	= 0;

	if (v1->sy > v2->sy)
	{
		t = v1;
		v1 = v2;
		v2 = t;
	} 

	if (v2->sy > v3->sy)
	{
		t = v2;
		v2 = v3;
		v3 = t;
	} 

	if (v1->sy > v2->sy)
	{
		t = v1;
		v1 = v2;
		v2 = t;
	} 

	// Compute gradients

	if (v3->sy == v2->sy) return; // zero-height

	if ((v2->sy != v1->sy) && (v2->sy != v3->sy))
	{
		dxDy12 = _mult_div_8_8(v2->sx - v1->sx, 0x10, v2->sy - v1->sy);
		dxDy13 = _mult_div_8_8(v3->sx - v1->sx, 0x10, v3->sy - v1->sy);
		dxDy23 = _mult_div_8_8(v3->sx - v2->sx, 0x10, v3->sy - v2->sy);
	}
	else if (v2->sy != v3->sy)
	{
		dxDy12 = 0;
		dxDy13 = _mult_div_8_8(v3->sx - v1->sx, 0x10, v3->sy - v1->sy);
		dxDy23 = _mult_div_8_8(v3->sx - v2->sx, 0x10, v3->sy - v2->sy);
	}
	else
	{
		dxDy12 = 0;
		dxDy13 = _mult_div_8_8(v3->sx - v1->sx, 0x10, v3->sy - v1->sy);
		dxDy23 = _mult_div_8_8(v3->sx - v2->sx, 0x10, v3->sy - v2->sy);
	}

	//if (_mult_div_8_8(v2->sy - v1->sy, dxDy13, 0x1) + v1->sx > v2->sx)	
	//	midOnLeft = true;

	y = v1->sy;
	yPrestep = ((y + 0xf) & 0xfff0) - y;

	x1 = (v1->sx<<4) + _mult_div_8_8(yPrestep, dxDy12, 0x1);
	x2 = (v1->sx<<4) + _mult_div_8_8(yPrestep, dxDy13, 0x1);

	y += yPrestep;

	while (y < (v2->sy))
	{
		short sx, sy;

		sx = (x1 + 128) >> 8;
		sy = y >> 4;

		put_pixel(framebuffer, sx, sy);

		sx = (x2 + 128) >> 8;
		put_pixel(framebuffer, sx, sy);

		x1 += dxDy12;
		x2 += dxDy13;
		y++;
	}

	if (x1 < x2)
		midOnLeft = true;
	else
	{
		short tt;
		tt = x1;
		x1 = x2;
		x2 = tt;
	}

	y = v2->sy;
	yPrestep = ((y + 0xf) & 0xfff0) - y;

	if (midOnLeft)
		x1 = (v2->sx<<4) + _mult_div_8_8(yPrestep, dxDy23, 0x1);
	else
		x2 = (v2->sx<<4) + _mult_div_8_8(yPrestep, dxDy23, 0x1);

	y += yPrestep;

	while (y < (v3->sy))
	{
		short sx, sy;

		sx = (x1 + 128) >> 8;
		sy = y >> 4;

		put_pixel(framebuffer, sx, sy);

		sx = (x2 + 128) >> 8;
		put_pixel(framebuffer, sx, sy);

		if (midOnLeft)
		{
			x1 += dxDy23;
			x2 += dxDy13;
		}
		else
		{
			x1 += dxDy13;
			x2 += dxDy23;
		}
		y++;
	}

}
	
