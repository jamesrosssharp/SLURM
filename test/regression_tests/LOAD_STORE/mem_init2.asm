	.org 0x4000

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002


	mov r2, banner
	bl tr_string

	mov r3, 0x8000
	mov r4, 0xaa55
	bl  perform_store

	mov r3, 0x8000
	bl  perform_load

	
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

/* ROUTINE: perform_store 
 *
 *	IN: r3 = address to store
 *		r4 = value
 *
 *	Trashes: r0, r1, r5
 *
 */

perform_store:
	mov r5, r15
	mov r2, string1
	bl tr_string

	mov	r2, r3
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov r2, r4
	bl tr_hex

	mov r2, 0xa
	bl tr_char

	st [r3], r4	

	mov r15, r5
	ret

/* ROUTINE: perform_load 
 *
 *	IN: r3 = address to load
 *
 *  OUT: r4 = value
 *
 *	Trashes: r0, r1, r5
 *
 */

perform_load:
	mov r5, r15
	mov r2, string2
	bl tr_string

	mov	r2, r3
	bl tr_hex

	ld r4, [r3]	
	
	mov r2, r4
	bl tr_hex

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret


banner:
	dw "Load / Store Regression Test\n========================\n\n"
	dw 0

string1:
	dw "Store to address: "
	dw 0

string2: 
	dw "Load from address: "
	dw 0

	.end
