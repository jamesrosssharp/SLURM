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
#include <demo.h>
#include "pwm.h"
#include "rtos.h"
#include <bundle.h>

unsigned short sprite_palette[16];
unsigned short bg_palette[16];

char sine_table[256] = {
          0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 16, 17, 19, 20, 22, 23,
         24, 26, 27, 29, 30, 32, 33, 34, 36, 37, 38, 39, 41, 42, 43, 44,
         45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56, 57, 58, 59,
         59, 60, 60, 61, 61, 62, 62, 62, 63, 63, 63, 64, 64, 64, 64, 64,
         64, 64, 64, 64, 64, 64, 63, 63, 63, 62, 62, 62, 61, 61, 60, 60,
         59, 59, 58, 57, 56, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46,
         45, 44, 43, 42, 41, 39, 38, 37, 36, 34, 33, 32, 30, 29, 27, 26,
         24, 23, 22, 20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2,
          0, -2, -3, -5, -6, -8, -9,-11,-12,-14,-16,-17,-19,-20,-22,-23,
        -24,-26,-27,-29,-30,-32,-33,-34,-36,-37,-38,-39,-41,-42,-43,-44,
        -45,-46,-47,-48,-49,-50,-51,-52,-53,-54,-55,-56,-56,-57,-58,-59,
        -59,-60,-60,-61,-61,-62,-62,-62,-63,-63,-63,-64,-64,-64,-64,-64,
        -64,-64,-64,-64,-64,-64,-63,-63,-63,-62,-62,-62,-61,-61,-60,-60,
        -59,-59,-58,-57,-56,-56,-55,-54,-53,-52,-51,-50,-49,-48,-47,-46,
        -45,-44,-43,-42,-41,-39,-38,-37,-36,-34,-33,-32,-30,-29,-27,-26,
        -24,-23,-22,-20,-19,-17,-16,-14,-12,-11, -9, -8, -6, -5, -3, -2,
};

#define SPRITE_SHEET_ADDRESS_HI 0x1
#define SPRITE_SHEET_ADDRESS_LO 0x0000
#define SPRITE_SHEET_WORD_ADDRESS 0x8000

#define SPRITE_WIDTH 128
#define SPRITE_HEIGHT 75

int slurm_y;
int slurm_x;
unsigned char slurm_sin;
unsigned char bg_x_sin;
unsigned char bg_y_sin;

short pwm_red = 0;
short pwm_blue = 0;
short pwm_green = 0;

static mutex_t my_mutex = RTOS_MUTEX_INITIALIZER;

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_CODE_BASE);

static void my_vsync_handler()
{
	vtors->rtos_unlock_mutex_from_isr(&my_mutex);
	vtors->background_update();
}

