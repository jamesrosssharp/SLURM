	.function asm_plasma
	.global asm_plasma

frame:
	dw 0

asm_plasma:

	sub r13, 64

	// Preserve registers
	st [r13, 0], r2
	st [r13, 2], r3
	st [r13, 4], r4
	st [r13, 6], r5
	st [r13, 8], r6
	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12
	st [r13, 22], r1
	st [r13, 24], r15 

	mov r6, 64	
	
	ld r7, [r0, frame]

	mov r8, r7

plasma_outer_loop:
	mov r5, 64
plasma_inner_loop:
	mov r9, r8
	stb [r4], r9
	add r8, 1
	add r4, 1
	sub r5, 1
	bnz plasma_inner_loop
	sub r6, 1
	bnz plasma_outer_loop

	//add r7, 1

	st [r0, frame], r7

	ld r2, [r13, 0]
	ld r3, [r13, 2]
	ld r4, [r13, 4]
	ld r5, [r13, 6]
	ld r6, [r13, 8]
	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]
	ld r1, [r13, 22]
	ld r15, [r13, 24]

	add r13, 64

	// Restore old stack pointer
	ret




	.endfunc

	.end
