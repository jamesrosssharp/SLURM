/*

	SlurmDemo : A demo to show off SlURM16

effect3.c : plasma

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

#include "background.h"
#include "demo.h"

extern short vsync;
extern short audio;

// 64x64 : 4kbytes
#define PLASMA_FRAMEBUFFER 0x7000

extern short bg_palette[];

extern void asm_plasma(unsigned char* fb);

void run_effect3(void)
{
	int frame = 0;
	int i;

	for (i = 0; i < 16; i ++)
	{
		bg_palette[i] = (bg_palette[i] & 0xfff) | 0xf000;
	}

	//__out(0x5f02, 0);
	
	load_palette(bg_palette, 16, 16);


	background_set(0, 
		    1, 
		    1,
		    0, 
		    0, 
		    PLASMA_FRAMEBUFFER, 
		    BG_TILES_ADDRESS + 16*256,
		    TILE_WIDTH_8X8,
		    TILE_MAP_STRIDE_64);

	
	background_set_x_y(0, 0, 0);

	background_update();

	while (frame < 1000)
	{

		while (audio || vsync)
		{
			if (audio)
			{
				chip_tune_play();
				audio = 0;
			}

			if (vsync)
			{
			   if (!(frame & 1))
			   {
				int x, y;
				unsigned char* fb = (unsigned char*)(PLASMA_FRAMEBUFFER * 2);

				asm_plasma(fb);

				//for (y = 0; y < 64; y++)
				//	for (x = 0; x < 30; x++)
			
				//		*fb++ = ((x + y + frame) & 0xf) + 48;
			   }
			   vsync = 0;
			   frame++;
			}
		}

		__sleep();
	}

}


