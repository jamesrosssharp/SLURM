	.org 0x0000

	mov r1, 3
	mov r2, 4
	nop
	nop
	nop
	add r1, r2

die:
	ba [r0, die]

	mov r3, 5
	mov r4, 6

	.end
