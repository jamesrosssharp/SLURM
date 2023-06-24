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


.global mult_div_8_8
	.function mult_div_8_8
mult_div_8_8:
	// r4 = [x,y], r5 = mult, r6 = w

	/*
	 *	Compute:
	 *
	 *	x [8:8] * mult [8:8] -> [16:16] / w [8 : 8] -> sx [8 : 8]
	 *
	 *
	 */


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

	mov r7, r4
	mul r4, r5	// r4: x*mult lower 16 bits
	mulu r7, r5	// r7: x*mult upper 16 bits

	// r7:r4 = x*mult[16:16]

	/* compute binary division of r7:r4 by r6 - non-restoring binary division */

	/* R : remainder
 	 * 64 bits 
 	 * r8 [63:48], r9 [47:32], r10 [31:16], r11 [15:0] */	

	mov r8, r0
	mov r9, r0
	mov r10, r7
	mov r11, r4

	/* D : divisor
 	 * 64 bits
 	 * x32 [63:48], x33 [47:32], x34 [31:16], x35 [15:0]  
 	 */ 
	mov x32, r0
	mov x33, r6
	mov x34, r0
	mov x35, r0  

	/* loop counter */
	mov r12, 32

	/* Q: 32 bits */	
	mov r5, r0 // Lower 16 bits
	mov r6, r0 // Upper 16 bits

div_loop:
	cc
	rolc r5
	rolc r6

	test r8, 0x8000
	bz r_pos
r_neg:
	// R <- R*2 + D
	cc
	rolc r11
	rolc r10
	rolc r9
	rolc r8
	add r11, x35
	adc r10, x34
	adc r9, x33
	adc r8, x32

	ba do_div_loop
r_pos:	
	or r5, 1

	// R <- R*2 - D
	cc
	rolc r11
	rolc r10
	rolc r9
	rolc r8
	sub r11, x35
	sbb r10, x34
	sbb r9, x33
	sbb r8, x32

do_div_loop:
	sub r12, 1
	bnz div_loop

	mov r2, r5
	xor r5, 0xffff
	sub r2, r5
	mov r6, r2
	sub r6, 1
	test r8, 0x8000
	mov.nz r2, r6


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

.global mult_8_8_div_16
	.function mult_8_8_div_16
mult_8_8_div_16:
	// r4 = a, r5 = b
	// Compute a * b >> 4

	sub r13, 4

	st [r13, 0], r7 

	mov r2, r4
	mov r7, r4
	mul r2, r5
	mulu r7, r5

	rorc r7
	rorc r2

	rorc r7
	rorc r2

	rorc r7
	rorc r2

	rorc r7
	rorc r2

	ld r7, [r13, 0]

	add r13, 4

	ret

	.endfunc

	.end
