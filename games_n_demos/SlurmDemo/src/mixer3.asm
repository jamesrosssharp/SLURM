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
	mov r15, r4
	add r15, r2		//

	mov x17, r4 // x17 <- audio buffer index
	mov x18, r5 // x18 <- count
	mov x19, r15

	mov r6, channel_info 
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	add r4, SCRATCH_PAD - 1  

	ba  mix_loop.ch1

	.align 0x100

	/*
 	 *	Audio mixing: 25125000 Cks/s / 1024 / 256 ~= 100 frames / s
 	 *		      ~= 250,000 clocks / frame
 	 *	This routine: ~12 clocks * 8 channels * 256 = ~25,000 clocks / frame
 	 *		      
 	 *		      So we should only have 10% CPU usage...
 	 *
 	 * 	We will mix to the scratchpad RAM. Our interrupt handler will swap the buffers for us.
 	 *
 	 */
	
mix_loop.ch1:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r10 // output sample
	bnz   mix_loop.ch1 // loop

	mov r6, channel_info 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2


	mov r6, channel_info + CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD - 1  
	mov r5, x18

	in  r6, [r4, 1]

mix_loop.ch2:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	add   r6, r10
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r6 // output sample
	in    r6, [r4, 1]
	bnz   mix_loop.ch2 // loop

	mov r6, channel_info + CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2


	mov r6, channel_info + 2*CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD - 1  
	mov r5, x18

	in  r6, [r4, 1]

mix_loop.ch3:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	add   r6, r10
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r6 // output sample
	in    r6, [r4, 1]
	bnz   mix_loop.ch3 // loop

	mov r6, channel_info + 2*CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2

	mov r6, channel_info + 3*CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD - 1  
	mov r5, x18

	in  r6, [r4, 1]

mix_loop.ch4:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	add   r6, r10
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r6 // output sample
	in    r6, [r4, 1]
	bnz   mix_loop.ch4 // loop

	mov r6, channel_info + 3*CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2


	mov r6, channel_info + 4*CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2,  [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD + 0x100 - 1  
	mov r5, x18

	/*
 	 *	Audio mixing: 25125000 Cks/s / 1024 / 256 ~= 100 frames / s
 	 *		      ~= 250,000 clocks / frame
 	 *	This routine: ~12 clocks * 8 channels * 256 = ~25,000 clocks / frame
 	 *		      
 	 *		      So we should only have 10% CPU usage...
 	 *
 	 * 	We will mix to the scratchpad RAM. Our interrupt handler will swap the buffers for us.
 	 *
 	 */

	ba mix_loop.ch5

	.align 0x100
	
mix_loop.ch5:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r10 // output sample
	bnz   mix_loop.ch5 // loop

	mov r6, channel_info + 4*CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2


	mov r6, channel_info + 5*CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD + 0x100 - 1  
	mov r5, x18

	in  r6, [r4, 1]

mix_loop.ch6:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	add   r6, r10
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r6 // output sample
	in    r6, [r4, 1]
	bnz   mix_loop.ch6 // loop

	mov r6, channel_info + 5*CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2


	mov r6, channel_info + 6*CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD + 0x100 - 1  
	mov r5, x18

	in  r6, [r4, 1]

mix_loop.ch7:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	add   r6, r10
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r6 // output sample
	in    r6, [r4, 1]
	bnz   mix_loop.ch7 // loop

	mov r6, channel_info + 6*CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2

	mov r6, channel_info + 7*CHANNEL_STRUCT_SIZE
	ld  r1,  [r6, CHANNEL_STRUCT_SAMPLE_POS]
	ld  r8,  [r6, CHANNEL_STRUCT_FREQUENCY_HI]
	ld  r3,  [r6, CHANNEL_STRUCT_FREQUENCY]
	ld  r2, [r6, CHANNEL_STRUCT_PHASE]
	ld  r11, [r6, CHANNEL_STRUCT_VOLUME]
	ld  r12, [r6, CHANNEL_STRUCT_LOOP_START]
	ld  r9,  [r6, CHANNEL_STRUCT_LOOP_END]

	mov r4, x17
	add r4, SCRATCH_PAD + 0x100 - 1  
	mov r5, x18

	in  r6, [r4, 1]

mix_loop.ch8:
	ldbsx  r10, [r1]   // load sample value; sign extend 8 bit to 16 bit
	add   r2, r3       // add freq lo to phase
	adc   r1, r8       // add with carry freq hi to sample pos
	mul   r10, r11     // multiply sample by volume
	add   r4, 1        // increment pointer
	cmp   r9, r1       // compare x23 (loop end) to sample pos
	mov.c r1,  r12 	   // if greater than (unsigned), move loop start to sample pos
	add   r6, r10
	sub   r5, 1        // decrement loop counter
	out   [r4, 0], r6 // output sample
	in    r6, [r4, 1]
	bnz   mix_loop.ch8 // loop

	mov r6, channel_info + 7*CHANNEL_STRUCT_SIZE 
	st  [r6, CHANNEL_STRUCT_SAMPLE_POS], r1
	st  [r6, CHANNEL_STRUCT_PHASE], r2

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

	.global mix_audio_3_update

mix_audio_3_update:
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

	mov r6, r2

	add r2, AUDIO_LEFT_CHANNEL_BRAM_LO

	mov r3, SCRATCH_PAD
	mov r5, 0x100

update_loop:
	in r4, [r3, 0]
	add r3, 1
	out [r2, 0], r4
	add r2, 1
	sub r5, 1
	nop
	bnz update_loop

	mov r2, r6
	add r2, AUDIO_RIGHT_CHANNEL_BRAM_LO

	mov r3, SCRATCH_PAD + 0x100
	mov r5, 0x100

update_loop2:
	in r4, [r3, 0]
	add r3, 1
	out [r2, 0], r4
	add r2, 1
	sub r5, 1
	nop
	bnz update_loop2

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
