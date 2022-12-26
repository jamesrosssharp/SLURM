	.org 0x0000
	.padto 0x200

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002

		mov r2, banner
		bl tr_string
	
		mov r3, 5
		mov r2, 6

		cmp r2, 7
		mov.le r2, r3

		bl tr_decimal

		

die:
		ba die


/*
 *	ROUTINE: tr_string
 *
 *	IN: 	 r2 = address of string to trace
 *	TRASHES: r0, r1
 *
 */

tr_string:
tr_string_loop:
		ld r1, [r2, 0]
		or r1, r1
		bz tr_string_die
		add r2, 2
		out [r0, TRACE_CHAR_PORT], r1
		ba tr_string_loop
tr_string_die:
		ret

/*
 *	ROUTINE: tr_decimal
 *
 *  IN:	r2 = number to print
 *  TRASHES: r0
 */

tr_decimal:
	mov r0, 0
	out [r0, TRACE_DEC_PORT], r2
	ret

/*
 *
 *	ROUTINE: tr_char
 *
 */
tr_char:
	mov r0, 0
	out [r0, TRACE_CHAR_PORT], r2
	ret

/*
 *
 *	ROUTINE: tr_hex
 *
 */
tr_hex:
	mov r0, 0
	out [r0, TRACE_HEX_PORT], r2
	ret

banner:
	dw "Conditional Move Regression Test\n===================\n\n"
	dw 0

	.end
