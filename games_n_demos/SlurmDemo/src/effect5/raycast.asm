/*

	SlurmDemo : A demo to show off SlURM16

raycast.asm : raycasting demo renderer heavy lifting

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

	.global mul_1616_1616_div65536
	.function   mul_1616_1616_div65536
mul_1616_1616_div65536:
	sub r13, 32

	// r4 = AB short[3]*, r5 = D tan/cot lo, r6 = C tan/cot hi
	//
	//	Multiply A 16: B 16 x C 16: D 16 -> 32:32, return middle 16:16 (bits [47:16]) in array in r4
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

	ld r7, [r4] 	// r7 = B	
	ld r8, [r4, 2]  // r8 = A

	// Compute B*D 

	mov r9, r7
	mov r10, r7
	mul r9, r5
	umulu r10, r5	// r10:r9 = B*D = k:w[0]

	mov r2, r10 // r2 = k

	// Compute A*D 
	mov r9, r8
	mov r10, r8
	mul r9, r5
	umulu r10, r5

	add r9, r2
	adc r10, r0   // r10:r9 = A*D + k = k:w[1]
	mov x32, r9   // x32 = w[1]	
	
	mov r2, r10 // r2 = w[2]

	// Compute B*C
	mov r9, r7
	mov r10, r7
	mul r9, r6
	umulu r10, r6
	
	add r9, x32
	adc r10, r0   // r10:r9 = B*C + w[1] = k:w[1]
	mov x32, r9   // x32 = w[1]

	mov r15, r10 // r15 =  k

	// Compute A*C
	mov r9, r8
	mov r10, r8
	mul r9, r6
	umulu r10, r6
	
	add r9, r2
	adc r10, r0
	add r9, r15
	adc r10, r0

	mov x33, r9	// x33 = w[2]
	mov x34, r10	// x34 = w[3] 

	// Now correct unsigned product

	test r8, 0x8000
	bz no_correct1 	

	mov r9, x33
	sub r9, r5
	mov x33, r9
	mov r9, x34
	sbb r9, r0
	sub r9, r6
	mov x34, r9

no_correct1:
	test r6, 0x8000
	bz no_correct2

	mov r9, x33
	sub r9, r7
	mov x33, r9
	mov r9, x34
	sbb r9, r0
	sub r9, r8
	mov x34, r9

no_correct2:

	mov r2, x32
	mov r9, x33
	mov r10, x34

	st [r4, 0], r2
	st [r4, 2], r9
	st [r4, 4], r10

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

	.global add_1616_1616
	.function   add_1616_1616
add_1616_1616:
	sub r13, 32

	// r4 = A short[3]*, r5 = B short[3]*
	//
	//	compute A + B
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

	ld r6, [r4]
	ld r7, [r4, 2]
	ld r8, [r4, 4]

	ld r9, [r5]
	ld r10, [r5, 2]
	ld r11, [r5, 4]

	add r6, r9
	adc r7, r10
	adc r8, r11

	st [r4], r6
	st [r4, 2], r7
	st [r4, 4], r8 

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
