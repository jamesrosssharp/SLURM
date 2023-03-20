/*

mixer2.asm: Audio mixer routines

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/



	.section mixer3.data

	.global pattern_A
// Pattern buffer A - 2k
pattern_A: 
	.times 64*8*4 db 0

	.global pattern_B
// Pattern buffer B - 2k
pattern_B:
	.times 64*8*4 db 0

//	dw 0
//	dw 0
// Buffer for samples - 24k
	.global music_heap
music_heap:
	.times 24*1024 db 0


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

	short base_freq_lo;	// 24
	short base_freq_hi;	// 26
	short volume_fine	// 28
};

We store 8 channels worth of channel_t here to tell us what to mix.
*/

CHANNEL_STRUCT_SIZE equ 30

CHANNEL_STRUCT_LOOP_START   equ 0
CHANNEL_STRUCT_LOOP_END	    equ 2
CHANNEL_STRUCT_SAMPLE_POS   equ 4
CHANNEL_STRUCT_FREQUENCY    equ 6
CHANNEL_STRUCT_FREQUENCY_HI equ 8
CHANNEL_STRUCT_PHASE	    equ 10
CHANNEL_STRUCT_PHASE_HI	    equ 12	
CHANNEL_STRUCT_VOLUME	    equ 14

	.section mixer3.data

	.global channel_info
channel_info:
	.times 8*CHANNEL_STRUCT_SIZE db 0 

	.section mixer3.text


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

	.global mix_audio_3
mix_audio_3:


	// Args: r4 = offset in buffer, r5 = mix count

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

/*	ld  r11, [r6, CHANNEL_STRUCT_SAMPLE_POS]	
	ld  r10, [r6, CHANNEL_STRUCT_FREQUENCY_HI]	
	ld  r1,  [r6, CHANNEL_STRUCT_FREQUENCY]		
	ld  r2,  [r6, CHANNEL_STRUCT_PHASE]		
	ld  r3,  [r6, CHANNEL_STRUCT_VOLUME]		
	ld  r8,  [r6, CHANNEL_STRUCT_LOOP_START]	
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]  	
*/	

	mov r6, channel_info 
	ld  r7,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r9,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r10, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r1,  [r6, CHANNEL_STRUCT_LOOP_END]

	add r6, CHANNEL_STRUCT_SIZE 
	
	mov x17, r7	// x17: sample pos (ch 1)
	mov x18, r8	// x18: freq hi
	mov x19, r9	// x19: freq
	mov x20, r10	// x20: phase
	mov x21, r11	// x21: volume
	mov x22, r12	// x22: loop start
	mov x23, r1	// x23: loop end

	ld  r7,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r9,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r10, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r1,  [r6, CHANNEL_STRUCT_LOOP_END]

	add r6, CHANNEL_STRUCT_SIZE 
	
	mov x24, r7	// x24: sample pos (ch 2)
	mov x25, r8	// x25: freq hi
	mov x26, r9	// x26: freq
	mov x27, r10	// x27: phase
	mov x28, r11	// x28: volume
	mov x29, r12	// x29: loop start
	mov x30, r1	// x30: loop end


mix_loop:
	mov r1, x17	// r1: sample pos
	mov r2, x20	// r2: phase
	mov r6, r0	// r6: mix var
	ldbsx  r3, [r1]  // load sample value; sign extend 8 bit to 16 bit
	add   r2, x19    // add freq lo to phase
	adc   r1, x18    // add with carry freq hi to sample pos
	mul   r3, x21    // multiply sample by volume
	mov   r7, x22    // move x22 (loop start) to temp reg
	mov   x20, r2	 // store phase in phase var
	cmp   x23, r1    // compare x23 (loop end) to sample pos
	mov.c r1,  r7 	 // if greater than (unsigned), move loop start to sample pos
	add   r6,  r3    // add sample value to mix var
	mov   x17, r1    // store sample pos
	
	mov r1, x24	// r1: sample pos
	mov r2, x27	// r2: phase
	ldbsx  r3, [r1]  // load sample value; sign extend 8 bit to 16 bit
	add   r2, x26    // add freq lo to phase
	adc   r1, x25    // add with carry freq hi to sample pos
	mul   r3, x28    // multiply sample by volume
	mov   r7, x30    // move x22 (loop start) to temp reg
	mov   x27, r2	 // store phase in phase var
	cmp   x30, r1    // compare x23 (loop end) to sample pos
	mov.c r1,  r7 	 // if greater than (unsigned), move loop start to sample pos
	add   r6,  r3    // add sample value to mix var
	mov   x24, r1    // store sample pos
	out   [r4, AUDIO_LEFT_CHANNEL_BRAM_LO], r6 // output sample
	add   r4, 1 // increment pointer
	sub   r5, 1 // decrement loop counter
	nop
	bnz   mix_loop // loop

	mov r6, channel_info 
	
	mov r7, x17	// x17: sample pos (ch 1)
	mov r8, x18	// x18: freq hi
	mov r9, x19	// x19: freq
	mov r10, x20	// x20: phase
	mov r11, x21	// x21: volume
	mov r12, x22	// x22: loop start
	mov r1,  x23	// x23: loop end

	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r7
	st  [r6, CHANNEL_STRUCT_FREQUENCY_HI], r8
	st  [r6, CHANNEL_STRUCT_FREQUENCY], r9
	st  [r6, CHANNEL_STRUCT_PHASE], r10
	st  [r6, CHANNEL_STRUCT_VOLUME], r11
	st  [r6, CHANNEL_STRUCT_LOOP_START], r12
	st  [r6, CHANNEL_STRUCT_LOOP_END], r1

	add r6, CHANNEL_STRUCT_SIZE

	mov r7, x24	// x24: sample pos (ch 2)
	mov r8, x25	// x25: freq hi
	mov r9, x26	// x26: freq
	mov r10, x27	// x27: phase
	mov r11, x28	// x28: volume
	mov r12, x29	// x29: loop start
	mov r1,  x30	// x30: loop end

	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r7
	st  [r6, CHANNEL_STRUCT_FREQUENCY_HI], r8
	st  [r6, CHANNEL_STRUCT_FREQUENCY], r9
	st  [r6, CHANNEL_STRUCT_PHASE], r10
	st  [r6, CHANNEL_STRUCT_VOLUME], r11
	st  [r6, CHANNEL_STRUCT_LOOP_START], r12
	st  [r6, CHANNEL_STRUCT_LOOP_END], r1

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
