
	.org 0

RESET_VEC:
	ba test1
HSYNC_VEC:
	ba interrupter
VSYNC_VEC:
	ba interrupter
AUDIO_VEC:
	ba test3
SPI_FLASH:
	ba test4
GPIO_VEC:
	ba test5
VECTORS:
	.times 20 dw 0x0000

/* Simple test loop */
test1:
	sti
	ld  r1, [some_bytes + 2]
	ld  r2, [some_bytes + 4]
	mov r3, 5
	st [some_bytes + 6], r1
loop:
	ld r1, [some_bytes + 6]
	add r1, r2
	sub r3, 1
	st [some_bytes + 6], r1
	nop
	bnz loop

	sleep	

/* Peasant multiply? */
test2:
	sti
	sleep

/* Sqrt using Newton's method? */	
test3:
	sti
	sleep

/* Don't know what to test here? */
test4:
	sti
	sleep

/* Don't know what to test here? */
test5:
	sti
	sleep
	

interrupter:
	mov r7, 0xaa55
	iret

some_bytes:
	dw 0x6969
	dw 0x0003
	dw 0x0004
	dw 0x0000

	.end
