

	.section mixer2.data

	.global pattern_A
// Pattern buffer A - 2k
pattern_A: 
	.times 64*8*4 db 0

	.global pattern_B
// Pattern buffer B - 2k
pattern_B:
	.times 64*8*4 db 0

	//dw 0
	//dw 0
// Buffer for samples - 24k
	.global music_heap
music_heap:
	.times 24*1024 db 0

	.section mixer2.text

// Sound mixing routines + stack (located in this bank so we have easy fast to sample data)
// Must fit in 4kB
/*
struct channel_t {
	char* loop_start;	// 0
	
	char* loop_end;		// 2

	char* sample_pos;	// 4

	short frequency;	// 6
	short frequency_hi;	// 8

	short phase;		// 10
	short phase_hi;		// 12
	
	short  volume;		// 14

	char  effect;		// 16
	char  param;		// 17
	char   base_note;	// 18
	char   note_deviation;  // 19 
	short  volume_effect;	// 20
	char   sample;          // 22
	char   pad;		// 23


};

We store 8 channels worth of channel_t here to tell us what to mix.
*/

CHANNEL_STRUCT_SIZE equ 24

CHANNEL_STRUCT_LOOP_START   equ 0
CHANNEL_STRUCT_LOOP_END	    equ 2
CHANNEL_STRUCT_SAMPLE_POS   equ 4
CHANNEL_STRUCT_FREQUENCY    equ 6
CHANNEL_STRUCT_FREQUENCY_HI equ 8
CHANNEL_STRUCT_PHASE	    equ 10
CHANNEL_STRUCT_PHASE_HI	    equ 12	
CHANNEL_STRUCT_VOLUME	    equ 14

old_stack:	// We save the previous stack here, and substitute to our own stack
	dw 0

	.global channel_info
channel_info:
	.times 8*CHANNEL_STRUCT_SIZE db 0 


// Register definitions for audio core

/*|  0x3000 - 0x31ff| Left Channel BRAM             | Write only  |
  |  0x3200 - 0x33ff| Right Channel BRAM            | Write only  |
  |  0x3400         | Control register (bit 0 = run)| Write only  |
  |  0x3401         | Left read pointer             | Read only   |
  |  0x3402         | Right read pointer            | Read only   |
*/

AUDIO_BASE equ 0x3000
AUDIO_LEFT_CHANNEL_BRAM_LO  equ (AUDIO_BASE + 0)
AUDIO_LEFT_CHANNEL_BRAM_HI  equ (AUDIO_BASE + 0x100)
AUDIO_RIGHT_CHANNEL_BRAM_LO equ (AUDIO_BASE + 0x200)
AUDIO_RIGHT_CHANNEL_BRAM_HI equ (AUDIO_BASE + 0x300)
AUDIO_CONTROL		equ (AUDIO_BASE + 0x400)
AUDIO_LEFT_PTR		equ (AUDIO_BASE + 0x401)
AUDIO_RIGHT_PTR		equ (AUDIO_BASE + 0x402)	

AUDIO_FREQ equ (25125000 / 512)

SCRATCH_PAD equ	0x8000 

.align 0x100

	.global mix_audio_2
mix_audio_2:


	// Args: r4 = offset in buffer, r5 = mix count

/*	cmp r4, 0
	bge pass1
	ret
pass1:
	cmp r4, 256
	blt pass2
	ret
pass2:
	cmp r5, 0
	bgt pass3
	ret
pass3:
	cmp r5, 256
	ble mixer2.okay
	ret


mixer2.okay:
*/

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

	in r2, [r0, AUDIO_RIGHT_PTR]
	and r2, 0x100
	xor r2, 0x100 		// r2: mix index into buffer
	add r4, r2		//

	
	//
	//	Registers: 
	//		r1 - r2 : working regs
	//		r4 : index in audio ram  
	//		r5 : mix count 
	//		r6 : channel struct offset
	//		r7 : mix variable
	//		r8 - r12 : working regs
	//		r15: working reg
	//

mix_audio_2.loop:

	mov r6, channel_info
	mov r7, r0

	// Mix channels 0 - 3

	mov r15, 2
