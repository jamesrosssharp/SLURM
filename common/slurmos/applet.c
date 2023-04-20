/*

	SlurmDemo : A demo to show off SlURM16

applet.c: To save code space, we break up the code for demos
and games into applets. Each applet has a set of vectors that
will be filled in by the main routine using methods in this file.

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

#include <applet.h>
#include <storage.h>
#include <rtos.h>
#include <copper.h>
#include <printf.h>
#include <background.h>
#include <sprite.h>
#include <pwm.h>

struct applet_vectors *vtors = (struct applet_vectors*)(APPLET_BASE);

void load_palette(unsigned short* palette, int offset, int count); 
unsigned short __in(unsigned short port);		
void __out(unsigned short port, unsigned short val);	

void applet_load(unsigned short applet_flash_lo, unsigned short applet_flash_hi, unsigned short size)
{
	// Load applet
	storage_load_synch(applet_flash_lo, applet_flash_hi, 0, 0, APPLET_BASE, 0, size);

	// Perform dynamic linking
	
	/* RTOS */
	vtors->rtos_lock_mutex = &rtos_lock_mutex;
	vtors->rtos_unlock_mutex = &rtos_unlock_mutex;
	vtors->rtos_unlock_mutex_from_isr = &rtos_unlock_mutex_from_isr;
	vtors->rtos_set_interrupt_handler = &rtos_set_interrupt_handler;
	/* uart */
	vtors->printf = &my_printf;
	/* storage */
	vtors->storage_load_synch = &storage_load_synch;
	vtors->storage_load_asynch = &storage_load_asynch;
	/* sprites */
	vtors->sprite_display = &sprite_display;
	vtors->sprite_set_x_y = &sprite_set_x_y;
	vtors->sprite_update_sprites = &sprite_update_sprites;
	vtors->sprite_update_sprite = &sprite_update_sprite;
	/* background */
	vtors->background_set = &background_set;
	vtors->background_set_x_y = &background_set_x_y;
	vtors->background_update = &background_update;
	/* copper */
	vtors->copper_control = &copper_control;
	vtors->copper_set_y_flip = &copper_set_y_flip;
	vtors->copper_set_x_pan = &copper_set_x_pan;
	vtors->copper_set_bg_color = &copper_set_bg_color;
	/* pwm */
	vtors->pwm_set = &pwm_set;
	/* palette */
	vtors->load_palette = &load_palette;
	/* port io */
	vtors->__in = &__in;
	vtors->__out = &__out;
}

void applet_run()
{
	vtors->applet_entry();
}

