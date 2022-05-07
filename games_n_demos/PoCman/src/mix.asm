/*
 *
 *	Square wave mixer
 *
 */

AUDIO_FREQ equ (25125000 / 512)

__asm_mix_audio:
	//
	//	r4 = target address
	//	r5 = wave structure
	//
	//	wave structure:
	//
	//	struct Wave {
	//		short freq;
	//		short ampl;
	//		short phase;
	//		short state;
	//		short decay;
	//	};
	//
	//

	sub r13, 32
	st [r13,18], r6
	st [r13,20], r7
	st [r13,22], r8
	st [r13,24], r9
	st [r13,26], r10
	st [r13,28], r11
	st [r13,30], r12


	// r6 : loop counter
	mov r6, 256

	// r7 <- freq
	ld r7, [r5, 0]
	// r8 <- phase 
	ld r8, [r5, 4]
	// r10 <- amplitude
	ld r10, [r5, 2]
	// r11 <- state 
	ld r11, [r5, 6]
	ld r9, [r5, 8] 

__asm_mix_audio.mix_loop:
	// r8 <- phase + freq
	add r8, r7
	cmp r8, AUDIO_FREQ
	blt __asm_mix_audio.no_state_change
	xor r11, 0x1
	sub r8, AUDIO_FREQ
__asm_mix_audio.no_state_change:
	mov r12, r11
	sub r10, r9 // decay by decay amount
	bns __asm_mix_audio.no_decay_wrap
	mov r10, r0
	mov r9, r0
__asm_mix_audio.no_decay_wrap:
	cmp r10, 16000
	blt __asm_mix_audio.no_decay_wrap2
	mov r10, 16000
	mov r9, r0
__asm_mix_audio.no_decay_wrap2:
	lsl r12
	sub r12, 1
	mul r12, r10
	out [r4, 0], r12 	
	add r4, 1
	sub r6, 1
	bnz __asm_mix_audio.mix_loop

	st [r5, 6], r11 // store state
	st [r5, 4], r8	// store phase
	st [r5, 2], r10 // store amplitude
	st [r5, 8], r9

	ld r12, [r13, 30]
	ld r11, [r13, 28]
	ld r10, [r13, 26]
	ld r9, [r13, 24]
	ld r8, [r13, 22]
	ld r7, [r13, 20]
	ld r6, [r13, 18]

	add r13, 32
	ret

