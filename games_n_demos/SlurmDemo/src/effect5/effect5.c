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


void main(void)
{
	vtors->background_set(0, 
		    0, 
		    0,
		    0, 
		    0, 
		    0, 
		    0,
		    0,
		    0);
	vtors->background_update();


	vtors->copper_set_bg_color(0x0000);
//	vtors->load_palette(torus_palette, 0, 16);

	vtors->copper_list_load(the_copper_list, sizeof(the_copper_list) / sizeof(the_copper_list[0]));
	vtors->copper_control(1);
	vtors->copper_set_y_flip(1, 150); 
	vtors->copper_set_alpha(0x8000);

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	// Create the sprite array

	clear_fb(framebuffers_upper_lo[0], 0x0000);
	clear_fb(framebuffers_upper_lo[1], 0x0000);
	
	vtors->sprite_display(0, framebuffers_word_addr[cur_front_buffer], SPRITE_STRIDE_256, FRAME_BUFFER_WIDTH, FRAME_BUFFER_HEIGHT, 54, 32);
	vtors->sprite_update_sprite(0);

	while (frame < 1000)
	{
		int i;
		vtors->rtos_lock_mutex(&eff5_mutex);
		frame++;
		
		clear_fb(framebuffers_upper_lo[!cur_front_buffer], 0x0000);

		if ((frame & 0xf) == 0)
			vtors->printf("FPS x100: %d\r\n", _mult_div_8_8(frame, 6000, vsync_count));

		flip_buffer = 1;

	}
	
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);

	vtors->copper_control(0);
	vtors->copper_set_y_flip(0, 0xfff); 
	vtors->copper_set_alpha(0x0000);
	vtors->sprite_init_sprites();
	vtors->copper_set_bg_color(0x0000);
}

