/*
 * BloodLust: a parallax scrolling shooter for the SLURM16.
 *
 * Controls: the d-pad moves the jet, A fires. Press A on the title
 * screen to start; left alone, the title runs a demo game.
 */

#include <game_io.h>
#include "game.h"
#include "video.h"

/* Cleared by the interrupt handler (top.asm) on every vertical blank. */
volatile short int_flag = 1;

static void enable_interrupts(void)
{
	__out(0x7000, 0x2);	/* vsync */
	global_interrupt_enable();
}

int main(void)
{
	video_init();
	game_init();
	enable_interrupts();

	while (1)
	{
		if (int_flag == 0)
		{
			int_flag = 1;
			video_vblank();		/* show the frame built last time */
			game_frame();		/* build the next one */
		}
		__sleep();
	}
	return 0;
}
