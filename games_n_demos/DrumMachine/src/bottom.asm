


	.padto 0x8000

// Sound mixing routines + stack (located in this bank so we have easy fast to sample data)
// Must fit in 4kB

/*
struct channel_t {
	char* loop_start;	// 0
	
	char* loop_end;		// 2

	char* sample_pos;	// 4

	short frequency;	// 6, 0 = channel off
	
	short phase;		// 8
	
	short  volume;		// 10

	char  bits;		// 12, 1 = 16 bit, 0 = 8 bit
	char  pad;		// 13
};

We store 8 channels worth of channel_t here to tell us what to mix.
*/

CHANNEL_STRUCT_SIZE equ 14

CHANNEL_STRUCT_LOOP_START   equ 0
CHANNEL_STRUCT_LOOP_END	    equ 2
CHANNEL_STRUCT_SAMPLE_POS   equ 4
CHANNEL_STRUCT_FREQUENCY    equ 6
CHANNEL_STRUCT_PHASE	    equ 8	
CHANNEL_STRUCT_VOLUME	    equ 10
CHANNEL_STRUCT_LOOP	    equ 11
CHANNEL_STRUCT_BITS	    equ 12

channel_info:
	.times 8*7 dw 0 
old_stack:	// We save the previous stack here, and substitute to our own stack
	dw 0

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

audio_buffer_table:
	dw 0
	dw AUDIO_RIGHT_CHANNEL_BRAM_LO
	dw AUDIO_LEFT_CHANNEL_BRAM_LO

// Should be called in interrupt context. Will mix audio from the 8 channels 
mix_audio:
	st [r0, old_stack], r13
	mov r13, sound_stack_end
	sub r13, 32

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

	// Find out which half of the buffer the audio read pointer is in
	// And set mix address

	in r2, [r0, AUDIO_LEFT_PTR]
	and r2, 0x100
	xor r2, 0x100 // r2: mix index into buffer
	
	// Outer Loop - for 256 blockram words...

	mov r3, 256	// r3: outer loop count
mix_audio.outer_loop:

	// Middle loop - for each of two stereo channels
	mov r4, 2		// r4: middle loop count
	mov r6, channel_info 	// r6: channel info struct

mix_audio.middle_loop:

	mov r11, 0 // r11 : the mix variable
	// Inner loop - for each of the 4 channels, mix data
	mov r5, 4	// r5: inner loop count 
