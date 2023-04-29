/*

	SlurmDemo : A demo to show off SlURM16

effect2.asm : text blitting for copper bars demo

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

/*
 *	Text blit routine
 *
 */

rand_table:
	dw 0	// 0
	dw 2
	dw 1
	dw 3
	dw 1	// 4
	dw 1
	dw 3
	dw 2
	dw 2 // 8
	dw 3
	dw 0
	dw 1
	dw 2 // 12
	dw 0
	dw 2
	dw 3

//void blit_rect_clip(unsigned short fb_upper_lo, unsigned short x, unsigned short y, unsigned short from_upper_lo, unsigned short x_from, unsigned short y_from);
/*
 *
 *	Take bitmap from coords (x_from, y_from) and writes it with clipping to (x,y)
 *
 *
 */
	.global blit_rect_clip
	.function blit_rect_clip

BLIT_WIDTH equ 8
BLIT_HEIGHT equ 8

blit_rect_clip:

	// [r13, 0x10] = x_from, [r13, 0x14] = y_from

	sub r13, 32

	// [r13, 0x30] = x_from, [r13, 0x34] = y_from
	
	st [r13, 0], r4 // fb_upper_lo
	st [r13, 2], r5 // x
	st [r13, 4], r6 // y
	st [r13, 6], r7 // from_upper_lo
	st [r13, 8], r8
	st [r13, 10], r9
	st [r13, 12], r10
	st [r13, 14], r11
	st [r13, 16], r12
	st [r13, 18], r15

	mov r9, BLIT_HEIGHT
	ld  r2, [r13, 0x30] // x_from
	ld  r3, [r13, 0x34] // y_from

	// Compute blit from address
	mov r10, r3
	mul r10, 128
	mov r11, r2
	asr r11
	add r10, r11
	add r7, r10 // r7: blit from address

	// Compute blit to address
	mov r10, r6
	mul r10, 64
	add r10, r5
	add r4, r10 // r4: blit to address

	mov r11, r0 // r11: rand table lookup

y_loop:

	mov r8, BLIT_WIDTH / 2
x_loop:

	ldb.ex r10, [r7] // r10: source pixel -> lower byte

	// Unroll loop twice to split up byte into two nibbles

	mov r15, 0xff 
	ld r12, [r11, rand_table]	// r12: blit pixel
	add r11, 2
	and r11, 0x1f 	


	cmp r5, 0
	blt skip_pixel_1
	cmp r5, 64
	bge skip_pixel_1
	cmp r6, 0
	blt skip_pixel_1
	cmp r6, 64
	bge skip_pixel_1
	
	test r10, 0xf
	mov.z r12, r15

	stb.ex [r4], r12

skip_pixel_1:	

	lsr r10
	lsr r10
	lsr r10
	lsr r10

	add r4, 1
	add r5, 1
	add r2, 1
	
	ld r12, [r11, rand_table]	// r12: blit pixel
	add r11, 2
	and r11, 0x1f 	

	cmp r5, 0
	blt skip_pixel_2
	cmp r5, 64
	bge skip_pixel_2
	cmp r6, 0
	blt skip_pixel_2
	cmp r6, 64
	bge skip_pixel_2

	test r10, 0xf
	mov.z r12, r15

	stb.ex [r4], r12

skip_pixel_2:

	add r7, 1
	add r4, 1
	add r5, 1
	add r2, 1

	sub r8, 1
	bnz x_loop

	add r4, 64 - BLIT_WIDTH
	add r7, 128 - BLIT_WIDTH / 2
	add r6, 1
	add r3, 1	
	sub r5, BLIT_WIDTH

	sub r9, 1
	bnz y_loop


	ld r4, [r13, 0]
	ld r5, [r13, 2]
	ld r6, [r13, 4]
	ld r7, [r13, 6]
	ld r8, [r13, 8]
	ld r9, [r13, 10]
	ld r10, [r13, 12]
	ld r11, [r13, 14]
	ld r12, [r13, 16]
	ld r15, [r13, 18]

	add r13, 32

	ret
	
	.endfunc


	.global clear_fb
	.function clear_fb
clear_fb:
	sub r13, 32

	st [r13, 0], r4 // fb_upper_lo
	st [r13, 2], r5 
	st [r13, 4], r6 
	st [r13, 6], r7 
	st [r13, 8], r8
	st [r13, 10], r9
	st [r13, 12], r10
	st [r13, 14], r11
	st [r13, 16], r12
	st [r13, 18], r15

	mov r5, 64
	mov r7, 0xff
clr_y_loop:

	mov r6, 64
clr_x_loop:
	stb.ex [r4], r7
	add r4, 1

	sub r6, 1
	bnz clr_x_loop

	sub r5, 1
	bnz clr_y_loop


	ld r4, [r13, 0]
	ld r5, [r13, 2]
	ld r6, [r13, 4]
	ld r7, [r13, 6]
	ld r8, [r13, 8]
	ld r9, [r13, 10]
	ld r10, [r13, 12]
	ld r11, [r13, 14]
	ld r12, [r13, 16]
	ld r15, [r13, 18]

	add r13, 32

	ret
	

	.endfunc

	.global get_upper_word
	.function get_upper_word

get_upper_word:

	ld.ex r2, [r4]
	ret


	.endfunc


	.end
