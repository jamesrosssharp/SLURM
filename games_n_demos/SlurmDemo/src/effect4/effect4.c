/*

	SlurmDemo : A demo to show off SlURM16

effect4.c : interlinked 3D tori (?)

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

#include <Matrix4.h>
#include <Vertex.h>

unsigned short torus_palette[] = {
	0x0000,	0xf000, 0xf211, 0xf411,
	0xf711, 0xf811, 0xf922, 0xfa22,
	0xfb33, 0xfc33, 0xfd44, 0xfe44,
	0xff66, 0xff88, 0xffaa, 0xffff	
};

/* =============== Torus object data ================ */


struct Point3D {

	short x;
	short y;
	short z;
};

struct Triangle {
	unsigned char v1;
	unsigned char v2;
	unsigned char v3;	
	unsigned char n;
}; 

#include "torus_obj.h"

/* ================================================== */

mutex_t eff4_mutex = RTOS_MUTEX_INITIALIZER;

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_BASE);



unsigned short frame = 0;

#define FRAME_BUFFER_WIDTH 256
#define FRAME_BUFFER_HEIGHT 128

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

bool flip_buffer = 0;

static void my_vsync_handler()
{
	if (flip_buffer)
	{
		cur_front_buffer = !cur_front_buffer;
		flip_buffer_spr(framebuffers_word_addr[cur_front_buffer]);
		flip_buffer = 0;
	}

	vtors->rtos_unlock_mutex_from_isr(&eff4_mutex);
}

void print_matrix(struct Matrix4* mat)
{
	vtors->printf("%x %x %x ", mat->x1, mat->y1, mat->z1);
	vtors->printf("%x\r\n", mat->w1);
	
	vtors->printf("%x %x %x ", mat->x2, mat->y2, mat->z2);
	vtors->printf("%x\r\n", mat->w2);
	
	vtors->printf("%x %x %x ", mat->x3, mat->y3, mat->z3);
	vtors->printf("%x\r\n", mat->w3);
	
	vtors->printf("%x %x %x ", mat->x4, mat->y4, mat->z4);
	vtors->printf("%x\r\n", mat->w4);
	
}


void main(void)
{
	struct Matrix4 rot;
	struct Matrix4 trans;
	struct Matrix4 proj;
	short test;
	short z_t = 0xff00;

	vtors->copper_set_bg_color(0x0000);
	vtors->load_palette(torus_palette, 0, 16);

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	// Create the sprite array

	vtors->sprite_display(0, framebuffers_word_addr[cur_front_buffer], SPRITE_STRIDE_256, FRAME_BUFFER_WIDTH, FRAME_BUFFER_HEIGHT, 54, 32);
	vtors->sprite_update_sprite(0);

	while (frame < 1000)
	{
		int i;
		vtors->rtos_lock_mutex(&eff4_mutex);
		frame++;
		
		flip_buffer = 1;

		clear_fb(framebuffers_upper_lo[!cur_front_buffer], 0x0);

		matrix4_createRot(&rot, (frame >> 1) & 0xff, (frame >> 2) & 0xff, frame & 0xff);

		z_t = 0xa00 + (sin_table_8_8[frame & 0xff] << 1);

		matrix4_createTrans(&trans, 0, 0, z_t);

		matrix4_createPerspective(&proj, 0xcc, 0x100, 0, 0);

		matrix4_multiply(&proj, &trans);
		matrix4_multiply(&proj, &rot);

		for (i = 0; i < N_TORUS_POINTS; i++)
		{
			struct Vertex v;
			short sx;
			short sy;

			v.x = torus_points[i].x; 	
			v.y = torus_points[i].y; 	
			v.z = torus_points[i].z; 
			v.w = 0x100;	

			vertex_multiply_matrix(&v, &proj);

			vertex_project(&v);

			sx = (v.sx + 8) >> 4;
			sy = (v.sy + 8) >> 4;

			if (sx > 0 && sx < 256 && sy > 0 && sy < 128)
				put_pixel(framebuffers_upper_lo[!cur_front_buffer], sx, sy);

		} 

	}

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);
}

