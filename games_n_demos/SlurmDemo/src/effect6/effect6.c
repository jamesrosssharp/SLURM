/*

	SlurmDemo : A demo to show off SlURM16

effect6.c : tunnel effect

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

#include <background.h>
#include <demo.h>
#include <rtos.h>
#include <bool.h>
#include <slurminterrupt.h>
#include <copper.h>
#include "effect6.h"
#include <bundle.h>

#include "tunnel.h"

mutex_t eff6_mutex = RTOS_MUTEX_INITIALIZER;

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_CODE_BASE);

unsigned short tunnel_palette[16];

unsigned short frame = 0;

#define FRAME_BUFFER_WIDTH 320
#define FRAME_BUFFER_HEIGHT 200

/* these are the addresses of our two framebuffers in the upper two banks of memory -
	each frame buffer region is 256x128 pixels, 4bpp (rendered as sprites)
	and each is in a different bank so we can be writing to the back buffer
	as the front buffer is being displayed with no memory conflict.
 */
unsigned short framebuffers_upper_lo[] = {0x0000, 0x8000};

/* these are the word addresses of the framebuffers (for sprite hardware) */
unsigned short framebuffers_word_addr[] = {0x8000, 0xc000};

unsigned short cur_front_buffer = 0;

void clear_fb(unsigned short fb, unsigned short col_word);
void flip_buffer_spr(unsigned short fb);

volatile bool flip_buffer = 0;
volatile short vsync_count = 0;

static void my_vsync_handler()
{
	if (flip_buffer)
	{
		cur_front_buffer = !cur_front_buffer;
		flip_buffer_spr(framebuffers_word_addr[cur_front_buffer]);
		flip_buffer = 0;
		vtors->rtos_unlock_mutex_from_isr(&eff6_mutex);
	}
	vsync_count++;
}

short _mult_div_8_8(short a, short m, short d)
{

	bool neg = false;
	short v;

	if (a < 0)
	{
		neg = !neg;
		a = -a;
	}
	if (m < 0)
	{
		neg = !neg;
		m = -m;
	}
	if (d < 0)
	{
		neg = !neg;
		d = -d;
	}

	v = mult_div_8_8(a, m, d);

	if (neg)
		v = -v;

	return v;

}

void main(void)
{

	//vtors->storage_load_synch(brick_texture_flash_offset_lo, brick_texture_flash_offset_hi, 0, 0, (unsigned short)&texture_cache[0], 0, (brick_texture_flash_size_lo>>1));
	//vtors->storage_load_synch(brick_texture2_flash_offset_lo, brick_texture2_flash_offset_hi, 0, 0, (unsigned short)&texture_cache[1], 0, (brick_texture_flash_size_lo>>1));

	tunnel_init();

	vtors->storage_load_synch(tunnel_pal_flash_offset_lo, tunnel_pal_flash_offset_hi, 0, 0, (unsigned int)tunnel_palette, 0, (sizeof(tunnel_palette)>>1));
	
	vtors->copper_set_bg_color(0x0000);

	//vtors->copper_list_load(the_copper_list, sizeof(the_copper_list) / sizeof(the_copper_list[0]));
	//vtors->copper_control(1);

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	vtors->load_palette(tunnel_palette, 0, 16);
	// Create the sprite array

	clear_fb(framebuffers_upper_lo[0], 0x0000);
	clear_fb(framebuffers_upper_lo[1], 0x0000);
	
	vtors->sprite_display(0, framebuffers_word_addr[!cur_front_buffer], SPRITE_STRIDE_320, FRAME_BUFFER_WIDTH, FRAME_BUFFER_HEIGHT, 24, 35);
	vtors->sprite_update_sprite(0);

	vtors->rtos_lock_mutex(&eff6_mutex);
	while (frame < 300)
	{
		int i;

		enter_critical();
		flip_buffer = 1;
		vtors->rtos_lock_mutex(&eff6_mutex);
		leave_critical();
		frame++;
		
		//clear_fb(framebuffers_upper_lo[!cur_front_buffer], 0x1234);
		
		render_tunnel(framebuffers_upper_lo[!cur_front_buffer], frame);

		if ((frame & 0xf) == 0)
		{
			vtors->printf("FPS x100: %d\r\n", _mult_div_8_8(frame, 6000, vsync_count));
		}
	

	}
	
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);

	vtors->copper_control(0);
	vtors->copper_set_y_flip(0, 0xfff); 
	vtors->copper_set_alpha(0x0000);
	vtors->sprite_init_sprites();
	vtors->copper_set_bg_color(0x0000);
}

