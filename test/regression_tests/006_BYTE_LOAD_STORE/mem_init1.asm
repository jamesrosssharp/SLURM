	.org 0x0000
	.padto 0x200

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002


	mov r2, banner
	bl tr_string

	mov r3, 0x2001 //0x8000
	mov r4, 0x55
	bl  perform_store

	mov r3, 0x2001 //0x8000
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
tr_string_loop:
		ldb r1, [r2, 0]
		or r1, r1
		bz tr_string_die
		add r2, 1
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
	out [r0, TRACE_CHAR_PORT], r2
	ret

/*
 *
 *	ROUTINE: tr_hex
 *
 */
tr_hex:
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

	stb [r3, 0], r4	

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

	mov r2, ' '
	bl tr_char

	mov r4, 0xdead
	ldb r4, [r3, 0]	
	
	mov r2, r4
	bl tr_hex

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret

/* ROUTINE: perform_double_store 
 *
 *	IN: r3 = address to store
 *		r4 = value
 *		r6 = address 2
 *		r7 = value 2
 *
 *	Trashes: r0, r1, r5
 *
 */

perform_double_store:
	mov r5, r15
	mov r2, string3
	bl tr_string

	mov	r2, r3
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov r2, r4
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov	r2, r6
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov r2, r7
	bl tr_hex

	mov r2, 0xa
	bl tr_char

	st [r3, 0], r4
	st [r6, 0], r7	

	mov r15, r5
	ret

/* ROUTINE: perform_double_load 
 *
 *	IN: r3, r6 = address to load
 *
 *  OUT: r4, r7 = values
 *
 *	Trashes: r0, r1, r5
 *
 */

perform_double_load:
	mov r5, r15
	mov r2, string4
	bl tr_string

	mov	r2, r3
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov	r2, r6
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov r4, r0
	mov r7, r0
	ld r4, [r3, 0]
	ld r7, [r6, 0]	
	
	mov r2, r4
	bl tr_hex

	mov r2, ' '
	bl tr_char

	mov r2, r7
	bl tr_hex

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret




banner:
	db "Load / Store Regression Test\n========================\n\n"
	.align 2
	dw 0

string1:
	db "Store to address: "
	.align 2
	dw 0

string2: 
	db "Load from address: "
	.align 2
	dw 0

string3:
	db "Double store to addresses: "
	.align 2
	dw 0

string4:
	db "Double load from addresses: "
	.align 2
	dw 0

	.end
