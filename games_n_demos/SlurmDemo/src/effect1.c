/*

	SlurmDemo : A demo to show off SlURM16

effect1.c : scrolling SLURM logo + sprites

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

#include <slurminterrupt.h>
#include "sprite.h"
#include "background.h"
#include "demo.h"
#include "pwm.h"
#include "rtos.h"

extern short bg_palette[];

extern char sine_table[];

extern int slurm_y;
extern int slurm_x;
extern unsigned char slurm_sin;
extern unsigned char bg_x_sin;
extern unsigned char bg_y_sin;

short pwm_red = 0;
short pwm_blue = 0;
short pwm_green = 0;

static mutex_t my_mutex = RTOS_MUTEX_INITIALIZER;

static void my_vsync_handler()
{
	rtos_unlock_mutex_from_isr(&my_mutex);
}

void run_effect1(void)
{
	int i;
	int frame = 0;

	// Add a vsync interrupt handler
	rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	for (i = 0; i < 16; i ++)
	{
		bg_palette[i] = (bg_palette[i] & 0xfff) | 0x0000;
	}

	__out(0x5f02, 1);
	
	load_palette(bg_palette, 16, 16);

	background_set(0, 
		    1, 
		    1,
		    0, 
		    0, 
		    BG_TILE_MAP_WORD_ADDRESS, 
		    BG_TILES_WORD_ADDRESS,
		    TILE_WIDTH_16X16,
		    TILE_MAP_STRIDE_64);

	background_update();

	while (frame < 256)
	{
		rtos_lock_mutex(&my_mutex);
		
		if (frame > 192)
		{
			__out(0x5d22, ((frame - 192) >> 2) * 0x1111U);
			pwm_set(((frame - 192)), ((frame - 192)), ((frame - 192)));
		}
		frame++;
	}

	__out(0x5d22, 0xffff);


	while (frame < 1000)
	{
		rtos_lock_mutex(&my_mutex);

		my_printf(".");
	
		//if (frame < 1000)
		frame++;

		if (frame > 300 + 60)
		{
			if (frame > 450)
			{
				if (frame < 450 + 64 + 1)
				{
					for (i = 0; i < 16; i ++)
					{
						bg_palette[i] = (bg_palette[i] & 0xfff) | ((frame < (450+64)) ? ((frame - 450) >> 2) << 12 : 0xf000);
					}

					load_palette(bg_palette, 16, 16);
				}

				bg_x_sin += 2;
				bg_y_sin += 3;
			}
			sprite_set_x_y(0, slurm_x, slurm_y + (sine_table[slurm_sin] >> 3));
			slurm_sin += 2;
		}
		else if (frame > 300)
		{
			slurm_y-=4;
			sprite_set_x_y(0, slurm_x, slurm_y);
		}

		sprite_update_sprite(0);
		
		background_set_x_y(0, (sine_table[bg_x_sin]) + 256, (sine_table[bg_y_sin]) + 256);
		background_update();
	}

	// Outro

	frame = 0;

	while (frame < 64 + 60)
	{

		rtos_lock_mutex(&my_mutex);

		frame++;

		if (frame > 64)
			{
				slurm_y += 4;
				sprite_set_x_y(0, slurm_x, slurm_y);

			}
		else
		{
			for (i = 0; i < 16; i ++)
			{
				bg_palette[i] = (bg_palette[i] & 0xfff) | ((frame < (64)) ? (15 - (frame >> 2)) << 12 : 0x0000);
			}

			load_palette(bg_palette, 16, 16);
		
			sprite_set_x_y(0, slurm_x, slurm_y + (sine_table[slurm_sin] >> 3));
			slurm_sin += 2;
			bg_x_sin += 2;
			bg_y_sin += 3;
		}

		sprite_update_sprite(0);
		
		
		background_set_x_y(0, (sine_table[bg_x_sin]) + 256, (sine_table[bg_y_sin]) + 256);
		background_update();
	}

	// Fadeout

	frame = 0;	
	while (frame < 64)
	{
	
		rtos_lock_mutex(&my_mutex);

		//if (frame > 192)
		__out(0x5d22, (15 - (frame >> 2)) * 0x1111U);
		pwm_set((63 - frame - 192), (63 - frame - 192), (63 - frame - 192));
		frame++;

	}

	rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);
}



