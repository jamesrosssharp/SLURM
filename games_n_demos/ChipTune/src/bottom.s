


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
	char* sample_start;
	char* sample_end;

	char* loop_start;
	char* loop_end;

	char* sample_pos;
	short frequency;	// 0 = channel off
	
	char  volume;
	char  loop;	// 1 = loop, 0 = no loop

	char  bits;	// 1 = 16 bit, 0 = 8 bit
	char  pad;
};

We store 8 channels worth of channel_t here to tell us what to mix.
*/

channel_info:
	.times 8*8 dw 0 
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

	in r2, [AUDIO_LEFT_PTR]
	and r2, 0x100
	xor r2, 0x100 ; r2: mix index into buffer
	
	// Outer Loop - for 256 blockram words...

	mov r3, 256	; r3: outer loop count
mix_audio.outer_loop:

	// Middle loop - for each of two stereo channels
	mov r4, 2	; r4: middle loop count
mix_audio.middle_loop:

	// Inner loop - for each of the 4 channels, mix data
	mov r5, 4	; r5: inner loop count 
mix_audio.inner_loop:



	sub r5, 1
	bnz mix_audio.inner_loop

	sub r4, 1
	bnz mix_audio.middle_loop

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

