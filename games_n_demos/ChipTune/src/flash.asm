
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

