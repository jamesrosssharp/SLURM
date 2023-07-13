/*

	SlurmDemo : A demo to show off SlURM16

raycast.c : raycasting demo renderer

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

#include "raycast.h"
#include "map.h"
#include "trig.h"

#include <applet.h>

extern struct applet_vectors *vtors;

#define SQUARE_WIDTH 32
#define SQUARE_WIDTH_FRAC 1024
#define SQUARE_SHIFT 5

unsigned short fire_ray(unsigned short px, unsigned short py, unsigned short phi)
{

	bool up = false;
	bool right = false;

	short ray1_x_prestep = 0;
	short ray1_y_prestep = 0;
	short ray1_x_step = 0;
	short ray1_y_step = 0;

	short ray2_x_prestep = 0;
	short ray2_y_prestep = 0;
	short ray2_x_step = 0;
	short ray2_y_step = 0;

	unsigned char col1 = 0;
	unsigned char col2 = 0;

	short x1 = px;
	short y1 = py;
	short x2 = px;
	short y2 = py;


	if ((0 < phi) && (phi < 256))
		up = true;

	if ((phi > 384) || (phi < 128))
		right = true;

	// Fixed point: 6 (grid coord) : 5 (tile u,v) : 5 (frac)

	if (up)
	{
		short cot_phi = cot(phi);

		ray1_y_prestep = (py & 0xfc00) - py;
		ray1_x_prestep = -mult_655_88_div8(ray1_y_prestep, cot_phi);
		ray1_y_step = - SQUARE_WIDTH_FRAC;
		ray1_x_step = mult_655_88_div8(SQUARE_WIDTH_FRAC, cot_phi);
	}
	else
	{
		short cot_phi = cot(phi);

		ray1_y_prestep = ((py & 0xfc00) + SQUARE_WIDTH_FRAC) - py;
		ray1_x_prestep = -mult_655_88_div8(ray1_y_prestep, cot_phi);
		ray1_y_step = SQUARE_WIDTH_FRAC;
		ray1_x_step = -mult_655_88_div8(SQUARE_WIDTH_FRAC, cot_phi);

	}

	if (right)
	{
		short tan_phi = tan(phi);

		ray2_y_prestep = ((px & 0xfc00) + SQUARE_WIDTH_FRAC) - px;
		ray2_x_prestep = -mult_655_88_div8(ray2_y_prestep, tan_phi);
		ray2_y_step = SQUARE_WIDTH_FRAC;
		ray2_x_step = -mult_655_88_div8(SQUARE_WIDTH_FRAC, tan_phi);
	}
	else
	{
		short tan_phi = tan(phi);

		ray2_y_prestep = ((px & 0xfc00)) - px;
		ray2_x_prestep = -mult_655_88_div8(ray2_y_prestep, tan_phi);
		ray2_y_step = -SQUARE_WIDTH_FRAC;
		ray2_x_step = mult_655_88_div8(SQUARE_WIDTH_FRAC, tan_phi);
	
	}




} 

void raycast_render(unsigned short fb, unsigned short px, unsigned short py, unsigned short pang)
{

	short phi_start = pang - 40;
	short phi_end   = pang + 40;

	short phi = pang;

//	for (phi = phi_start; phi < phi_end; phi++)
	{
		unsigned short d = fire_ray(px, py, phi & 0x1ff);

		vtors->printf("Phi: %x d: %x\n", phi, d);		
	}

}
