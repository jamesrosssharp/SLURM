/*

	SlurmDemo : A demo to show off SlURM16

effect4.asm : low level routines

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

	.global		clear_fb
	.function	clear_fb
clear_fb:
	// r4 = framebuffer, r5 = color word

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

	mov r8, r4
	add r8, 2
	mov r9, r8
	add r9, 2
	mov r10, r9
	add r10, 2

	mov r6, 128
y_loop:
	mov r7, 16
x_loop:
	st.ex [r4], r5
	st.ex [r8], r5
	st.ex [r9], r5
	st.ex [r10], r5
	add r4, 8
	add r8, 8
	add r9, 8
	add r10, 8
	sub r7, 1
	bnz x_loop
	sub r6, 1
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

	.function flip_buffer_spr
	.global flip_buffer_spr

flip_buffer_spr:

	// r4 : framebuffer word addr

	out [r0, 0x5300], r4
	add r4, 16
	out [r0, 0x5301], r4
	add r4, 16
	out [r0, 0x5302], r4
	add r4, 16
	out [r0, 0x5303], r4
	add r4, 16
	ret
	
	.endfunc

	.function put_pixel
	.global put_pixel
put_pixel:
	// r4 = fb, r5 = x, r6 = y, r7 = col

	mul r6, 256
	add r6, r5

	rln r5, r7
	mov r2, r7
	test r6, 1
	mov.z r5, r2

	asr r6

	add r4, r6

	ldb.ex r2, [r4]
	or r5, r2
	stb.ex [r4], r5

	ret

	.endfunc

	.function enter_critical
	.global enter_critical
enter_critical:
	cli
	ret

	.function leave_critical
	.global leave_critical
leave_critical:
	sti
	ret



	.endfunc


	.end
