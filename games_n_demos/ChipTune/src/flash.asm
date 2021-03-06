
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

calculate_flash_offset_hi:
	add r4, r6
	adc r5, r7
	mov r2, r5
	cc
	rorc r5
	rorc r4
	mov r2, r5
		
	ret



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

calculate_flash_offset_lo:
	add r4, r6
	adc r5, r7
	mov r2, r5
	cc
	rorc r5
	rorc r4
	mov r2, r4
	ret


/*
 *	add_offset
 *
 * 	r4: address of base lo
 *	r5: address of base hi
 *	r6: offset to add lo
 *	r7: offset to add hi
 *
 */

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

