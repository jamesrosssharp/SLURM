/*

	SlurmDemo : A demo to show off SlURM16

main.c: Main function

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


#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

#include <bundle.h>

#include "printf.h"
#include "music.h"
#include "flash_control.h"
#include "sprite.h"

volatile short flash_complete 	= 0;
volatile short vsync 		= 0;
volatile short audio 		= 0;

#define SPRITE_SHEET_ADDRESS 0x8000
#define SPRITE_WIDTH 128
#define SPRITE_HEIGHT 75

#define SPRITE_X_FUDGE 16
#define SPRITE_Y_FUDGE 8

void enable_interrupts()
{
	__out(0x7000, SLURM_INTERRUPT_VSYNC | SLURM_INTERRUPT_FLASH_DMA | SLURM_INTERRUPT_AUDIO);
	global_interrupt_enable();
}

unsigned short sprite_palette[16] = { 0x0555, 0x0333, 0x0333, 0x0333};

int main()
{
	int sprites = 0;

	__out(0x5f02, 1);
	
	my_printf("Hello world Slurm Demo!\n");

	enable_interrupts();
	init_music_player();
	sprite_init_sprites();
	
	// Load the sprite sheet

	do_flash_dma_full_address(slurm_sprite_flash_offset_lo, slurm_sprite_flash_offset_hi, 0, 0, (void*)SPRITE_SHEET_ADDRESS, (slurm_sprite_flash_size_lo>>1) - 1);
	do_flash_dma(slurm_sprite_pal_flash_offset_lo, slurm_sprite_pal_flash_offset_hi, 0, 0, sprite_palette, (sizeof(sprite_palette)>>1) - 1);

	// Display the sprite

	load_palette(sprite_palette, 0, 16);
	sprites = sprite_display(0, SPRITE_SHEET_ADDRESS, SPRITE_STRIDE_256, SPRITE_WIDTH, SPRITE_HEIGHT, 160 - (SPRITE_WIDTH >> 1) + SPRITE_X_FUDGE, 120 - (SPRITE_HEIGHT >> 1) + SPRITE_Y_FUDGE);

	while (1)
	{
		if (audio)
		{
			chip_tune_play();
			audio = 0;
		}
		__sleep();
	}

	return 0;
}
