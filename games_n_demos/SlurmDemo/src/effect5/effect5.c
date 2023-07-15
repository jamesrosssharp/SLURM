/*

	SlurmDemo : A demo to show off SlURM16

effect4.c : raycasting demo

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
#include "effect5.h"
#include "map.h"
#include <bundle.h>

unsigned short the_copper_list[] = {
	COPPER_ALPHA(0xf),
	COPPER_BG(0x0aaf),
	COPPER_VWAIT(50),
	COPPER_BG(0x099f),
	COPPER_VWAIT(80),
	COPPER_BG(0x088f),
	COPPER_VWAIT(100),
	COPPER_BG(0x077f),
	COPPER_VWAIT(110),
	COPPER_BG(0x066f),
	COPPER_VWAIT(120),
	COPPER_BG(0x055f),
	COPPER_VWAIT(130),
	COPPER_BG(0x044f),
	COPPER_VWAIT(140),
	COPPER_BG(0x033f),
	COPPER_VWAIT(150),
	COPPER_ALPHA(0x4),
	COPPER_BG(0x0fff),
	COPPER_VWAIT(152),
	COPPER_BG(0x0aaa),
	COPPER_VWAIT(160),
	COPPER_BG(0x0888),
	COPPER_VWAIT(180),
	COPPER_BG(0x0666),
	COPPER_VWAIT(210),
	COPPER_BG(0x0555),
	COPPER_VWAIT(240),
	COPPER_BG(0x0333),
	COPPER_VWAIT(0xfff)
};

mutex_t eff5_mutex = RTOS_MUTEX_INITIALIZER;

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_CODE_BASE);

unsigned short ray_palette[] = {
	0x0000,	0xff00, 0xf0f0, 0xf00f,
	0xffff, 0xf811, 0xf922, 0xfa22,
	0xfb33, 0xfc33, 0xfd44, 0xfe44,
	0xff66, 0xff88, 0xffaa, 0xffff	
};



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
		vtors->rtos_unlock_mutex_from_isr(&eff5_mutex);
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

#include "raycast.h"

unsigned short px[2] = {32768, 1};
unsigned short py[2] = {32768, 1};
unsigned short pang = 0;

#define UP_KEY 1
#define DOWN_KEY 2
#define LEFT_KEY 4
#define RIGHT_KEY 8
#define A_KEY 16
#define B_KEY 32

#include "trig.h"

void poll_gpios()
{
	short keys = vtors->__in(0x1001);

	if (keys & UP_KEY)
	{
		move_player_forward(px, py, pang);
		if (map_data[py[1]][px[1]])
			move_player_backward(px, py, pang);
	}
	if (keys & DOWN_KEY)
	{
		move_player_backward(px, py, pang);
		if (map_data[py[1]][px[1]])
			move_player_forward(px, py, pang);
	
	}
	if (keys & LEFT_KEY)
	{
		pang ++;
		pang &= 0x7ff;
	}
	if (keys & RIGHT_KEY)
	{
		pang --;
		pang &= 0x7ff;
	}

}

#define RC_TILES_WORD_ADDRESS 0x3800
#define RC_TILES_ADDRESS_LO 0x7000
#define RC_TILES_ADDRESS_HI 0x0000

void main(void)
{
/*	vtors->background_set(0, 
		    1, 
		    0,
		    0, 
		    0, 
		    ((unsigned short)map_data) >> 1, 
		    RC_TILES_WORD_ADDRESS,
		    TILE_WIDTH_8X8,
		    TILE_MAP_STRIDE_32);
	vtors->background_update();
*/

	vtors->storage_load_synch(rc_map_tiles_flash_offset_lo, rc_map_tiles_flash_offset_hi, 0, 0, RC_TILES_ADDRESS_LO, RC_TILES_ADDRESS_HI, (rc_map_tiles_flash_size_lo>>1));
	
	vtors->copper_set_bg_color(0x0000);
//	vtors->load_palette(torus_palette, 0, 16);

	vtors->copper_list_load(the_copper_list, sizeof(the_copper_list) / sizeof(the_copper_list[0]));
	vtors->copper_control(1);
//	vtors->copper_set_y_flip(1, 150); 
//	vtors->copper_set_alpha(0x8000);

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	vtors->load_palette(ray_palette, 0, 16);
	// Create the sprite array

	clear_fb(framebuffers_upper_lo[0], 0x0000);
	clear_fb(framebuffers_upper_lo[1], 0x0000);
	
	vtors->sprite_display(0, framebuffers_word_addr[cur_front_buffer], SPRITE_STRIDE_320, FRAME_BUFFER_WIDTH, FRAME_BUFFER_HEIGHT, 24, 16);
	vtors->sprite_update_sprite(0);

	while (1)
//	while (frame < 1000)
	{
		int i;
		vtors->rtos_lock_mutex(&eff5_mutex);
		frame++;
		
		clear_fb(framebuffers_upper_lo[!cur_front_buffer], 0x0000);

		raycast_render(framebuffers_upper_lo[!cur_front_buffer], px, py, pang >> 2);

		poll_gpios();

		if ((frame & 0xf) == 0)
		{
			vtors->printf("FPS x100: %d\r\n", _mult_div_8_8(frame, 6000, vsync_count));
			vtors->printf("Px: %x py: %x pang: %x\n", get_player_xy(px), get_player_xy(py), pang);
		}

		flip_buffer = 1;

	}
	
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);

	vtors->copper_control(0);
	vtors->copper_set_y_flip(0, 0xfff); 
	vtors->copper_set_alpha(0x0000);
	vtors->sprite_init_sprites();
	vtors->copper_set_bg_color(0x0000);
}

