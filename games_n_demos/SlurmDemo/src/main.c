/*

	SlurmDemo : A demo to show off SlURM16

main.c: Main function

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


#include <slurmsng.h>
#include <slurminterrupt.h>
#include <slurmflash.h>

#include <bundle.h>

#include <printf.h>
#include <music.h>
#include <storage.h>
#include <sprite.h>
#include <background.h>
#include "demo.h"
#include <rtos.h>
#include <gfx.h>

#include <applet.h>
#include <applet_bundle.h>

static int frame = 0;

static void my_vsync_handler()
{
	frame++;
}

int main()
{
	int sprites = 0;
	int i;

	my_printf("Hello world Slurm Demo!\r\n");
	
	gfx_set_mode(VIDEO_MODE_320X240);
	copper_set_bg_color(0x0000);
	copper_set_alpha(0);

	storage_init(STORAGE_TASK_ID);
	init_music_player(AUDIO_TASK_ID);
	sprite_init_sprites();
	background_init();

	rtos_set_interrupt_handler(SLURM_INTERRUPT_VSYNC_IDX, my_vsync_handler);

	while (frame < 256) ;


	my_printf("Ready to start demo\r\n");

	// Spin in a loop
	
	while (1)
	{

/*		applet_load(effect1_applet_flash_offset_lo, effect1_applet_flash_offset_hi, 
			    effect1_applet_flash_size_lo >> 1);
		applet_run();  
*/

		applet_load(effect2_applet_flash_offset_lo, effect2_applet_flash_offset_hi, 
			    effect2_applet_flash_size_lo >> 1);
		applet_run();  

/*		applet_load(effect3_applet_flash_offset_lo, effect3_applet_flash_offset_hi, 
			    effect3_applet_flash_size_lo >> 1);
		applet_run();  

		applet_load(effect4_applet_flash_offset_lo, effect4_applet_flash_offset_hi, 
			    effect4_applet_flash_size_lo >> 1);
		applet_run();  

		applet_load(effect5_applet_flash_offset_lo, effect5_applet_flash_offset_hi, 
			    effect5_applet_flash_size_lo >> 1);
		applet_run();  

		applet_load(effect6_applet_flash_offset_lo, effect6_applet_flash_offset_hi, 
			    effect6_applet_flash_size_lo >> 1);
		applet_run();  
*/
	}

}
