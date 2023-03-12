/*

notemul.asm: Routines for working with frequency and slide tables

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/



//
//
//	Multiply 32 bit frequency by c5 speed and divide to get frequency for playing 	
//
//
	.section text

	.function note_mul_asm
	.global note_mul_asm
note_mul_asm:
	// r4 = note_lo
	// r5 = note_hi
	// r6 = c5speed

	sub r13, 32

	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12

	mov r8, r4
	umulu r8, r6

	mov r9, r5
	mov r10, r5
	mul r9, r6
	umulu r10, r6
	
	add r9, r8
	nop
	nop
	nop
	adc r10, 0
	
	mov r2, r9


	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]

	add r13, 32

	ret

	.endfunc

	.function note_mul_asm_hi
	.global note_mul_asm_hi 

note_mul_asm_hi:
	// r4 = note_lo
	// r5 = note_hi
	// r6 = c5speed

	sub r13, 32

	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12

	mov r8, r4
	umulu r8, r6

	mov r9, r5
	mov r10, r5
	mul r9, r6
	umulu r10, r6
	
	add r9, r8
	adc r10, 0
	
	mov r2, r10


	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]

	add r13, 32

	ret

	.endfunc

	.function note_mul32_asm
	.global note_mul32_asm

	/* Multiply by slide tables which are in 16:16 fixed point format. This is a 32x 32 multiply, and we return bits [31:16] of the 64 bit output */
note_mul32_asm:	

	/*	
		in:
			 R4	= B
			 R5     = A
			 R6     = D
			 R7     = C

		Return:

			(A*D + B*C)lo + (B*D)hi

	*/ 

	sub r13, 32

	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12

	/* compute (A * D)lo */

	mov r8, r5
	mul r8, r6

	/* compute (B * C)lo */

	mov r9, r4
	mul r9, r7

	/* compute (A*D + B*C)lo */

	add r8, r9

	/* compute (B*D)hi */

	mov r10, r4
	umulu r10, r6
 
	mov r2, r8
	add r2, r10

	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]

	add r13, 32

	ret

	.endfunc

	.function note_mul32_asm_hi
	.global note_mul32_asm_hi

	/* Multiply by slide tables which are in 16:16 fixed point format. This is a 32x 32 multiply, and we return bits [47:32] of the 64 bit output */
note_mul32_asm_hi:	

	/*	
		in:
			 R4	= B
			 R5     = A
			 R6     = D
			 R7     = C

		Return:

			(AD + BC)hi + (AC)lo		

	*/ 

	sub r13, 32

	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12
	
	/* compute (A*C)lo */

	mov r2, r5
	mul r2, r7

	/* compute (AD + BC)hi */

	mov r8, r5
	umulu r8, r6

	mov r9, r4
	umulu r9, r7

	add r8, r9 /* r8 = (AD + BC) hi */

	mov r11, r8

	/* add carry from lo word */

	/* compute (A * D)lo */

	mov r8, r5
	mul r8, r6

	/* compute (B * C)lo */

	mov r9, r4
	mul r9, r7

	/* compute (A*D + B*C)lo */

	add r8, r9

	/* compute (B*D)hi */

	mov r10, r4
	umulu r10, r6
 
	mov r12, r8
	add r12, r10

	adc r2, 0
	
	/* compute result */	

	add r2, r11

	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]

	add r13, 32

	ret

	.endfunc



	.end
