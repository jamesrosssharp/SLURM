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

void triangle_rasterize(unsigned short framebuffer, struct Vertex* v0, struct Vertex* v1, struct Vertex* v2, unsigned short color)
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

	short y_end = 0;

	struct Vertex* top;
	struct Vertex* middle;
	struct Vertex* bottom;

	short middleCompare = 0;
	short bottomCompare = 0;


	if (v0->sy < v1->sy)
	{
		if (v2->sy < v0->sy)
		{
			top = v2; 
			middle = v0;
			bottom = v1;	
			middleCompare = 0;
			bottomCompare = 1; 
		}  
		else
		{
			top = v0;

			if (v1->sy < v2->sy)
			{
				middle = v1;
				bottom = v2;
				middleCompare = 1;
				bottomCompare = 2; 		
			}
			else
			{
				middle = v2;
				bottom = v1;
				middleCompare = 2;
				bottomCompare = 1; 		
			}  

		}

	}
	else
	{
		if (v2->sy < v1->sy)
		{
			top = v2; 
			middle = v1;
			bottom = v0;	
			middleCompare = 1;
			bottomCompare = 0; 
		} 
		else
		{
			top = v1;
			
			if (v0->sy < v2->sy)
			{
				middle = v0;
				bottom = v2;
				middleCompare = 3;
				bottomCompare = 2; 		
			}
			else
			{
				middle = v2;
				bottom = v0;
				middleCompare = 2;
				bottomCompare = 3; 		
			}  
		}
	} 

	if (bottomCompare < middleCompare)
	{
		midOnLeft = false;
	}
	else
	{
		midOnLeft = true;
	}


	// Compute gradients

	if (bottom->sy == top->sy) return; // zero-height

	if ((middle->sy != top->sy) && (middle->sy != bottom->sy))
	{
		dxDy12 = _mult_div_8_8(middle->sx - top->sx, 0x10, middle->sy - top->sy);
		dxDy13 = _mult_div_8_8(bottom->sx - top->sx, 0x10, bottom->sy - top->sy);
		dxDy23 = _mult_div_8_8(bottom->sx - middle->sx, 0x10, bottom->sy - middle->sy);
	}
	else if (middle->sy != bottom->sy)
	{
		dxDy12 = 0;
		dxDy13 = _mult_div_8_8(bottom->sx - top->sx, 0x10, bottom->sy - top->sy);
		dxDy23 = _mult_div_8_8(bottom->sx - middle->sx, 0x10, bottom->sy - middle->sy);
	}
	else
	{
		dxDy12 = _mult_div_8_8(middle->sx - top->sx, 0x10, middle->sy - top->sy);
		dxDy13 = _mult_div_8_8(bottom->sx - top->sx, 0x10, bottom->sy - top->sy);
		dxDy23 = 0;
	}

	y = top->sy;
	yPrestep = ((y + 0xf) & 0xfff0) - y;

	if (midOnLeft)
	{
		x1 = (top->sx) + mult_8_8_div_16(yPrestep, dxDy12);
		x2 = (top->sx) + mult_8_8_div_16(yPrestep, dxDy13);
	}
	else
	{
		x1 = (top->sx) + mult_8_8_div_16(yPrestep, dxDy13);
		x2 = (top->sx) + mult_8_8_div_16(yPrestep, dxDy12);
	}


	y += yPrestep;

	framebuffer += 8*y;

	y_end = ((middle->sy + 0xf) & 0xfff0); 

	while (y < y_end)
	{
		short sx, sx2, sy;
		int j;

		sx = (x1 + 15) >> 4;
		sy = y >> 4;
		sx2 = (x2 + 15) >> 4;

		if (sx < sx2)
			draw_scanline(framebuffer, sx, sx2 - sx, color);
		framebuffer += 128;

		if (midOnLeft)
		{
			x1 += dxDy12;
			x2 += dxDy13;
		}
		else
		{
			x1 += dxDy13;
			x2 += dxDy12;	
		}

		y+=16;
	}

	y = middle->sy;
	yPrestep = ((y + 0xf) & 0xfff0) - y;

	if (midOnLeft)
		x1 = (middle->sx) + mult_8_8_div_16(yPrestep, dxDy23);
	else
		x2 = (middle->sx) + mult_8_8_div_16(yPrestep, dxDy23);

	y += yPrestep;

	y_end = ((bottom->sy + 0xf) & 0xfff0); 

	while (y < y_end)
	{
		short sx, sx2, sy;
		int j;

		sx = (x1 + 15) >> 4;
		sy = y >> 4;
		sx2 = (x2 + 15) >> 4;

		if (sx < sx2)
			draw_scanline(framebuffer, sx, sx2 - sx, color);
		
		framebuffer += 128;

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
		y+=16;
	}

}
	
