/*

	SlurmDemo : A demo to show off SlURM16

tunnel.asm : tunnel effect

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
extern void compute_flash_offset(unsigned short* flash_lo, unsigned short* flash_hi, unsigned short x);
*/
	.global compute_flash_offset
	.function compute_flash_offset
compute_flash_offset:
	sub r13, 32

	//
	//	r4: flash_lo
	//	r5: flash_hi
	//	r6: x
	//	r7: y
	//


	st [r13, 0], r4 
	st [r13, 2], r5 
	st [r13, 4], r6 
	st [r13, 6], r7 
	st [r13, 8], r8
	st [r13, 10], r9
	st [r13, 12], r10
	st [r13, 14], r11
	st [r13, 16], r12
	st [r13, 18], r15

	// multiply y by table width in words
	mov r8, r7
	mov r9, 320
	mul r7, r9	
	umulu r8, r9

	mov r9, r6
	asr r9
	add r7, r9
	adc r8, r0	// r8:r7 -> x>>1 + 320*y

	ld r9, [r4]
	ld r10, [r5]	// r10:r9 -> flash offset

	add r9, r7
	adc r10, r8	// r10:r9 -> flash offset + x>>1 + 320*y

	st [r4], r9
	st [r5], r10

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

// extern void tunnel_render_asm(unsigned short fb, unsigned char* distance_buffer, unsigned char* angle_buffer, unsigned char* shade_buffer);
	.global tunnel_render_asm
	.function tunnel_render_asm
tunnel_render_asm:
	sub r13, 32

	//	r4: *frame_buffer
	//	r5: *distance_buffer
	//	r6: *angle_buffer
	//	r7: *shade_buffer
	//	[r13, 0x30]: shift U
	//	[r13, 0x32]: shift V

	st [r13, 0], r4 
	st [r13, 2], r5 
	st [r13, 4], r6 
	st [r13, 6], r7 
	st [r13, 8], r8
	st [r13, 10], r9
	st [r13, 12], r10
	st [r13, 14], r11
	st [r13, 16], r12
	st [r13, 18], r15

	ld r11, [r13, 0x30]
	ld r12, [r13, 0x34]


	mov r15, r4
	mov r9, 160
	add r15, r9
tunnel_loop:
	ldb r8, [r5]
	add r8, r11
	and r8, 63
	mul r8, 64
	ldb r10, [r6]
	add r10, r12
	and r10, 63
	add r8, r10
	
	cc
	rorc r8
	.extern texture
	ldb r10, [r8, texture]
	bnc  low_nibble 
high_nibble:
	rrn r10, r10
low_nibble:
	and r10, 0xf
	ldb r8, [r7]
	rln r8, r8
	or  r10, r8
	.extern color_tab
	ld  r10,[r10, color_tab]
	mul r10,0x11

	stb.ex [r4], r10
	stb.ex [r15], r10

	add r4, 1
	add r15, 1
	add r5, 1
	add r6, 1
	add r7, 1
	sub r9, 1
	bnz tunnel_loop



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

	.end
