	.padto 200h

my_vector_table:
RESET_VEC:
	ba start
HSYNC_VEC:
	ba dummy_handler
VSYNC_VEC:
	ba dummy_handler
AUDIO_VEC:
	ba dummy_handler
SPI_FLASH:
	ba dummy_handler
GPIO_VEC:
	ba dummy_handler
VECTORS:
	.times 20 dw 0x0000

start:
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

dummy_handler:
	iret

.global str
.data
str:
	dw L.1
.global puts
.text
.text
puts:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r6
	st [r13, 22], r7
	st [r13, 24], r8
	st [r13, 26], r9
	st [r13, 28], r11
	st [r13, 30], r12
	mov r12,r4
	ba L.4
L.3:
	mov r4,r11
	bl putc
L.4:
	mov r9,r12
	mov r12, r9
	add r12,1
	ldb r9,[r9]
	mov r11,r9
	mov r9,r9
	cmp r9,r0
	bne L.3
L.2:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r6, [r13, 20]
	ld r7, [r13, 22]
	ld r8, [r13, 24]
	ld r9, [r13, 26]
	ld r11, [r13, 28]
	ld r12, [r13, 30]
	add r13,32
	ret
.global main
.text
main:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r6
	st [r13, 22], r7
	st [r13, 24], r8
	st [r13, 26], r9
	ld r4,[str]
	bl puts
L.7:
L.8:
	ba L.7
	mov r2,r0
L.6:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r6, [r13, 20]
	ld r7, [r13, 22]
	ld r8, [r13, 24]
	ld r9, [r13, 26]
	add r13,32
	ret
.data
L.1:
	db 0x48
	db 0x65
	db 0x6c
	db 0x6c
	db 0x6f
	db 0x20
	db 0x77
	db 0x6f
	db 0x72
	db 0x6c
	db 0x64
	db 0x21
	db 0xa
	db 0x0
.align 2
	.end

