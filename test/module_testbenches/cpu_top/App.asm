	.org 0x0000

TRACE_CHAR_PORT equ 0x6001

	mov r1, 3
	mov r2, 4
	add r1, r2
	mov r3, 'A'
	out [r0, TRACE_CHAR_PORT], r3
	ld  r6, [r0, theVar]
	add r6, 1
	lsl r6
	lsl r6
	st [r0, theVar], r6
	bl subroutine
	
die:
	ba [r0, die]

	mov r3, 5
	mov r4, 6

subroutine:
	mov r7, 'B'
	nop
	nop
	nop
	out [r0, TRACE_CHAR_PORT], r7
	ret



theVar:
	dw 0xaa55

	.end
