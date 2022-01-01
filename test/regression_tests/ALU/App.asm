		.org 0x4000
	
TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002

	
		mov r2, banner
		bl tr_string
	
		// Addition test

		mov r2, string1
		bl tr_string

		mov r3, 20
		mov r4, 30
		bl add_num

		mov r3, 56
		mov r4, 127
		bl add_num

		mov r3, 0xffff
		mov r4, 1
		bl add_num

		// Subtraction test

		mov r2, string2
		bl tr_string

		mov r3, 20
		mov r4, 30
		bl sub_num

		mov r3, 56
		mov r4, 127
		bl sub_num

		mov r3, 0xffff
		mov r4, 1
		bl sub_num

		// Test AND

		mov r2, string3
		bl tr_string

		mov r3, 0x0100
		mov r4, 0x03ff
		bl and_num

		mov r3, 0xff00
		mov r4, 0x00ff
		bl and_num

		mov r3, 0xaa55
		mov r4, 0xffee
		bl and_num

		// Test OR

		mov r2, string4
		bl tr_string

		mov r3, 0x0100
		mov r4, 0x03ff
		bl or_num

		mov r3, 0xff00
		mov r4, 0x00ff
		bl or_num

		mov r3, 0xaa55
		mov r4, 0xffee
		bl or_num

		// Test XOR
		
		mov r2, string5
		bl tr_string

		mov r3, 0x0100
		mov r4, 0x03ff
		bl xor_num

		mov r3, 0xff00
		mov r4, 0x00ff
		bl xor_num

		mov r3, 0xaa55
		mov r4, 0xffee
		bl xor_num

		// Print end banner
		mov r2, banner_end
		bl tr_string

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

/*
 *
 *  ROUTINE: add_num
 *
 *	in: r3 = num1, r4 = num2
 *
 *  trashes: r0, r2, r5
 */

add_num:
	mov r5, r15

	mov r2, r3
	bl tr_decimal
	mov r2, '+'
	bl tr_char

	mov r2, r4
	bl tr_decimal
	mov r2, '='
	bl tr_char

	mov r2,r3
	add r2, r4
	bl tr_decimal

	bnz add_num_no_Z
	mov r2, 'Z'
	bl tr_char	

add_num_no_Z:

	bns add_num_no_S
	mov r2, 'S'
	bl tr_char	

add_num_no_S:

	bnc add_num_no_C
	mov r2, 'C'
	bl tr_char

add_num_no_C:

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret

/*
 *
 *  ROUTINE: sub_num
 *
 *	in: r3 = num1, r4 = num2
 *
 *  trashes: r0, r2, r5
 */

sub_num:
	mov r5, r15

	mov r2, r3
	bl tr_decimal
	mov r2, '-'
	bl tr_char

	mov r2, r4
	bl tr_decimal
	mov r2, '='
	bl tr_char

	mov r2,r3
	sub r2, r4
	bl tr_decimal

	bnz sub_num_no_Z
	mov r2, 'Z'
	bl tr_char	

sub_num_no_Z:

	bns sub_num_no_S
	mov r2, 'S'
	bl tr_char	

sub_num_no_S:

	bnc sub_num_no_C
	mov r2, 'C'
	bl tr_char

sub_num_no_C:

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret

/*
 *
 *  ROUTINE: and_num
 *
 *	in: r3 = num1, r4 = num2
 *
 *  trashes: r0, r2, r5
 */

and_num:
	mov r5, r15

	mov r2, r3
	bl tr_hex
	mov r2, '&'
	bl tr_char

	mov r2, r4
	bl tr_hex
	mov r2, '='
	bl tr_char

	mov r2,r3
	and r2, r4
	bl tr_hex

	bnz and_num_no_Z
	mov r2, 'Z'
	bl tr_char	

and_num_no_Z:

	bns and_num_no_S
	mov r2, 'S'
	bl tr_char	

and_num_no_S:

	bnc and_num_no_C
	mov r2, 'C'
	bl tr_char

and_num_no_C:

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret

/*
 *
 *  ROUTINE: or_num
 *
 *	in: r3 = num1, r4 = num2
 *
 *  trashes: r0, r2, r5
 */

or_num:
	mov r5, r15

	mov r2, r3
	bl tr_hex
	mov r2, '|'
	bl tr_char

	mov r2, r4
	bl tr_hex
	mov r2, '='
	bl tr_char

	mov r2,r3
	or r2, r4
	bl tr_hex

	bnz or_num_no_Z
	mov r2, 'Z'
	bl tr_char	

or_num_no_Z:

	bns or_num_no_S
	mov r2, 'S'
	bl tr_char	

or_num_no_S:

	bnc or_num_no_C
	mov r2, 'C'
	bl tr_char

or_num_no_C:

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret

/*
 *
 *  ROUTINE: xor_num
 *
 *	in: r3 = num1, r4 = num2
 *
 *  trashes: r0, r2, r5
 */

xor_num:
	mov r5, r15

	mov r2, r3
	bl tr_hex
	mov r2, '^'
	bl tr_char

	mov r2, r4
	bl tr_hex
	mov r2, '='
	bl tr_char

	mov r2,r3
	xor r2, r4
	bl tr_hex

	bnz xor_num_no_Z
	mov r2, 'Z'
	bl tr_char	

xor_num_no_Z:

	bns xor_num_no_S
	mov r2, 'S'
	bl tr_char	

xor_num_no_S:

	bnc xor_num_no_C
	mov r2, 'C'
	bl tr_char

xor_num_no_C:

	mov r2, 0xa
	bl tr_char

	mov r15, r5
	ret





banner:
	dw "\n\nTEST_START\nALU Regression Test\n===================\n\n"
	dw 0

string1:
	dw "ADDITION:\n"
	dw 0

string2:
	dw "SUBTRACTION:\n"
	dw 0

string3:
	dw "AND:\n"
	dw 0

string4:
	dw "OR:\n"
	dw 0

string5:
	dw "XOR:\n"
	dw 0

banner_end:
	dw "\n\nTEST_END\n\nsee you!\n"
	dw 0

	.end
