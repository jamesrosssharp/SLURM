/*

flash.asm: Flash helper routines

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/




/*
 *
 *	calculate_flash_offset_hi(base_lo, base_hi, offset_lo, offset_hi)
 *
 *	r4: base_lo
 *	r5: base_hi
 *	r6: offset_lo
 *	r7: offset_hi
 *
 *	returns total_offset_hi
 *
 */
	.function calculate_flash_offset_hi
	.global calculate_flash_offset_hi
calculate_flash_offset_hi:
	add r4, r6
	adc r5, r7
	mov r2, r5
	cc
	rorc r5
	rorc r4
	mov r2, r5
	ret
	.endfunc


/*
 *
 *	calculate_flash_offset_lo(base_lo, base_hi, offset_lo, offset_hi)
 *
 *	r4: base_lo
 *	r5: base_hi
 *	r6: offset_lo
 *	r7: offset_hi
 *
 *	returns total_offset_lo
 *
 */
	.function calculate_flash_offset_lo
	.global calculate_flash_offset_lo
calculate_flash_offset_lo:
	add r4, r6
	adc r5, r7
	mov r2, r5
	cc
	rorc r5
	rorc r4
	mov r2, r4
	ret
	.endfunc

/*
 *	add_offset
 *
 * 	r4: address of base lo
 *	r5: address of base hi
 *	r6: offset to add lo
 *	r7: offset to add hi
 *
 */
	.function add_offset
	.global add_offset
add_offset:
	sub r13, 16
	st [r13], r8
	st [r13,2], r9
	
	ld r8, [r4]
	ld r9, [r5]

	add r8, r6
	adc r9, r7

	st [r4], r8
	st [r5], r9

	ld r8, [r13]
	ld r9, [r13,2]
	add r13, 16
	ret
	.endfunc

	.end

