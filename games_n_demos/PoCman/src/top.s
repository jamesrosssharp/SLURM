	.org 200h

my_vector_table:
RESET_VEC:
	ba start
HSYNC_VEC:
	ba dummy_handler
VSYNC_VEC:
	ba vsync_handler
AUDIO_VEC:
	ba audio_handler
SPI_FLASH:
	ba dummy_handler
GPIO_VEC:
	ba dummy_handler
VECTORS:
	.times 20 dw 0x0000

start:
	// Zero regs (makes it easier to debug waveforms)
	mov r1, r0
	mov r2, r0
	mov r3, r0
	mov r4, r0
	mov r5, r0
	mov r6, r0
	mov r7, r0
	mov r8, r0
	mov r9, r0
	mov r10, r0
	mov r11, r0
	mov r12, r0

	// Copy vectors
	mov r1, r0
	mov r2, my_vector_table
	mov r3, 32
copy_loop:
	ld r4,[r2, 0]
	st [r1, 0], r4
	add r1, 2
	add r2, 2
	sub r3, 1
	bnz copy_loop

	// Set up stack
	mov r13, 0x7ffe
	bl main
	bl exit
die:
	sleep
	ba die

putc:
	out [r0, 0], r4
	nop
	nop
	nop
putc.loop:
	in r4, [r0, 1]
	or r4,r4
	bz putc.loop
	ret

trace_dec:
	out [r0, 0x6000], r4
	ret

trace_char:
	out [r0, 0x6001], r4
	ret

trace_hex:
	out [r0, 0x6002], r4
	ret

exit:
	out [r0, 0x6006], r0 
	ret

__out:
	out [r4, 0], r5
	ret

__in: 
	in r2, [r4, 0]
	ret

__sleep:
	sleep
	ret	

dummy_handler:
	mov r1, 0xffff
	out [r0, 0x7001], r1
	iret

vsync_handler:
	stf r1

	sub r13, 32
	st [r13, 16], r1
	st [r13, 18], r2
	st [r13, 20], r3
	st [r13, 22], r4
	st [r13, 24], r5
	st [r13, 26], r6
	st [r13, 28], r7
	st [r13, 30], r15
	


	mov r1, 0x2
	out [r0, 0x7001], r1
	bl	handle_vsync
	
	ld r1, [r13, 16]
	ld r2, [r13, 18]
	ld r3, [r13, 20]
	ld r4, [r13, 22]
	ld r5, [r13, 24]
	ld r6, [r13, 26]
	ld r7, [r13, 28]
	ld r15,[r13, 30]
	

	add r13, 32
	rsf r1

	iret

audio_handler:
	stf r1

	sub r13, 32

	st [r13, 16], r1
	st [r13, 18], r2
	st [r13, 20], r3
	st [r13, 22], r4
	st [r13, 24], r5
	st [r13, 26], r6
	st [r13, 28], r7
	st [r13, 30], r15
	
	mov r1, 0x4
	out [r0, 0x7001], r1
	bl	mix_audio

	ld r1, [r13, 16]
	ld r2, [r13, 18]
	ld r3, [r13, 20]
	ld r4, [r13, 22]
	ld r5, [r13, 24]
	ld r6, [r13, 26]
	ld r7, [r13, 28]
	ld r15,[r13, 30]
	
	add r13, 32

	rsf r1

	iret



