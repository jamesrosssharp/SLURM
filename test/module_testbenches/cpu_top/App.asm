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

	// Do a memcpy

	mov r1, 0xc000
	mov r2, 0x8000
	mov r3, 0xffff
loopy:
	ld r4, [r1, 0]
	st [r2, 0], r4
	add r1, 1
	add r2, 1
	sub r3, 1
	bnz loopy


	
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

	.padto 0xc000
	dw 0x0123
	dw 0x4567
	dw 0x89ab
	dw 0xcdef
	dw 0x0123
	dw 0x4567
	dw 0x89ab
	dw 0xcdef
	dw 0x0123
	dw 0x4567
	dw 0x89ab
	dw 0xcdef
	dw 0x0123
	dw 0x4567
	dw 0x89ab
	dw 0xcdef
	dw 0x0123
	dw 0x4567
	dw 0x89ab
	dw 0xcdef
	dw 0x0123
	dw 0x4567
	dw 0x89ab
	dw 0xcdef






	.end
