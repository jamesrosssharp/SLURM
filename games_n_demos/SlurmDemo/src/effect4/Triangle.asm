/*

	SlurmDemo : A demo to show off SlURM16

Triangle.asm : triangle rasterization

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


	.section data

/* jump table is indexed with 3..0 : | len1 | len 0 | x1 1 | x1 0 | */
scanline_start_jump_table:
	dw  done_scanline	// len = 00b, trivial cases, no pixels
	dw  done_scanline  	
	dw  done_scanline
	dw  done_scanline

	dw  align_start_1_0   // len = 01b, one pixel
	dw  align_start_1_1   // len = 01b, one pixel
	dw  align_start_1_0   // len = 01b, one pixel
	dw  align_start_1_1   // len = 01b, one pixel

	dw  align_start_2_0   // len = 10b, two pixels
	dw  align_start_2_1   
	dw  align_start_2_0   
	dw  align_start_2_1   

	dw  align_start_3_0   // len = 11b, three pixels
	dw  align_start_3_1   
	dw  align_start_3_0   
	dw  align_start_3_1   

color_repeat_table_byte:
	db 0x00
	db 0x11
	db 0x22
	db 0x33
	db 0x44
	db 0x55
	db 0x66
	db 0x77
	db 0x88
	db 0x99
	db 0xaa
	db 0xbb
	db 0xcc
	db 0xdd
	db 0xee
	db 0xff

color_repeat_table_word:
	dw 0x0000
	dw 0x1111
	dw 0x2222
	dw 0x3333
	dw 0x4444
	dw 0x5555
	dw 0x6666
	dw 0x7777
	dw 0x8888
	dw 0x9999
	dw 0xaaaa
	dw 0xbbbb
	dw 0xcccc
	dw 0xdddd
	dw 0xeeee
	dw 0xffff

	.section text
align_start_1_0:
		mov r8, r5
		mov r9, r4
		lsr r8
		add r9, r8
		ldb.ex  r10, [r9]
		and r10, 0xf0
		or r10, r7
		stb.ex  [r9], r10
		sub r6, 1
		add r9, 1
		ret
	
align_start_1_1: 
		mov r8, r5
		mov r9, r4
		lsr r8
		add r9, r8
		ldb.ex  r10, [r9]
		and r10, 0xf
		rln r11, r7
		or r10, r11
		stb.ex  [r9], r10	
		sub r6, 1
		add r9, 1
		ret

align_start_2_0:
		mov r8, r5
		mov r9, r4
		lsr r8
		add r9, r8
		ldb r11, [r7, color_repeat_table_byte]
		stb.ex  [r9], r11
		sub r6, 2
		add r9, 1

		ret
	
align_start_2_1:  
		mov r8, r5
		mov r9, r4
		lsr r8
		add r9, r8
		ldb.ex  r10, [r9]
		and r10, 0xf
		rln r11, r7
		or r10, r11
		stb.ex  [r9], r10	

		add r9, 1
		ldb.ex  r10, [r9]
		and r10, 0xf0
		or r10, r7
		stb.ex  [r9], r10

		add r9, 1
		sub r6, 2
		ret

align_start_3_0:
		mov r8, r5
		mov r9, r4
		lsr r8
		add r9, r8
		ldb r11, [r7, color_repeat_table_byte]
		stb.ex  [r9], r11
		add r9, 1	
		ldb.ex  r10, [r9]
		and r10, 0xf0
		or r10, r7
		stb.ex  [r9], r10

		add r9, 1

		sub r6, 3
		ret
align_start_3_1:  
		mov r8, r5
		mov r9, r4
		lsr r8
		add r9, r8
		ldb.ex  r10, [r9]
		and r10, 0xf
		rln r11, r7
		or r10, r11
		stb.ex  [r9], r10	

		add r9, 1
		ldb r11, [r7, color_repeat_table_byte]
		stb.ex  [r9], r11

		add r9, 1

		sub r6, 3
		ret




	.section text
	.align 0x100
	.function draw_scanline
	.global draw_scanline
draw_scanline:
	// r4 = framebuffer (+ y * width), r5 = x1, r6 = width, r7 = col

	sub r13, 32

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

	// Trivial cases: <= 3 pixels ... use jump table

	cmp r6, 3
	bgtu more_than_3_pixels

	mov r8, r6
	mov r9, r5
	and r8, 0x3
	and r9, 0x3
	lsl r8
	lsl r8
	or  r8, r9	// r8 : {len[1:0], x1[1:0]}
	lsl r8
	
	ld r9, [r8, scanline_start_jump_table]
	bl [r9]

	ba done_scanline

	// More than 3 pixels: align to a word boundary... use jump table
more_than_3_pixels:

	//ba done_scanline

	mov r8, r5 // r8 = x1
	mov r9, 4
	and r8, 3
	bnz adjust

	mov r9, r4
	mov r8, r5
	lsr r8
	add r9, r8

	ba before_write_4pix_loop
adjust:
	sub r9, r8
	

	lsl r9
	lsl r9
	or  r8,r9
	lsl r8
	
	ld r9, [r8, scanline_start_jump_table]
	bl [r9]

before_write_4pix_loop:
	lsl r7
	ld r7, [r7, color_repeat_table_word]

write_4pix_loop:
	// Write 4 pixels at a time
	cmp r6, 4
	blt finish_scanline

	st.ex [r9], r7
	add r9, 2

	sub r6, 4
	ba write_4pix_loop
	
finish_scanline:

	cmp r6, 3
	bne not_3_pix

	and r7, 0xfff
	ld.ex r10, [r9]
	and r10, 0xf000
	or r10, r7
	st.ex [r9], r10
	ba done_scanline

not_3_pix:
	cmp r6, 2
	bne not_2_pix

	and r7, 0xff
	ld.ex r10, [r9]
	and r10, 0xff00
	or r10, r7
	st.ex [r9], r10
	ba done_scanline

not_2_pix:
	cmp r6, 1
	bne not_1_pix

	and r7, 0xf
	ld.ex r10, [r9]
	and r10, 0xfff0
	or r10, r7
	st.ex [r9], r10
	ba done_scanline

not_1_pix:

done_scanline:

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