mix_audio_2.loop_ch0_3:
	ld  r11, [r6, CHANNEL_STRUCT_SAMPLE_POS]	
	ld  r10, [r6, CHANNEL_STRUCT_FREQUENCY_HI]	
	ld  r1,  [r6, CHANNEL_STRUCT_FREQUENCY]		
	ld  r2,  [r6, CHANNEL_STRUCT_PHASE]		
	ld  r3,  [r6, CHANNEL_STRUCT_VOLUME]		
	ld  r8,  [r6, CHANNEL_STRUCT_LOOP_START]	
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]  	
	ldbsx r12, [r11]				
	add r2, r1					
	adc r11, r10 					
	nop						
	mul r12, r3					
	st [r6, CHANNEL_STRUCT_PHASE], r2		
	cmp r9, r11					
	mov.c r11, r8					
	add r7, r12					
	st [r6, CHANNEL_STRUCT_SAMPLE_POS], r11		
	add   r6, CHANNEL_STRUCT_SIZE  			

	ld  r11, [r6, CHANNEL_STRUCT_SAMPLE_POS]	
	ld  r10, [r6, CHANNEL_STRUCT_FREQUENCY_HI]	
	ld  r1,  [r6, CHANNEL_STRUCT_FREQUENCY]		
	ld  r2,  [r6, CHANNEL_STRUCT_PHASE]		
	ld  r3,  [r6, CHANNEL_STRUCT_VOLUME]		
	ld  r8,  [r6, CHANNEL_STRUCT_LOOP_START]	
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]  	
	ldbsx r12, [r11]				
	add r2, r1					
	adc r11, r10 					
	nop						
	mul r12, r3					
	st [r6, CHANNEL_STRUCT_PHASE], r2		
	cmp r9, r11					
	mov.c r11, r8					
	add r7, r12					
	st [r6, CHANNEL_STRUCT_SAMPLE_POS], r11		
	add   r6, CHANNEL_STRUCT_SIZE  			
	
	sub r15, 1
	bnz mix_audio_2.loop_ch0_3


	out   [r4, AUDIO_LEFT_CHANNEL_BRAM_LO], r7

	mov r7, r0

	// Mix channels 4 - 7

	mov r15, 2
mix_audio_2.loop_ch4_7:

	ld  r11, [r6, CHANNEL_STRUCT_SAMPLE_POS]	
	ld  r10, [r6, CHANNEL_STRUCT_FREQUENCY_HI]	
	ld  r1,  [r6, CHANNEL_STRUCT_FREQUENCY]		
	ld  r2,  [r6, CHANNEL_STRUCT_PHASE]		
	ld  r3,  [r6, CHANNEL_STRUCT_VOLUME]		
	ld  r8,  [r6, CHANNEL_STRUCT_LOOP_START]	
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]  	
	ldbsx r12, [r11]				
	add r2, r1					
	adc r11, r10 					
	nop						
	mul r12, r3					
	st [r6, CHANNEL_STRUCT_PHASE], r2		
	cmp r9, r11					
	mov.c r11, r8					
	add r7, r12					
	st [r6, CHANNEL_STRUCT_SAMPLE_POS], r11		
	add   r6, CHANNEL_STRUCT_SIZE  			

	ld  r11, [r6, CHANNEL_STRUCT_SAMPLE_POS]	
	ld  r10, [r6, CHANNEL_STRUCT_FREQUENCY_HI]	
	ld  r1,  [r6, CHANNEL_STRUCT_FREQUENCY]		
	ld  r2,  [r6, CHANNEL_STRUCT_PHASE]		
	ld  r3,  [r6, CHANNEL_STRUCT_VOLUME]		
	ld  r8,  [r6, CHANNEL_STRUCT_LOOP_START]	
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]  	
	ldbsx r12, [r11]				
	add r2, r1					
	adc r11, r10 					
	nop						
	mul r12, r3					
	st [r6, CHANNEL_STRUCT_PHASE], r2		
	cmp r9, r11					
	mov.c r11, r8					
	add r7, r12					
	st [r6, CHANNEL_STRUCT_SAMPLE_POS], r11		
	add   r6, CHANNEL_STRUCT_SIZE  			

	sub r15, 1
	bnz mix_audio_2.loop_ch4_7

	out   [r4, AUDIO_RIGHT_CHANNEL_BRAM_LO], r7

	add r4, 1
	sub r5, 1
	nop
	bnz mix_audio_2.loop

	
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

	.end
