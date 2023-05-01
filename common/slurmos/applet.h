/*

	SlurmDemo : A demo to show off SlURM16

applet.h: To save code space, we break up the code for demos
and games into applets. Each applet has a set of vectors that
will be filled in by the main routine using an OS method.
This header defines the vector interface. 

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

#ifndef APPLET_H
#define APPLET_H

#define APPLET_BASE 0xc000 /* Must match linker script for applet */
#define N_APPLET_VECTORS 25 /* should match below */
#define APPLET_SIZE 0x4000

#ifndef __ASM__ 

#include <storage.h>
#include <sprite.h>
#include <background.h>
#include <rtos.h>

struct applet_vectors {

	void (* applet_entry)();		// 0

	/* RTOS */
	void (* rtos_lock_mutex)(mutex_t* mut);		// 1
	void (*	rtos_unlock_mutex)(mutex_t* mut);	// 2
	void (*	rtos_unlock_mutex_from_isr)(mutex_t* mut);	// 3
	void (*	rtos_set_interrupt_handler)(unsigned short irq, void (*handler)());	// 4

	/* uart */

	void (* printf)(char * fmt, ...);	// 5

	/* storage */

	void (* storage_load_synch)(unsigned short base_lo, unsigned short base_hi, 
		  unsigned short offset_lo, unsigned short offset_hi, 
		  unsigned short address_lo, unsigned short address_hi, 
		  short count);		// 6

	void (*storage_load_asynch)(unsigned short base_lo, unsigned short base_hi, 
		  unsigned short offset_lo, unsigned short offset_hi, 
		  unsigned short address_lo, unsigned short address_hi, 
		  short count, storage_callback_t cb, void* user_data); // 7

	/* sprites */

	short (*sprite_display)(unsigned char sprite_index, 
		     unsigned short sprite_pointer,
		     enum SpriteStride stride, 
		     unsigned short width, 
		     unsigned short height, 
		     short x, 
		     short y);	// 8

	void (*sprite_set_x_y)(unsigned char sprite_index, short x, short y); // 9

	void (*sprite_update_sprites)(); // 10

	void (*sprite_update_sprite)(unsigned char sprite_index); // 11

	/* background */

	void (*background_set)(int bg_idx, 
		    unsigned char enable, 
		    unsigned char palette,
		    short x, 
		    short y, 
		    unsigned short tilemap_address, 
		    unsigned short tileset_address,
		    enum TileWidth tile_width,
		    enum TileMapStride tile_stride); // 12

	void (*background_set_x_y)(int bg_idx, short x, short y); // 13
	void (*background_update)(); // 14

	/* copper */

	void (*copper_control)(short enable); // 15
	void (*copper_set_y_flip)(short enable, short flip_y); // 16
	void (*copper_set_x_pan)(short xpan); // 17
	void (*copper_set_bg_color)(unsigned short color); // 18
	void (*copper_set_alpha)(unsigned short alpha); // 19
	void (*copper_list_load)(unsigned short* copper_list, unsigned short len); //20

	/* pwm */

	void (*pwm_set)(unsigned char r, unsigned char g, unsigned char b); // 21

	/* palette */

	void (*load_palette)(unsigned short* palette, int offset, int count); // 22

	/* port io */

	unsigned short (*__in)(unsigned short port);		// 23
	void (*__out)(unsigned short port, unsigned short val);	// 24

	/* music / audio */
};

void applet_load(unsigned short applet_flash_lo, unsigned short applet_flash_hi, unsigned short size);
void applet_run();

#endif

#endif
