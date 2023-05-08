/*

	SlurmDemo : A demo to show off SlURM16

math.asm : 8:8 fixed point math routines

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

	.global mult_8_8
	.function mult_8_8
mult_8_8:
	// R4 = a (8:8), R5 = b (8:8)
	mov r2, r4

	mul r4, r5
	mulu r2, r5
	
	bswap r4, r4
	bswap r2, r2
	and r4, 0xff
	and r2, 0xff00

	// return a*b (8:8)
	or r2, r4
	
	ret
	
	.endfunc

	.global dot4_8_8
	.function dot4_8_8
dot4_8_8:
	// r4 = a, r5 = b, r6 = a inc, r7 = b inc

	sub r13, 32

	// [r13, 0x30] = x_from, [r13, 0x34] = y_from
	
	st [r13, 0], r4 // a
	st [r13, 2], r5 // b
	st [r13, 4], r6 // a_inc
	st [r13, 6], r7 // b_inc
	st [r13, 8], r8
	st [r13, 10], r9
	st [r13, 12], r10
	st [r13, 14], r11
	st [r13, 16], r12
	st [r13, 18], r15

	// Multiply a1 * b1 -> 16:16

	ld r2, [r4, 0]
	ld r9, [r5, 0]
	mov r10, r2
	mul r2, r9
	mulu r10, r9

	add r4, r6
	add r5, r7

	ld r11, [r4, 0]
	ld r12, [r5, 0]
	mov r15, r11
	mul r11, r12
	mulu r15, r12

	add r2, r11
	adc r10, r15

	add r4, r6
	add r5, r7

	ld r11, [r4, 0]
	ld r12, [r5, 0]
	mov r15, r11
	mul r11, r12
	mulu r15, r12

	add r2, r11
	adc r10, r15

	add r4, r6
	add r5, r7

	ld r11, [r4, 0]
	ld r12, [r5, 0]
	mov r15, r11
	mul r11, r12
	mulu r15, r12

	add r2, r11
	adc r10, r15

	bswap r2, r2
	bswap r10, r10
	and r2, 0xff
	and r10, 0xff00

	or r2, r10

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
