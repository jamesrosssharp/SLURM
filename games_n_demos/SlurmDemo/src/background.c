/*

background.c: Routines for programming the background hardware

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "background.h"

struct background {
	unsigned char enable;
	unsigned char palette;
	short x;
	short y;
	unsigned short tilemap_address;
	unsigned short tileset_address;
	unsigned char tile_width;
	unsigned char tile_stride;	
};

struct background bg_arr[2];

void background_init()
{
	int i;

	for (i = 0; i < 2; i++)
	{
		bg_arr[i].enable = 0;
	}
}

void background_set(int bg_idx, 
		    unsigned char enable, 
		    unsigned char palette,
		    short x, 
		    short y, 
		    unsigned short tilemap_address, 
		    unsigned short tileset_address,
		    enum TileWidth tile_width,
		    enum TileMapStride tile_stride)
{
	//if ((bg_idx < 0) || (bg_idx >= 2))
	//	return;

	struct background* bg = &bg_arr[bg_idx];

	bg->enable = enable;
	bg->palette = palette;
	bg->x = x;
	bg->y = y;
	bg->tilemap_address = tilemap_address;
	bg->tileset_address = tileset_address;
	bg->tile_width = (unsigned char) tile_width;
	bg->tile_stride = (unsigned char) tile_stride;

}	    
	
void background_set_x_y(int bg_idx, short x, short y)
{
	//if (bg_idx < 0 || bg_idx >= 2)
	//	return;

	struct background* bg = &bg_arr[bg_idx];

	bg->x = x;
	bg->y = y;

}

#define BG_CON_0_BASE 0x5d00 
#define BG_CON_1_BASE 0x5d05 

#define BG_CON_CTL 0
#define BG_CON_X 1
#define BG_CON_Y 2
#define BG_CON_MAP_ADDRESS 3
#define BG_CON_SET_ADDRESS 4

void background_update()
{
	int i;
	struct background* bg = bg_arr;
	unsigned short regs = BG_CON_0_BASE;

	for (i = 0; i < 2; i++)
	{
		short ctl = 0;
		ctl = (bg->enable & 1)  | ((bg->palette & 0xf) << 4) |
		      ((bg->tile_width & 1) << 15) |
		      ((bg->tile_stride & 3) << 8);
		__out(regs++, ctl);
		__out(regs++, bg->x);
		__out(regs++, bg->y);
		__out(regs++, bg->tilemap_address);
		__out(regs++, bg->tileset_address);
	}

}


