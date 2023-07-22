/*

	SlurmDemo : A demo to show off SlURM16

tunnel.c : tunnel effect

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

#include "tunnel.h"
#include "effect6.h"
#include <applet.h>
#include <bundle.h>
#include <bool.h>
#include <rtos.h>

unsigned char distance_buffer[2][320];
unsigned char angle_buffer[2][320];
unsigned char shade_buffer[2][320];

unsigned char color_tab[16][16];

unsigned char texture[64][32];

#define WIDTH 80
#define HEIGHT 50

extern struct applet_vectors *vtors;

mutex_t distance_mutex = RTOS_MUTEX_INITIALIZER;
mutex_t angle_mutex = RTOS_MUTEX_INITIALIZER;
mutex_t shade_mutex = RTOS_MUTEX_INITIALIZER;

short sine_table[256] = {
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



void storage_cb(void* user_handle)
{
	mutex_t* mut = (mutex_t*)user_handle;

	//vtors->printf("Callback! %x\n", mut);	
	vtors->rtos_unlock_mutex(mut);
}

void tunnel_init()
{
	vtors->storage_load_synch(color_table_flash_offset_lo, color_table_flash_offset_hi, 0, 0, (unsigned int)color_tab, 0, (sizeof(color_tab)>>1));
	vtors->storage_load_synch(tunnel_texture2_flash_offset_lo, tunnel_texture2_flash_offset_hi, 0, 0, (unsigned int)texture, 0, (sizeof(texture)>>1));

	vtors->rtos_lock_mutex(&distance_mutex);
	vtors->rtos_lock_mutex(&angle_mutex);
	vtors->rtos_lock_mutex(&shade_mutex);
}

void load_table_row_synch(unsigned short buffer, unsigned short flash_lo, unsigned short flash_hi, unsigned short x, unsigned short y, unsigned short count_words)
{
	compute_flash_offset(&flash_lo, &flash_hi, x, y);

	vtors->storage_load_synch(flash_lo, flash_hi, 0, 0, (unsigned int)buffer, 0, count_words);
}

void load_table_row_asynch(unsigned short buffer, unsigned short flash_lo, unsigned short flash_hi, unsigned short x, unsigned short y, unsigned short count_words, mutex_t* mutex)
{
	compute_flash_offset(&flash_lo, &flash_hi, x, y);

	vtors->storage_load_asynch(flash_lo, flash_hi, 0, 0, (unsigned int)buffer, 0, count_words, storage_cb, mutex);
}



void render_tunnel(unsigned short fb, unsigned short frame)
{
	unsigned int y;

	unsigned int shiftX;
	unsigned int shiftY;

	unsigned int shiftU;
	unsigned int shiftV;

	bool buf_idx = 0; 

	//vtors->printf("render_tunnel!\r\n");

	// Compute shift values

	shiftU = frame << 2;
	shiftV = frame;

	shiftX = WIDTH + (sine_table[(frame << 2) & 255] >> 1);
	shiftY = (HEIGHT >> 1) + (sine_table[(frame << 1) & 255] >> 2);

	// Preload first row of each table

	load_table_row_synch((unsigned short)distance_buffer[0], distance_table_flash_offset_lo, distance_table_flash_offset_hi, shiftX, shiftY, 40);
	load_table_row_synch((unsigned short)angle_buffer[0], angle_table_flash_offset_lo, angle_table_flash_offset_hi, shiftX, shiftY, 40);
	load_table_row_synch((unsigned short)shade_buffer[0], shade_table_flash_offset_lo, shade_table_flash_offset_hi, shiftX, shiftY, 40);

	buf_idx = !buf_idx;

	// Loop for all Y, reloading each successive row

	for (y = 0; y < HEIGHT; y++)
	{
		unsigned char* b1, *b2, *b3;

		shiftY++;
		// Asynch load next row
		load_table_row_asynch((unsigned short)distance_buffer[buf_idx], distance_table_flash_offset_lo, distance_table_flash_offset_hi, shiftX, shiftY, 40, &distance_mutex);
		load_table_row_asynch((unsigned short)angle_buffer[buf_idx], angle_table_flash_offset_lo, angle_table_flash_offset_hi, shiftX, shiftY, 40, &angle_mutex);
		load_table_row_asynch((unsigned short)shade_buffer[buf_idx], shade_table_flash_offset_lo, shade_table_flash_offset_hi, shiftX, shiftY, 40, &shade_mutex);

		buf_idx = !buf_idx;
		
		// Render current row

		b1 = (unsigned char*)distance_buffer[buf_idx]; 
		b2 = (unsigned char*)angle_buffer[buf_idx];
		b3 = (unsigned char*)shade_buffer[buf_idx]; 

		if (shiftX & 1)
		{
			b1 ++;
			b2 ++;
			b3 ++;
		}	

		tunnel_render_asm(fb, b1, b2, b3, shiftU, shiftV);

		// Wait for IO
		vtors->rtos_lock_mutex(&distance_mutex);
		vtors->rtos_lock_mutex(&angle_mutex);
		vtors->rtos_lock_mutex(&shade_mutex);

		fb += 640;
	}

}
