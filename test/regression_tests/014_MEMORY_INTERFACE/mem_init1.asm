	.org 0x0000
	.padto 0x200

TRACE_DEC_PORT  equ 0x6000
TRACE_CHAR_PORT equ 0x6001
TRACE_HEX_PORT  equ 0x6002


		mov r1, 0x1234
		mov r2, 0x2345
		mov r3, 0x3456
		mov r4, 0x4567
	
		st [r0, 0x2000], r4
		mov r6, 0x8000
	//	nop
	//	nop
	
		st [r6, 0x0], r1
		st [r6, 0x2], r2
		st [r6, 0x4], r3
		ld r5, [r0, 0x2000]

die:
		sleep
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


banner:
	dw "Memory Interface Test\n========================\n\n"
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
