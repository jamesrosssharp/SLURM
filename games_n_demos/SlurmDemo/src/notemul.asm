//
//
//	Multiply 32 bit frequency by c5 speed and divide to get frequency for playing 	
//
//
	.section text

	.function note_mul_asm
	.global note_mul_asm
note_mul_asm:
	// r4 = note_lo
	// r5 = note_hi
	// r6 = c5speed

	sub r13, 32

	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12

	mov r8, r4
	umulu r8, r6

	mov r9, r5
	mov r10, r5
	mul r9, r6
	umulu r10, r6
	
	add r9, r8
	nop
	nop
	nop
	adc r10, 0
	
	mov r2, r9


	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]

	add r13, 32

	ret

	.endfunc

	.function note_mul_asm_hi
	.global note_mul_asm_hi 

note_mul_asm_hi:
	// r4 = note_lo
	// r5 = note_hi
	// r6 = c5speed

	sub r13, 32

	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12

	mov r8, r4
	umulu r8, r6

	mov r9, r5
	mov r10, r5
	mul r9, r6
	umulu r10, r6
	
	add r9, r8
	adc r10, 0
	
	mov r2, r10


	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]

	add r13, 32

	ret

	.endfunc

	.end
