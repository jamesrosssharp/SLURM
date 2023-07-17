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

short ray1_x_prestep[3] = {0, 0, 0};
short ray1_y_prestep[3] = {0, 0, 0};
short ray1_x_step[3] = {0, 0, 0};
short ray1_y_step[3] = {0, 0, 0};

short ray2_x_prestep[3] = {0, 0, 0};
short ray2_y_prestep[3] = {0, 0, 0};
short ray2_x_step[3] = {0, 0, 0};
short ray2_y_step[3] = {0, 0, 0};

unsigned char col1 = 0;
unsigned char col2 = 0;

short _x1[3]; 
short _y1[3]; 
short _x2[3]; 
short _y2[3]; 

int i = 0;

bool found1 = false;
bool found2 = false;

unsigned short d1 = 65535, d2 = 65535;

short one[3] = {1, 0, 0};

unsigned short fire_ray(unsigned short fb, unsigned short *px, unsigned short *py, unsigned short phi)
{

	bool up = false;
	bool right = false;

	_x1[2] = 0;
	_x1[0] = px[0];
	_x1[1] = px[1];

	_x2[2] = 0;
	_x2[0] = px[0];
	_x2[1] = px[1];

	_y1[2] = 0;
	_y1[0] = py[0];
	_y1[1] = py[1];

	_y2[2] = 0;
	_y2[0] = py[0];
	_y2[1] = py[1];
	


	if (phi < 256)
		up = true;

	if ((phi < 128) || (phi > 384))
		right = true;

	if ( up )
	{
		ray1_y_prestep[2] = -1;
		ray1_y_prestep[0] = -(short)py[0];
		ray1_y_prestep[1] = -1;

		ray1_x_prestep[2] = 0;
		ray1_x_prestep[0] = -ray1_y_prestep[0];
		ray1_x_prestep[1] = 0;

		mul_1616_1616_div65536(ray1_x_prestep, cot_lo(phi), cot_hi(phi));

		ray1_y_step[2] = -1;
		ray1_y_step[0] = 0;
		ray1_y_step[1] = -1;

		ray1_x_step[2] = 0;
  		ray1_x_step[0] = 0;
		ray1_x_step[1] = 1;

		mul_1616_1616_div65536(ray1_x_step, cot_lo(phi), cot_hi(phi));

	}
	else
	{
		ray1_y_prestep[2] = 0;
		ray1_y_prestep[0] = -(short)py[0];
		ray1_y_prestep[1] = 0;

		ray1_x_prestep[2] = 0;
		ray1_x_prestep[0] = -ray1_y_prestep[0];
		ray1_x_prestep[1] = -1;

		mul_1616_1616_div65536(ray1_x_prestep, cot_lo(phi), cot_hi(phi));

		ray1_y_step[2] = 0;
		ray1_y_step[0] = 0;
		ray1_y_step[1] = 1;

		ray1_x_step[2] = -1;
  		ray1_x_step[0] = 0;
		ray1_x_step[1] = -1;

		mul_1616_1616_div65536(ray1_x_step, cot_lo(phi), cot_hi(phi));

	}

	add_1616_1616(_x1, ray1_x_prestep);
	add_1616_1616(_y1, ray1_y_prestep);

	i = 0;

	col1 = 0;
	col2 = 0;

	while (i < 20)
	{
		if ((_x1[1] > 31) || (_y1[1] > 31) || _x1[2] || _y1[2] || (_x1[1] < 0) || (_y1[1] < 0)) 
			break;

		put_pixel(fb, get_player_xy(&_x1[0]) >> 2, get_player_xy(&_y1[0]) >> 2, 2);

		if (up)
			col1 = map_data[_y1[1] - 1][_x1[1]];
		else
			col1 = map_data[_y1[1]][_x1[1]];

		if (col1)
			break;

		i++;
		add_1616_1616(_x1, ray1_x_step);
		add_1616_1616(_y1, ray1_y_step);

	}	

	return 0;
} 

void raycast_render(unsigned short fb, unsigned short *px, unsigned short *py, unsigned short pang)
{

	short phi_start = pang - 40;
	short phi_end   = pang + 40;

	short phi = pang;

	
	int x, y;

	put_pixel(fb, get_player_xy(px) >> 2, get_player_xy(py) >> 2, 1);

/*	for (x = 0; x < 128; x++)
	{
		for (y = 0; y < 64; y++)
		{
			char col = map_data[y>>3][x>>3];
			put_pixel(fb, x, y, col);
		}
	}
*/	


	for (phi = phi_start; phi < phi_end; phi++)
	{
		unsigned short d = fire_ray(fb, px, py, phi & 0x1ff);

		//vtors->printf("Phi: %x d: %x\n", phi, d);		
	}

}