mix_audio.inner_loop:
	ld r9, [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld r8, [r6, CHANNEL_STRUCT_FREQUENCY]
	ld r10, [r6, CHANNEL_STRUCT_PHASE] 
	ld r12, [r6, CHANNEL_STRUCT_VOLUME]
	ldbsx r7, [r9]
	nop
	add r10, r8	// r10 : PHASE + delta
	adc r9, 0
	ld r8, [r6, CHANNEL_STRUCT_LOOP_END]
	st [r6, CHANNEL_STRUCT_PHASE], r10
	ld r10, [r6, CHANNEL_STRUCT_LOOP_START]
	mul  r7, r12
	cmp r8, r9
	nop
	mov.c r9, r10
	add  r11, r7
	nop
	nop
	st [r6, CHANNEL_STRUCT_SAMPLE_POS], r9
	add r6, CHANNEL_STRUCT_SIZE
	sub r5, 1
	nop
	nop
	bnz mix_audio.inner_loop

	lsl r4
	ld  r7, [r4, audio_buffer_table]
	nop
	nop
	lsr r4
	add r7, r2
	nop
	nop
	nop
	out [r7, 0], r11

	sub r4, 1
	nop
	nop
	bnz mix_audio.middle_loop

	add r2, 1
	sub r3, 1
	nop
	nop
	bnz mix_audio.outer_loop

	// Restore registers
	
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

//	add r13, 32

	// Restore old stack pointer
	ld r13, [r0, old_stack]
	ret

mix_audio_2:
	st [r0, old_stack], r13
	mov r13, sound_stack_end
	sub r13, 32

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

	// Find out which half of the buffer the audio read pointer is in
	// And set mix address

	in r2, [r0, AUDIO_RIGHT_PTR]
	and r2, 0x100
	xor r2, 0x100 		// r2: mix index into buffer
	st  [r13, 24], r2 	// sp + 24 <= audio back buffer index		

	// Mix Left channel 1

	//	r1 : mix index (scratch pad ram) + loop counter
	//	r2 : sample pos
	//	r3 : frequency
	// 	r4 : phase
	// 	r5 : volume
	// 	r6 : loop start 
	//	r7 : loop end
	//	r8 : pointer to channel structure
	//	r9 : sample

	mov r8, channel_info
	mov r12, 256
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	

mix_audio_2.channel1_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	sub   r12, 1
	mul   r9, r5
	nop
	cmp   r7, r2
	mov.c r2, r6
	test  r12, 0xffff
	out   [r12, SCRATCH_PAD], r9
	bnz   mix_audio_2.channel1_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE


	// Mix left channel 2
	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	

mix_audio_2.channel2_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	in    r10, [r12, SCRATCH_PAD]
	sub   r12, 1
	mul   r9, r5
	cmp   r7, r2
	mov.c r2, r6
	nop
	add   r10, r9
	nop
	nop
	nop
	test  r12, 0x8000
	out   [r12, SCRATCH_PAD + 1], r10
	bz   mix_audio_2.channel2_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE



	// Mix left channel 3
	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	

mix_audio_2.channel3_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	in    r10, [r12, SCRATCH_PAD]
	mul   r9, r5
	sub   r12, 1
	cmp   r7, r2
	mov.c r2, r6
	add   r10, r9
	nop
	test r12, 0x8000
	out   [r12, SCRATCH_PAD + 1], r10
	bz   mix_audio_2.channel3_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE

	// Mix left channel 4 + output

	// r10: in mix val
	// r11: out ptr 
	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	
	ld  r11, [r13, 24]

mix_audio_2.channel4_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	in    r10, [r12, SCRATCH_PAD]
	mul   r9, r5
	nop
	cmp   r7, r2
	mov.c r2, r6
	add   r11, 1
	add   r10, r9
	nop
	sub   r12, 1
	nop
	out   [r11, AUDIO_LEFT_CHANNEL_BRAM_LO - 1], r10
	bns   mix_audio_2.channel4_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE


	// Mix right channel 1 (5)
	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	

mix_audio_2.channel5_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	sub   r12, 1
	mul   r9, r5
	nop
	cmp   r7, r2
	mov.c r2, r6
	test  r12, 0x8000
	out   [r12, SCRATCH_PAD + 1], r9
	bz   mix_audio_2.channel5_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE


	// Mix right channel 2 (6) 

	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	

mix_audio_2.channel6_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	in    r10, [r12, SCRATCH_PAD]
	sub   r12, 1
	mul   r9, r5
	cmp   r7, r2
	mov.c r2, r6
	nop
	add   r10, r9
	nop
	nop
	nop
	test  r12, 0x8000
	out   [r12, SCRATCH_PAD + 1], r10
	bz   mix_audio_2.channel6_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE


	// Mix right channel 3 (7)

	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	


mix_audio_2.channel7_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	in    r10, [r12, SCRATCH_PAD]
	sub   r12, 1
	mul   r9, r5
	cmp   r7, r2
	mov.c r2, r6
	nop
	add   r10, r9
	nop
	nop
	nop
	test  r12, 0x8000
	out   [r12, SCRATCH_PAD + 1], r10
	bz   mix_audio_2.channel7_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	add   r8, CHANNEL_STRUCT_SIZE

	// Mix right channel 4 + output (8)

	mov r12, 255
	ld  r2, [r8, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r3, [r8, CHANNEL_STRUCT_FREQUENCY]
	ld  r4, [r8, CHANNEL_STRUCT_PHASE]
	ld  r5, [r8, CHANNEL_STRUCT_VOLUME]
	ld  r6, [r8, CHANNEL_STRUCT_LOOP_START]
	ld  r7, [r8, CHANNEL_STRUCT_LOOP_END]  	
	ld  r11, [r13, 24]

mix_audio_2.channel8_loop:
	ldbsx r9, [r2]
	add   r4, r3
	adc   r2, 0
	in    r10, [r12, SCRATCH_PAD]
	mul   r9, r5
	nop
	cmp   r7, r2
	mov.c r2, r6
	add   r11, 1
	add   r10, r9
	nop
	nop
	sub   r12, 1
	out   [r11, AUDIO_RIGHT_CHANNEL_BRAM_LO - 1], r10
	bns   mix_audio_2.channel8_loop

	st    [r8, CHANNEL_STRUCT_SAMPLE_POS], r2
	st    [r8, CHANNEL_STRUCT_PHASE], r4
	
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

//	add r13, 32

	// Restore old stack pointer
	ld r13, [r0, old_stack]
	ret





sound_stack:
	.times 256 dw 0
sound_stack_end:

// We will include samples here


