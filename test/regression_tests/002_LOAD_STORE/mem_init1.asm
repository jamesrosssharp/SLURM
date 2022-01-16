	.org 0x0000
	.padto 0x100

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002


	mov r2, banner
	bl tr_string

	mov r3, 0x2000 //0x8000
	mov r4, 0xaa55
	bl  perform_store

	mov r3, 0x2000 //0x8000
	bl  perform_load

	mov r3, 0x2800 //0xc200
	mov r4, 0x55aa
	bl  perform_store

	mov r3, 0x2800 //0xc200
	bl  perform_load

	mov r3, 0x2100
	mov r4, 0xff00
	bl  perform_store

	mov r3, 0x2100
	bl  perform_load

	mov r3, 0x3f00
	mov r4, 0x1234
	bl  perform_store

	mov r3, 0x3f00
	bl  perform_load

	mov r3, 0x2800
	mov r4, 0x1234
	mov r6, 0x3f00
	mov r7, 0x4321
	bl perform_double_store

	mov r3, 0x2800
	bl  perform_load

	mov r3, 0x3f00
	bl  perform_load

	mov r3, 0x2800
	mov r6, 0x3f00
	bl perform_double_load

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

	st [r3, 0], r4	

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
	ld r4, [r3, 0]	
	
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
	dw "Load / Store Regression Test\n========================\n\n"
	dw 0

string1:
	dw "Store to address: "
	dw 0

string2: 
	dw "Load from address: "
	dw 0

string3:
	dw "Double store to addresses: "
	dw 0

string4:
	dw "Double load from addresses: "
	dw 0

	.end
