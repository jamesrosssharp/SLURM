/*

background.h: Routines for programming the background hardware

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

#ifndef BACKGROUND_H
#define BACKGROUND_H

enum TileWidth {
	TILE_WIDTH_16X16 = 0,
	TILE_WIDTH_8X8 = 1
};

enum TileMapStride {
	TILE_MAP_STRIDE_256 = 0,
	TILE_MAP_STRIDE_128 = 1,
	TILE_MAP_STRIDE_64 = 2,
	TILE_MAP_STRIDE_32 = 3
}; 

void background_init();
void background_set(int bg_idx, 
		    unsigned char enable, 
		    unsigned char palette,
		    short x, 
		    short y, 
		    unsigned short tilemap_address, 
		    unsigned short tileset_address,
		    enum TileWidth tile_width,
		    enum TileMapStride tile_stride);

void background_set_x_y(int bg_idx, short x, short y);
void background_update();

#endif
