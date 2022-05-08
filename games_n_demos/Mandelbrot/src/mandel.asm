//
//	mandelbrot inner loop
//
//

// r4 = Re{c}, r5 = Im{c} in 1:7 fixed point 
mandel_loop:
	sub r13, 32	

	st [r13, 16], r6
	st [r13, 18], r7
	st [r13, 20], r8
	st [r13, 22], r9
	st [r13, 24], r10
	st [r13, 26], r11
	st [r13, 28], r12

	// r2: iteration count
	mov r2, 63

	// r6 : Re{z}, r7 : Im{z}
	mov r6, r4
	mov r7, r5

mandel_loop.loop:
	// compute Z^2
	// Re{Z^2} = Re{Z}^2 - Im{z}^2
	// Im{Z^2} = 2Re{Z}Im{Z}
	mov r8,r6
	mov r9,r7
	mov r10, r6
	mul r8,r8	
	mul r9,r9
	mul r10, r7
	nop
	sub r8,r9
	nop
	// r8: Re{Z^2} r9: Im{Z^2}, 2:14 fixed point
	// convert to 1:7 fixed point
	
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8

	// Z <- Z^2 + C 
	add r10, r5
	nop	
	add r8, r4
	nop

	// Store Z
	mov r7, r10
	mov r6, r8

	// Compute length
	asr r8
	asr r10
	nop
	mul r8, r8
	mul r10, r10
	nop
	nop
	add r8, r10
	nop
	nop

	// > 2?
	cmp r8, (1<<13)
	bgt mandel_loop.done 

	sub r2, 1
	bnz mandel_loop.loop
mandel_loop.done:

	lsr r2
	nop
	nop
	nop
	lsr r2



	ld r6, [r13,16]
	ld r7, [r13,18]
	ld r8, [r13,20]
	ld r9, [r13,22]
	ld r10, [r13,24]
	ld r11, [r13,26]
	ld r12, [r13,28]

	add r13, 32
	ret
