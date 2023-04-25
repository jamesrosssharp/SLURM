/*

	SlurmDemo : A demo to show off SlURM16

effect2.c : copper bars

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

#include "copper.h"
#include "rtos.h"
#include <slurminterrupt.h>

#include <applet.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_BASE);

#define COPPER_BAR_HEIGHT 16

struct copper_bar {
	short y;
	short vy;
	short x;
	short vx;
	short id;
};

struct copper_bar bar1 = {0, 0, 0};
struct copper_bar bar2 = {0, 0, 1};

short cpr_idx = 0;

unsigned short the_copper_list[512];

unsigned short bar1_colors[COPPER_BAR_HEIGHT] = {
	0x0000,	// 0
	0x0002, // 1
	0x0004, // 2
	0x0006, // 3
	0x0008, // 4
	0x000a, // 5
	0x000c, // 6
	0x000e, // 7
	0x000f, // 8
	0x000f, // 9
	0x022f, // 10
	0x0aaf, // 11
	0x0fff, // 12
	0x0aaf, // 13
	0x000a, // 14
	0x0004, // 15

};

unsigned short bar2_colors[COPPER_BAR_HEIGHT] = {
	0x0000,	// 0
	0x0200, // 1
	0x0400, // 2
	0x0600, // 3
	0x0800, // 4
	0x0a00, // 5
	0x0c00, // 6
	0x0e00, // 7
	0x0f00, // 8
	0x0f00, // 9
	0x0f22, // 10
	0x0faa, // 11
	0x0fff, // 12
	0x0aaf, // 13
	0x0a00, // 14
	0x0400, // 15

};

void do_copper_bars()
{
	// Wait until bar1_y 
	int i;
	int j;
	
	struct copper_bar *b1;
	struct copper_bar *b2;
	unsigned short *b1_cols;
	unsigned short *b2_cols;
	unsigned short ov = 0;

	int h1 = COPPER_BAR_HEIGHT;
	int h2 = COPPER_BAR_HEIGHT;
	int st2 = 0;

	cpr_idx = 0;
	
	if (bar1.y > bar2.y)
	{
		// Blue bar lower down than red bar
		b1 = &bar2;
		b2 = &bar1;
		b1_cols = bar2_colors;
		b2_cols = bar1_colors;
	}
	else
	{
		// red bar lower than blue bar
		b1 = &bar1;
		b2 = &bar2;
		b1_cols = bar1_colors;
		b2_cols = bar2_colors;
	}

	// Check for overlap

	if (b1->y + COPPER_BAR_HEIGHT > b2->y)
	{
		if (b1->id == 0)
		{
			h1 = (b2->y - b1->y);
		}
		else
		{
			st2 = COPPER_BAR_HEIGHT - (b2->y - b1->y);
		}
		ov = 1;
	}

	the_copper_list[cpr_idx++] = COPPER_VWAIT(b1->y);

	for (i = 0; i < h1; i++)
	{
		if (b1->y + i > 260)
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(0x0000);
		else
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(b1_cols[i]);
		cpr_idx++;
	}

	if (!ov)
	{
		the_copper_list[cpr_idx++] = COPPER_VWAIT(b2->y);
	}

	for (j = st2; j < h2; j++)
	{
		if (b2->y + j > 260)
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(0x0000);
		else
			the_copper_list[cpr_idx] = COPPER_BG_WAIT(b2_cols[j]);
		cpr_idx++;
	}

	the_copper_list[cpr_idx++] = COPPER_BG(0x000);
	the_copper_list[cpr_idx++] = COPPER_VWAIT(0xfff);

}

void do_vertical_copper_bars()
{
	int i;
	int j;
	
	unsigned short *b1_cols;
	unsigned short *b2_cols;
	struct copper_bar *b1;
	struct copper_bar *b2;
	
	int w1 = COPPER_BAR_HEIGHT;
	int w2 = COPPER_BAR_HEIGHT;
	int st2 = 0;
	int ov = 0;

	cpr_idx = 0;
	
	if (bar1.x > bar2.x)
	{
		// Blue bar lower down than red bar
		b1 = &bar2;
		b2 = &bar1;
		b1_cols = bar2_colors;
		b2_cols = bar1_colors;
	}
	else
	{
		// red bar lower than blue bar
		b1 = &bar1;
		b2 = &bar2;
		b1_cols = bar1_colors;
		b2_cols = bar2_colors;
	}

	// Check for overlap

	if (b1->x + COPPER_BAR_HEIGHT > b2->x)
	{
		if (b1->id == 0)
		{
			w1 = (b2->x - b1->x);
		}
		else
		{
			st2 = COPPER_BAR_HEIGHT - (b2->x - b1->x);
		}
		ov = 1;
	}

	the_copper_list[cpr_idx++] = 0x0000; 
	the_copper_list[cpr_idx++] = COPPER_HWAIT(b1->x);

	for (i = 0; i < w1; i++)
	{
		the_copper_list[cpr_idx++] = COPPER_BG(b1_cols[i]);
		the_copper_list[cpr_idx++] = COPPER_BG(b1_cols[i]);
	}	

	if (!ov)
	{
		the_copper_list[cpr_idx++] = COPPER_HWAIT(b2->x);
	}

	for (i = st2; i < w2; i++)
	{
		the_copper_list[cpr_idx++] = COPPER_BG(b2_cols[i]);
		the_copper_list[cpr_idx++] = COPPER_BG(b2_cols[i]);
	}	

	the_copper_list[cpr_idx++] = COPPER_BG(0x000);
	the_copper_list[cpr_idx++] = COPPER_HWAIT(399);
	the_copper_list[cpr_idx++] = COPPER_JUMP(0x001);

	//vtors->copper_list_load(the_copper_list, cpr_idx);
}

void do_sound_copper_bars()
{
	int i, j;

	cpr_idx = 0;

	the_copper_list[cpr_idx++] = COPPER_VWAIT(20);
	the_copper_list[cpr_idx++] = COPPER_BG(0x000);

	for (i = 0; i < 128; i++)
	{
		the_copper_list[cpr_idx++] = COPPER_HWAIT((((short)(vtors->__in(0x8000 + i*2) + vtors->__in(0x8100 + i*2))  >> 8) + 180) & 0xfff);
		the_copper_list[cpr_idx++] = COPPER_BG(0xfff);
		the_copper_list[cpr_idx++] = COPPER_BG_WAIT(0x000);
		the_copper_list[cpr_idx++] = COPPER_BG_WAIT(0x000);
	}
	
	the_copper_list[cpr_idx++] = COPPER_BG(0x000);
	the_copper_list[cpr_idx++] = COPPER_VWAIT(0xfff);

}

mutex_t eff2_mutex = RTOS_MUTEX_INITIALIZER;

static void my_vsync_handler()
{
	vtors->copper_list_load(the_copper_list, cpr_idx);
	vtors->rtos_unlock_mutex_from_isr(&eff2_mutex);
}

void main(void)
{
	int i, j;
	int frame = 0;

	// Add a vsync interrupt handler
	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	vtors->copper_control(1);

	bar1.y = 10;
	bar1.x = 10;
	bar1.vy = 3;
	bar1.vx = 3;

	bar2.y = 230;
	bar2.x = 310;
	bar2.vx = -2;
	bar2.vy = -2;

	while (frame < 1000)
	{

		unsigned short btns;
	
		vtors->rtos_lock_mutex(&eff2_mutex);
		
		do_copper_bars();
		
		frame++;
		
		if (frame < 64)
			vtors->pwm_set(0, 0, frame);

		btns = vtors->__in(0x1001);

		if (btns & 1)
			bar1.y++;
		if (btns & 2)
			bar1.y--;

		bar1.y += bar1.vy;
		bar2.y += bar2.vy;

		if (bar1.vy > 0 && bar1.y > 230)
			bar1.vy = -bar1.vy;
		if (bar1.vy < 0 && bar1.y < 10)
			bar1.vy = -bar1.vy;

		if (bar2.vy > 0 && bar2.y > 230)
			bar2.vy = -bar2.vy;
		if (bar2.vy < 0 && bar2.y < 10)
			bar2.vy = -bar2.vy;

	}

	// Outtro

	while (bar1.y < 300)
	{
		frame++;

		vtors->rtos_lock_mutex(&eff2_mutex);

		do_copper_bars();
	
		if (bar1.y > 250)
			vtors->pwm_set(0, 0, 300 - bar1.y);

		bar1.y += 4;
		bar2.y -= 4;


	}

	// Vertical copper bars

	frame = 0;

	while (frame < 1000)
	{
		unsigned short btns;

		vtors->rtos_lock_mutex(&eff2_mutex);

		do_vertical_copper_bars();
		
		frame++;
		
		btns = vtors->__in(0x1001);

		if (btns & 1)
			bar1.x++;
		if (btns & 2)
			bar1.x--;

		bar1.x += bar1.vx;
		bar2.x += bar2.vx;

		if (bar1.vx > 0 && bar1.x > 330)
			bar1.vx = -bar1.vx;
		if (bar1.vx < 0 && bar1.x < 30)
			bar1.vx = -bar1.vx;

		if (bar2.vx > 0 && bar2.x > 330)
			bar2.vx = -bar2.vx;
		if (bar2.vx < 0 && bar2.x < 30)
			bar2.vx = -bar2.vx;
	}

	// Sound copper bars

	frame = 0;

	while (frame < 1000)
	{
		frame++;
		vtors->rtos_lock_mutex(&eff2_mutex);

		do_sound_copper_bars();	

	}

	vtors->pwm_set(0, 0, 0);

	vtors->copper_control(0);

	vtors->rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, 0);
}


