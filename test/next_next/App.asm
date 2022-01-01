		.org 0x0000
	
TRACE_CHAR_PORT equ 0x6001

	
		mov r0, 0
		mov r2, string
	
loop:
		ld r1, [r2]
		or r1, r1
		bz die
		inc r2
		out [r0, TRACE_CHAR_PORT], r1
		ba loop

die:
		ba die


string:
	dw "\n\nHello world\n\n"

		.end
