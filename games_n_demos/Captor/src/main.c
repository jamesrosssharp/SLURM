/*
 * Captor: a vertical scrolling shooter for the SLURM16.
 *
 * Controls: the d-pad flies the plane, A fires, B makes an evasive roll.
 * Press A on the title screen to start; left alone, the title runs a demo.
 */

#include <game_io.h>
#include "game.h"
#include "video.h"

extern volatile short vsync;	/* set by the vsync interrupt (top.asm) */

int main(void)
{
	video_init();
	game_init();

	while (1)
	{
		if (vsync)
		{
			vsync = 0;
			video_vblank();		/* show the frame built last time */
			game_frame();		/* build the next one */
		}
		__sleep();
	}
	return 0;
}
