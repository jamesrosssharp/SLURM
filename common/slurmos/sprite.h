/*

sprite.h: Routines for programming the sprite hardware

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#ifndef SPRITE_H
#define SPRITE_H

enum SpriteStride {
	SPRITE_STRIDE_256 = 1,	
	SPRITE_STRIDE_320 = 0
};

void sprite_init_sprites();

/*
 *	Display a sprite
 *
 * 	Returns: number of sprite channels consumed to display the sprite
 */
short sprite_display(unsigned char sprite_index, 
		     unsigned short sprite_pointer,
		     enum SpriteStride stride, 
		     unsigned short width, 
		     unsigned short height, 
		     short x, 
		     short y);


void sprite_set_x_y(unsigned char sprite_index, short x, short y);

void sprite_update_sprites();

void sprite_update_sprite(unsigned char sprite_index);

#endif