void main(void)
{
	int i;
	int frame = 0;
	int sprites = 0;

	vtors->printf("Hello effect1 \r\n");

	// Load the sprite sheet

	vtors->storage_load_synch(slurm_sprite_flash_offset_lo, slurm_sprite_flash_offset_hi, 0, 0, SPRITE_SHEET_ADDRESS_LO, SPRITE_SHEET_ADDRESS_HI, (slurm_sprite_flash_size_lo>>1));
	vtors->storage_load_synch(slurm_sprite_pal_flash_offset_lo, slurm_sprite_pal_flash_offset_hi, 0, 0, (unsigned int)sprite_palette, 0, (sizeof(sprite_palette)>>1));

	slurm_y = 360 - (SPRITE_HEIGHT >> 1) + SPRITE_Y_FUDGE;
	slurm_x = 160 - (SPRITE_WIDTH >> 1) + SPRITE_X_FUDGE;
	sprites = vtors->sprite_display(0, SPRITE_SHEET_WORD_ADDRESS, SPRITE_STRIDE_256, SPRITE_WIDTH, SPRITE_HEIGHT, slurm_x, slurm_y);

	vtors->storage_load_synch(bg_tiles_flash_offset_lo, bg_tiles_flash_offset_hi, 0, 0, BG_TILES_ADDRESS_LO, BG_TILES_ADDRESS_HI, (bg_tiles_flash_size_lo>>1));
	vtors->storage_load_synch(bg_tilemap_flash_offset_lo, bg_tilemap_flash_offset_hi, 0, 0, BG_TILE_MAP_ADDRESS_LO, BG_TILE_MAP_ADDRESS_HI, (bg_tilemap_flash_size_lo>>1));
	vtors->storage_load_synch(bg_tilemap_pal_flash_offset_lo, bg_tilemap_pal_flash_offset_hi, 0, 0, (unsigned short)bg_palette, 0, (sizeof(bg_palette)>>1));

	vtors->load_palette(sprite_palette, 0, 16);
	
	// Add a vsync interrupt handler
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	for (i = 0; i < 16; i ++)
	{
		bg_palette[i] = (bg_palette[i] & 0xfff) | 0x0000;
	}

	vtors->__out(0x5f02, 1);
	
	vtors->load_palette(bg_palette, 16, 16);

	vtors->background_set(0, 
		    1, 
		    1,
		    0, 
		    0, 
		    BG_TILE_MAP_WORD_ADDRESS, 
		    BG_TILES_WORD_ADDRESS,
		    TILE_WIDTH_16X16,
		    TILE_MAP_STRIDE_64);

	vtors->background_update();

	while (frame < 256)
	{
		vtors->rtos_lock_mutex(&my_mutex);
		
		if (frame > 192)
		{
			vtors->__out(0x5d22, ((frame - 192) >> 2) * 0x1111U);
			vtors->pwm_set(((frame - 192)), ((frame - 192)), ((frame - 192)));
		}
		frame++;
	}

	vtors->__out(0x5d22, 0xffff);

	while (frame < 1000)
	{
		vtors->rtos_lock_mutex(&my_mutex);

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

					vtors->load_palette(bg_palette, 16, 16);
				}

				bg_x_sin += 2;
				bg_y_sin += 3;
			}
			vtors->sprite_set_x_y(0, slurm_x, slurm_y + (sine_table[slurm_sin] >> 3));
			slurm_sin += 2;
		}
		else if (frame > 300)
		{
			slurm_y-=4;
			vtors->sprite_set_x_y(0, slurm_x, slurm_y);
		}

		vtors->sprite_update_sprite(0);
		
		vtors->background_set_x_y(0, (sine_table[bg_x_sin]) + 256, (sine_table[bg_y_sin]) + 256);
	//	vtors->background_update();
	}

	// Outro

	frame = 0;

	while (frame < 64 + 60)
	{

		vtors->rtos_lock_mutex(&my_mutex);

		frame++;

		if (frame > 64)
			{
				slurm_y += 4;
				vtors->sprite_set_x_y(0, slurm_x, slurm_y);

			}
		else
		{
			for (i = 0; i < 16; i ++)
			{
				bg_palette[i] = (bg_palette[i] & 0xfff) | ((frame < (64)) ? (15 - (frame >> 2)) << 12 : 0x0000);
			}

			vtors->load_palette(bg_palette, 16, 16);
		
			vtors->sprite_set_x_y(0, slurm_x, slurm_y + (sine_table[slurm_sin] >> 3));
			slurm_sin += 2;
			bg_x_sin += 2;
			bg_y_sin += 3;
		}

		vtors->sprite_update_sprite(0);
		
		
		vtors->background_set_x_y(0, (sine_table[bg_x_sin]) + 256, (sine_table[bg_y_sin]) + 256);
	//	vtors->background_update();
	}

	// Fadeout

	frame = 0;	
	while (frame < 64)
	{
	
		vtors->rtos_lock_mutex(&my_mutex);

		//if (frame > 192)
		vtors->__out(0x5d22, (15 - (frame >> 2)) * 0x1111U);
		vtors->pwm_set((63 - frame - 192), (63 - frame - 192), (63 - frame - 192));
		frame++;

	}

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);
}



