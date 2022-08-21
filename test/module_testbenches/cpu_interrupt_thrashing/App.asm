.org 0x0000

TRACE_CHAR_PORT equ 0x6001
TRACE_DEC_PORT	equ 0x6000
TRACE_HEX_PORT	equ 0x6002

	// Vector table

my_vector_table:
RESET_VEC:
	ba start
HSYNC_VEC:
	ba hsync_handler
VSYNC_VEC:
	ba vsync_handler
AUDIO_VEC:
	ba audio_handler
SPI_FLASH:
	ba flash_handler
GPIO_VEC:
	ba gpio_handler
VECTORS:
	.times 20 dw 0x0000


hsync_handler:
	st [r13, -2], r1
	mov r1, 'H'
	out [r0, TRACE_CHAR_PORT], r1
	ld r1, [r13, -2]
	iret
	
vsync_handler:
	st [r13, -2], r1
	mov r1, 'V'
	out [r0, TRACE_CHAR_PORT], r1
	ld r1, [r13, -2]
	iret
	
audio_handler:
	st [r13, -2], r1
	mov r1, 'A'
	out [r0, TRACE_CHAR_PORT], r1
	ld r1, [r13, -2]
	iret
	
flash_handler:
	st [r13, -2], r1
	mov r1, 'F'
	out [r0, TRACE_CHAR_PORT], r1
	ld r1, [r13, -2]
	iret

gpio_handler:
	st [r13, -2], r1
	mov r1, 'G'
	out [r0, TRACE_CHAR_PORT], r1
	ld r1, [r13, -2]
	iret

	.padto 0x8000
start:
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
	mov r13, 0x7ffe
	mov r14, r0
	mov r15, r0

	// Enable interrupts

	sti

	// Spin in a loop, outputting characters to 
	// trace port

	
outer:

	mov r2, 1
	mov r3, 1
	mov r4, 1

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4

	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	add r4, r3	
	mov r3, r2
	mov r2, r4
	out [r0, TRACE_DEC_PORT], r4
	
	ba outer	


	.times 256 dw 0x0
	


	.end
