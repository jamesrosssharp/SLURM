/*

sprite.c: Routines for programming the sprite hardware

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

#include "sprite.h"

struct sprite {
	short x; 
	short y; 
	short width; 
	short height; 
	char n_sprites_used; // zero means disabled 
	char stride;         
	unsigned short sprite_pointer; 
};

struct sprite sprites[256];

#define MAKE_SPRITE_X(x, en, pal, stride) ((x & 0x3ff) | ((en & 0x1) << 10) | ((pal & 0xf) << 11) | ((stride & 1) << 15))
#define MAKE_SPRITE_Y(y, width) ((y & 0x3ff) | ((width & 0x3f) << 10)) 
#define MAKE_SPRITE_H(y) ((y & 0x3ff))
#define MAKE_SPRITE_A(a) (a)

extern void load_sprite_x(short sprite, short x);
extern void load_sprite_y(short sprite, short y);
extern void load_sprite_h(short sprite, short h);
extern void load_sprite_a(short sprite, short a);

void sprite_init_sprites()
{
	int i;

	for (i = 0; i < 256; i++)
		sprites[i].n_sprites_used = 0;
	sprite_update_sprites();
}

void sprite_update_sprites()
{
	int i;

	struct sprite* sp = sprites;
	
	for (i = 0; i < 256; i++)
	{
		short x; 
		short y; 
		short h; 
		short a;
	
		//my_printf("Sprite: %x used: %x\r\n", i, sp->n_sprites_used);
	
		if (sp->n_sprites_used == 0)
		{
			x = MAKE_SPRITE_X(0, 0, 0, 0);
			load_sprite_x(i, x);
			sp ++;
			continue;
		}

		x = MAKE_SPRITE_X(sp->x, !!sp->n_sprites_used, 0, sp->stride);
		y = MAKE_SPRITE_Y(sp->y, sp->width);
		h = MAKE_SPRITE_H(sp->y + sp->height - 1);
		a = MAKE_SPRITE_A(sp->sprite_pointer);

		load_sprite_x(i, x);
		load_sprite_y(i, y);
		load_sprite_h(i, h);
		load_sprite_a(i, a);

		sp++;
	}

}

void sprite_update_sprite(unsigned char sprite_index)
{
	struct sprite* sp = &sprites[sprite_index];
	int i;
	int n = sp->n_sprites_used;

	for (i = 0; i < n; i++)
	{
		short x; 
		short y; 
		short h; 
		short a;
		
		x = MAKE_SPRITE_X(sp->x, !!sp->n_sprites_used, 0, sp->stride);
		y = MAKE_SPRITE_Y(sp->y, sp->width);
		h = MAKE_SPRITE_H(sp->y + sp->height - 1);
		a = MAKE_SPRITE_A(sp->sprite_pointer);

		load_sprite_x(i, x);
		load_sprite_y(i, y);
		load_sprite_h(i, h);
		load_sprite_a(i, a);

		sp++;
	} 

}



short sprite_display(unsigned char sprite_index, 
		     unsigned short sprite_pointer,
		     enum SpriteStride stride, 
		     unsigned short width, 
		     unsigned short height, 
		     short x, 
		     short y)
{

	short processed_width = 0;
	unsigned char n_sprites_processed = 0;

	struct sprite* sp = &sprites[sprite_index];

	//my_printf("Sp-> %x\r\n", &sprites[15]);
	while (width > 0)
	{
		unsigned char this_width = (width < 64) ? width : 64;
		sp->x = x;
		sp->y = y;
		sp->width = this_width - 1;
		sp->height = height;
		sp->sprite_pointer = sprite_pointer;
		sp->stride = stride;
		sprite_pointer += this_width >> 2;
		x += this_width;
		width -= this_width;
		sp->n_sprites_used = 1;
		n_sprites_processed ++; 
		sp++;
	}

	sprite_update_sprites();

	sprites[sprite_index].n_sprites_used = n_sprites_processed; 

	return n_sprites_processed;
}

void sprite_set_x_y(unsigned char sprite_index, short x, short y)
{
	struct sprite* sp = &sprites[sprite_index];
	int i;
	int n = sp->n_sprites_used;
	int xx = sp->x;
	int yy = sp->y;

	for (i = 0; i < n; i++)
	{
		sp->x = sp->x - xx + x;
		sp->y = sp->y - yy + y;
		sp++;
	} 

}

