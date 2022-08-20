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
	ba flash_handler
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
	st [r13, -2], r1

	mov r1, 0xffff
	out [r0, 0x7001], r1

	ld r1, [r13, -2]
	iret

	.align 0x100

flash_handler:
	st [r13, -2], r1

	mov r1, 1
	st [flash_complete], r1
	mov r1, 8
	out [r0, 0x7001], r1
	
	ld r1, [r13, -2]
	iret

	.align 0x100

vsync_handler:
	// Store flags
	st [r13, -2], r1
	
	stf r1
	sub r13, 4
	st [r13, 0], r1	

	mov r1, 2
	out [r0, 0x7001], r1

	sub r13, 32
	st  [r13, 2], r15
	st  [r13, 4], r2
	st  [r13, 6], r4
	st  [r13, 8], r5
	st  [r13, 10], r6
	st  [r13, 12], r7
	st  [r13, 14], r8
	st  [r13, 16], r9
	st  [r13, 18], r10
	st  [r13, 20], r11
	st  [r13, 22], r12
	st  [r13, 24], r3
	nop	

	bl do_vsync
	
	ld r15, [r13,2]
	ld r2,  [r13,4]
	ld r4,  [r13, 6]
	ld r5,  [r13, 8]
	ld r6,  [r13, 10]
	ld r7,  [r13, 12]
	ld r8,  [r13, 14]
	ld r9,  [r13, 16]
	ld r10,  [r13, 18]
	ld r11,  [r13, 20]
	ld r12,  [r13, 22]
	ld r3,  [r13, 24]
	nop	

	add r13, 32

	// Restore flags
	ld r1, [r13, 0]
	add r13, 4
	rsf r1

	ld r1, [r13, -2]
	iret

	.align 0x100

audio_handler:
	st [r13, -2], r1

	mov r1, 1
	st [audio], r1
	mov r1, 4
	out [r0, 0x7001], r1
	
	ld r1, [r13, -2]
	iret

	.align 0x100

vsync_handler_2:
	st [r13, -2], r1

	mov r1, 1
	st [vsync], r1
	mov r1, 2
	out [r0, 0x7001], r1
	
	ld r1, [r13, -2]
	iret


