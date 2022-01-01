		.org 0x4000
	
TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001

	
		mov r2, banner
		bl tr_string
	
		mov r2, string1
		bl tr_string

		mov r2, 20
		mov r4, 30
		add r2, r4
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
		mov r0, 0
tr_string_loop:
		ld r1, [r2]
		or r1, r1
		bz tr_string_die
		inc r2
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

banner:
	dw "\n\nALU Regression Test\n===================\n\n"
	dw 0
string1:
	dw "20 + 30 ="
	dw 0

	.end
