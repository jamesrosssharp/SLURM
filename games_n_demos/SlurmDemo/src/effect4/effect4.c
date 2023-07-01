/*

	SlurmDemo : A demo to show off SlURM16

effect4.c : interlinked 3D tori

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

#include <copper.h>

#include "qsort.h"

unsigned short torus_palette[] = {
	0x0000,	0xf100, 0xf211, 0xf411,
	0xf711, 0xf811, 0xf922, 0xfa22,
	0xfb33, 0xfc33, 0xfd44, 0xfe44,
	0xff66, 0xff88, 0xffaa, 0xffff	
};

#define NULL 0

/* =============== Torus object data ================ */


struct Point3D {

	short x;
	short y;
	short z;
};

#include "Triangle.h"

#include "torus_obj.h"

/* ================================================== */

/* =============== Vertex + normal arrays =========== */

struct Vertex vertices[N_TORUS_POINTS];
struct Vertex normals[N_TORUS_NORMALS];

short vertex_z[N_TORUS_POINTS];

// Triangle z buffer

#define ZBUFFER_SIZE 2048

struct Triangle* zbuffer[ZBUFFER_SIZE];

/* =============== Copper list ====================== */

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

/* ================================================== */

mutex_t eff4_mutex = RTOS_MUTEX_INITIALIZER;

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_CODE_BASE);



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

volatile bool flip_buffer = 0;
volatile short vsync_count = 0;

static void my_vsync_handler()
{
	if (flip_buffer)
	{
		cur_front_buffer = !cur_front_buffer;
		flip_buffer_spr(framebuffers_word_addr[cur_front_buffer]);
		flip_buffer = 0;
		vtors->rtos_unlock_mutex_from_isr(&eff4_mutex);
	}
	vsync_count++;
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

/*int tri_compare_func(void* a, void* b)
{
	struct Triangle* t1 = (struct Triangle*)a;
	struct Triangle* t2 = (struct Triangle*)b;

	return (vertices[t1->v1].z - vertices[t2->v1].z);
}

void z_sort_tris(struct Triangle** tris, int n_tris)
{
	//qsort((void**)tris, 0, n_tris - 1, tri_compare_func, 0);
}*/

void create_zbuffer()
{
	int i;
	short maxZ = -32768;
	short minZ = 32767;

	for (i = 0; i < ZBUFFER_SIZE; i++)	
		zbuffer[i] = NULL;	

	// Find out 
	for (i = 0; i < N_TORUS_TRIS; i++)
	{
		short z = -vertex_z[torus_tris[i].v1]; 
		if (z < minZ)
			minZ = z;
		if (z > maxZ)
			maxZ = z;
	}

	//vtors->printf("Z min: %x %x %x\r\n", minZ, maxZ, maxZ - minZ);

	for (i = 0; i < N_TORUS_TRIS; i ++)
	{
		struct Triangle* t = &torus_tris[i];
		short z = -vertex_z[t->v1]; 
		
		if (normals[t->n].z > 0)
			continue;

		z -= minZ;

		z = ZBUFFER_SIZE - 1 - z;

		//vtors->printf("Z: %x\r\n", z);

		if (z >= 0 && z < ZBUFFER_SIZE)
		{
			if (zbuffer[z] != NULL)
			{
				struct Triangle* tt;	
				for (tt = zbuffer[z]; tt->next != NULL; tt = tt->next)
					;
					
				tt->next = t;
				tt->next->next = NULL;
			}
			else {
				zbuffer[z] = t;
				zbuffer[z]->next = NULL;
			}
		}
	}

}

void main(void)
{
	struct Matrix4 rot;
	struct Matrix4 trans;
	struct Matrix4 proj;
	short test;
	short z_t = 0xff00;
	int j;

	vtors->background_set(0, 
		    0, 
		    0,
		    0, 
		    0, 
		    0, 
		    0,
		    0,
		    0);

	vtors->copper_set_bg_color(0x0000);
	vtors->load_palette(torus_palette, 0, 16);

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

	while (frame < 500)
	{
		int i;
		vtors->rtos_lock_mutex(&eff4_mutex);
		frame++;
		
		clear_fb(framebuffers_upper_lo[!cur_front_buffer], 0x0000);

		matrix4_createRot(&rot, (frame << 1) & 0xff, (frame << 2) & 0xff, frame & 0xff);

		z_t = 0xc00 + (sin_table_8_8[(frame << 2) & 0xff] << 2);

		matrix4_createTrans(&trans, 0, 0, z_t);

		matrix4_createPerspective(&proj, 0xcc, 0x100, 0, 0);

		matrix4_multiply(&proj, &trans);
		matrix4_multiply(&proj, &rot);

		for (i = 0; i < N_TORUS_POINTS; i++)
		{
			struct Vertex *v;
			short sx;
			short sy;

			v = &vertices[i];

			v->x = torus_points[i].x; 	
			v->y = torus_points[i].y; 	
			v->z = torus_points[i].z; 
			v->w = 0x100;	

			vertex_multiply_matrix(v, &proj);

			vertex_z[i] = v->z;

			vertex_project(v);

		}

		for (i = 0; i < N_TORUS_NORMALS; i++)
		{
			struct Vertex* n;

			n = &normals[i];
			
			n->x = torus_normals[i].x;
			n->y = torus_normals[i].y;
			n->z = torus_normals[i].z;
 
			vertex_multiply_matrix(n, &rot);
		} 

		create_zbuffer();

		for (i = 0; i < ZBUFFER_SIZE; i++)
		{
			struct Triangle* t = zbuffer[i]; 
			short col = 0;

			if (t == NULL)
				continue;

			do {

				col = ((-normals[t->n].z) >> 4);
			
				if (col < 1) col = 1;
				if (col > 0xf) col = 0xf;
		
				triangle_rasterize(framebuffers_upper_lo[!cur_front_buffer], &vertices[t->v1], &vertices[t->v2], &vertices[t->v3], col);			
		
			} while (t = t->next);
		}  

		//{

		//	struct Vertex v1; //= {0, 0, 0, 10, 10};
		//	struct Vertex v2; //= {0, 0, 0, 10, 50};
		//	struct Vertex v3; //= {0, 0, 0, 50, 50};

		//	v1.sx = 20 * 16;
		//	v1.sy = 20 * 16;

		//	v3.sx = 100 * 16;
		//	v3.sy = 100 * 16;

		//	v2.sx = 20 * 16;
		//	v2.sy = 100 * 16;

		//	triangle_rasterize(framebuffers_upper_lo[!cur_front_buffer], &v1, &v2, &v3, 0xf);			
		//}
		//leave_critical();

		if ((frame & 0xf) == 0)
			vtors->printf("FPS x100: %d\r\n", _mult_div_8_8(frame, 6000, vsync_count));

		flip_buffer = 1;

	}
	

/*	while (1)
	{
		unsigned short i;
		short val = 0;
		for (i = 0; i < 1000; i++)
		{
			unsigned short j;
			unsigned short k;
			for (j = 0; j < 100; j++)
				for (k = 0; k < 100; k++)
					;
			val ++;
		}
		vtors->printf("Val: %x\r\n", val);
	}*/


	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);

	vtors->copper_control(0);
	vtors->copper_set_y_flip(0, 0xfff); 
	vtors->copper_set_alpha(0x0000);
	vtors->sprite_init_sprites();
	vtors->copper_set_bg_color(0x0000);
}

