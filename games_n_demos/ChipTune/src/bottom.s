


	.padto 0x8000

// Pattern buffer A - 2k
pattern_A: 
	.times 64*8*4 db 0

// Pattern buffer B - 2k
pattern_B:
	.times 64*8*4 db 0

// Buffer for samples - 24k
music_heap:
	.times 24*1024 db 0

// Sound mixing routines + stack (located in this bank so we have easy fast to sample data)
// Must fit in 4kB

/*
struct channel_t {
	char* sample_start;	// 0

	char* sample_end;	// 2

	char* loop_start;	// 4
	
	char* loop_end;		// 6

	char* sample_pos;	// 8

	short frequency;	// 10, 0 = channel off
	
	short phase;		// 12
	
	char  volume;		// 14
	char  loop;		// 15, 1 = loop, 0 = no loop

	char  bits;		// 16, 1 = 16 bit, 0 = 8 bit
	char  pad;		// 17
};

We store 8 channels worth of channel_t here to tell us what to mix.
*/

CHANNEL_STRUCT_SIZE equ 9

CHANNEL_STRUCT_SAMPLE_START equ 0
CHANNEL_STRUCT_SAMPLE_END   equ 2
CHANNEL_STRUCT_LOOP_START   equ 4
CHANNEL_STRUCT_LOOP_END	    equ 6
CHANNEL_STRUCT_SAMPLE_POS   equ 8
CHANNEL_STRUCT_FREQUENCY    equ 10
CHANNEL_STRUCT_PHASE	    equ 12	
CHANNEL_STRUCT_VOLUME	    equ 14
CHANNEL_STRUCT_LOOP	    equ 15
CHANNEL_STRUCT_BITS	    equ 16

channel_info:
	.times 8*9 dw 0 
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
	or r8, r8
	bz mix_audio.skip_channel
	

	ldb r10, [r6, CHANNEL_STRUCT_BITS]
	cmp r10, 1
	beq mix_audio.mix_8_bit

	// 16 bit	
	ld r7, [r9]

	ba mix_audio.do_mix
mix_audio.mix_8_bit:
	// 8 bit

	ldb r7, [r9]
	mul r7, 256

mix_audio.do_mix:

	ldb r12, [r6, CHANNEL_STRUCT_VOLUME]
	mul r12, 256

	mulu r7, r12
	add  r11, r7

	// Update

	ld r7, [r6, CHANNEL_STRUCT_PHASE] 
	add r7, r8	// r7 : PHASE + delta
	cmp r7, AUDIO_FREQ
	bnc mix_audio.no_sample_inc

	sub r7, AUDIO_FREQ
	st [r6, CHANNEL_STRUCT_PHASE], r7

	add r9, r10
	
	ldb r7, [r6, CHANNEL_STRUCT_LOOP] // r7: loop flag
	or  r7, r7
	bz  mix_audio.no_loop

	ld  r8, [r6, CHANNEL_STRUCT_LOOP_END]
	cmp r9, r8
	bnc mix_audio.done_sample_pos

	ld  r9, [r6, CHANNEL_STRUCT_LOOP_START]
	ba  mix_audio.done_sample_pos	

mix_audio.no_loop:

	ld  r8, [r6, CHANNEL_STRUCT_SAMPLE_END]
	cmp r9, r8
	bnc mix_audio.done_sample_pos

	st [r6, CHANNEL_STRUCT_FREQUENCY], r0
	ba mix_audio.skip_channel	
		

mix_audio.done_sample_pos:

	st [r6, CHANNEL_STRUCT_SAMPLE_POS], r9

mix_audio.no_sample_inc:  
mix_audio.skip_channel:

	add r6, CHANNEL_STRUCT_SIZE * 2
	sub r5, 1
	bnz mix_audio.inner_loop

	ld  r7, [r4, audio_buffer_table]
	add r7, r2
	out [r7, 0], r11

	sub r4, 1
	bnz mix_audio.middle_loop

	add r2, 1
	sub r3, 1
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

	// Restore old stack pointer
	ld r13, [r0, old_stack]
	ret

sound_stack:
	.times 256 dw 0
sound_stack_end:

