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

#define SQUARE_MASK 0xfc00

unsigned short fire_ray(unsigned short fb, unsigned short *px, unsigned short *py, unsigned short phi)
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

	short x1[2]; 
	short y1[2]; 
	short x2[2]; 
	short y2[2]; 

	int i = 0;

	bool found1 = false;
	bool found2 = false;

	unsigned short d1 = 65535, d2 = 65535;

	x1[0] = px[0];
	x1[1] = px[1];
	x2[0] = px[0];
	x2[1] = px[1];
	y1[0] = py[0];
	y1[1] = py[1];
	y2[0] = py[0];
	y2[1] = py[1];
	
	if ((0 < phi) && (phi < 256))
		up = true;

	if ((phi > 384) || (phi < 128))
		right = true;

	/*
	// Fixed point: 6 (grid coord) : 5 (tile u,v) : 5 (frac)

	if (up)
	{
		short cot_phi = cot(phi);

		ray1_y_prestep = (py & SQUARE_MASK) - py;
		ray1_x_prestep = -mult_655_88_div8(ray1_y_prestep, cot_phi);
		ray1_y_step = - SQUARE_WIDTH_FRAC;
		ray1_x_step = mult_655_88_div8(SQUARE_WIDTH_FRAC, cot_phi);
	}
	else
	{
		short cot_phi = cot(phi);

		ray1_y_prestep = ((py & SQUARE_MASK) + SQUARE_WIDTH_FRAC) - py;
		ray1_x_prestep = -mult_655_88_div8(ray1_y_prestep, cot_phi);
		ray1_y_step = SQUARE_WIDTH_FRAC;
		ray1_x_step = -mult_655_88_div8(SQUARE_WIDTH_FRAC, cot_phi);

	}

	if (right)
	{
		short tan_phi = tan(phi);

		ray2_y_prestep = ((px & SQUARE_MASK) + SQUARE_WIDTH_FRAC) - px;
		ray2_x_prestep = -mult_655_88_div8(ray2_y_prestep, tan_phi);
		ray2_y_step = SQUARE_WIDTH_FRAC;
		ray2_x_step = -mult_655_88_div8(SQUARE_WIDTH_FRAC, tan_phi);
	}
	else
	{
		short tan_phi = tan(phi);

		ray2_y_prestep = ((px & SQUARE_MASK)) - px;
		ray2_x_prestep = -mult_655_88_div8(ray2_y_prestep, tan_phi);
		ray2_y_step = -SQUARE_WIDTH_FRAC;
		ray2_x_step = mult_655_88_div8(SQUARE_WIDTH_FRAC, tan_phi);
	
	}

	x1 += ray1_x_prestep;
	y1 += ray1_y_prestep;

	x2 += ray2_x_prestep;
	y2 += ray2_y_prestep;


	put_pixel(fb, px >> 8, py >> 8, 3);

	while ((i < 20) && (! found1) && (! found2))
	{
		while ((right && (x1 <= x2)) || (!right && (x1 >= x2)))
		{

			short map_x;
			short map_y;

			map_x = x1 & SQUARE_MASK;
			
			if (up)
			{
				map_y = (y1 - SQUARE_WIDTH_FRAC - 1) & SQUARE_MASK;
			}
			else
			{
				map_y = y1 & SQUARE_MASK;
			}

			if ((map_x > (31 << 10)) || (map_y > (31 << 10))) break;

			put_pixel(fb, map_x >> 8, map_y >> 8, 1);

			col1 = map_data[map_y >> 10][map_x >> 10];
			if (col1)
			{
				found1 = true;
			 	break;
			}

			x1 += ray1_x_step;
			y1 += ray1_y_step;
		} 


		while ((up && (y2 >= y1)) || (!up && (y2 <= y1)))
		{

			short map_x;
			short map_y;

			map_y = y2 & SQUARE_MASK;
			
			if (!right)
			{
				map_x = (x2 - SQUARE_WIDTH_FRAC - 1) & SQUARE_MASK;
			}
			else
			{
				map_y = y2 & SQUARE_MASK;
			}

			put_pixel(fb, map_x >> 8, map_y >> 8, 2);
			
			col2 = map_data[map_y >> 10][map_x >> 10];
			if (col2)
			{
				found2 = true;
			 	break;
			}

			x2 += ray2_x_step;
			y2 += ray2_y_step;
		} 

		i ++;
	}
	if (found1)
		d1 = cos(phi) * (x1 - px) - sin(phi) * (y1 - py);

	if (found2)
		d2 = cos(phi) * (x2 - px) - sin(phi) * (y2 - py);

	if (d1 < d2)
		return d1;
	else
		return d2;
 
*/

	return 0;
} 

void raycast_render(unsigned short fb, unsigned short *px, unsigned short *py, unsigned short pang)
{

	short phi_start = pang - 40;
	short phi_end   = pang + 40;

	short phi = pang;

	
	int x, y;

	put_pixel(fb, get_player_xy(px) >> 2, get_player_xy(py) >> 2, 1);

	for (x = 0; x < 128; x++)
	{
		for (y = 0; y < 64; y++)
		{
			char col = map_data[y>>3][x>>3];
			put_pixel(fb, x, y, col);
		}
	}
	


//	for (phi = phi_start; phi < phi_end; phi++)
	{
		unsigned short d = fire_ray(fb, px, py, phi & 0x1ff);

		//vtors->printf("Phi: %x d: %x\n", phi, d);		
	}

}
