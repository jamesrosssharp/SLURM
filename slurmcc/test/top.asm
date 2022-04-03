	.org 0h

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
	bl main
die:
	ba die

putc:
	out [r0, 0], r4
putc.loop:
	in r4, [r0, 1]
	or r4,r4
	bz putc.loop
	ret

exit:
	out [r0, 0x6006], r0 

dummy_handler:
	iret

