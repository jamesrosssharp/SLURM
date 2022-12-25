
	.org 0

	mov r1, 3
	mov r2, 4
	mov r3, 5
loop:
	add r1, r2
	sub r3, 1
	nop
	bnz loop

	sleep	



	.end
