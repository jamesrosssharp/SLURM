
	.org 0

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
	sti
	ld  r1, [some_bytes + 2]
	ld  r2, [some_bytes + 4]
	mov r3, 5
loop:
	add r1, r2
	sub r3, 1
	nop
	bnz loop

	sleep	

dummy_handler:
	mov r7, 0xaa55
	iret

some_bytes:
	dw 0x6969
	dw 0x0003
	dw 0x0004

	.end
