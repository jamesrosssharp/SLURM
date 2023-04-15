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

#define COPPER_BAR_HEIGHT 16

short bar1_y = 0;
short bar1_vy = 1;
short bar1_dir = 0;

unsigned short the_copper_list[128];

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

void do_copper_bars()
{
	// Wait until bar1_y 
	int i;
	the_copper_list[0] = COPPER_VWAIT(bar1_y);
	for (i = 0; i < COPPER_BAR_HEIGHT; i++)
	{
		if (bar1_y + i > 240)
			the_copper_list[i + 1] = COPPER_BG_WAIT(0x0000);
		else
			the_copper_list[i + 1] = COPPER_BG_WAIT(bar1_colors[i]);
	}
	the_copper_list[i++] = COPPER_BG(0x000);
	the_copper_list[i++] = COPPER_VWAIT(0xfff);

	copper_list_load(the_copper_list, i);
}

mutex_t eff2_mutex = RTOS_MUTEX_INITIALIZER;

static void my_vsync_handler()
{
	rtos_unlock_mutex_from_isr(&eff2_mutex);
}

void run_effect2(void)
{
	int i;
	int frame = 0;

	// Add a vsync interrupt handler
	rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	copper_control(1);

	bar1_y = 0;
	bar1_vy = 2;

	my_printf("Frame ptr: %x\r\n", &frame);

	while (frame < 1000)
	{

		rtos_lock_mutex(&eff2_mutex);

		//my_printf(".");
		
		frame++;

		do_copper_bars();
	
		if (frame < 64)
			pwm_set(0, 0, frame);

		bar1_y += bar1_vy;

		if (bar1_vy > 0 && bar1_y > 230)
			bar1_vy = -bar1_vy;
		if (bar1_vy < 0 && bar1_y < 10)
			bar1_vy = -bar1_vy;
	}

	// Outtro

	while (bar1_y < 300)
	{
		frame++;

		rtos_lock_mutex(&eff2_mutex);

		do_copper_bars();
	
		if (bar1_y > 250)
			pwm_set(0, 0, 300 - bar1_y);

		bar1_y += 4;


	}

	pwm_set(0, 0, 0);

	copper_control(0);

}


