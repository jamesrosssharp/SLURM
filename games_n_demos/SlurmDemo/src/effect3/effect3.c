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
#include "rtos.h"

#include <slurminterrupt.h>

// 64x64 : 4kbytes - keep this in sync with the asm
#define PLASMA_FRAMEBUFFER_WORD 0x8000

extern short bg_palette[];

extern unsigned short asm_plasma();

unsigned short plasma_palette[] = {
	0xf001,	0xf004, 0xf008, 0xf00a,
	0xf00d, 0xf02d, 0xf04d, 0xf06d,
	0xf0ad, 0xf0df, 0xf2d0, 0xf4d0,
	0xfad0, 0xff22, 0xff44, 0xff88
	
};

mutex_t eff3_mutex = RTOS_MUTEX_INITIALIZER;

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_CODE_BASE);

static void my_vsync_handler()
{
	vtors->rtos_unlock_mutex_from_isr(&eff3_mutex);
}

void main(void)
{
	int frame = 0;
	int i;

	vtors->copper_set_bg_color(0x0000);
	vtors->load_palette(plasma_palette, 16, 16);

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	vtors->background_set(0, 
		    1, 
		    1,
		    0, 
		    0, 
		    PLASMA_FRAMEBUFFER_WORD, 
		    BG_TILES_WORD_ADDRESS + 16*256,
		    TILE_WIDTH_8X8,
		    TILE_MAP_STRIDE_64);

	
	vtors->background_set_x_y(0, 0, 0);

	vtors->background_update();

	while (frame < 1000)
	{

		unsigned char* fb;
		unsigned short idx;	
		unsigned short col;	

		vtors->rtos_lock_mutex(&eff3_mutex);

		idx = asm_plasma();
		col = plasma_palette[idx >> 4];

		vtors->pwm_set((col & 0xf00) >> 6, (col & 0xf0) >> 2, (col & 0xf) << 2);

		frame++;
	}

	vtors->background_set(0, 
		    0, 
		    0,
		    0, 
		    0, 
		    0, 
		    0,
		    0,
		    0);
	
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);

}


