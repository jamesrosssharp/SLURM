	.org 0x0000

// Vector table

RESET_VEC:
	ba 0x100
HSYNC_VEC:
	ba dummy_handler
VSYNC_VEC:
	ba dummy_handler
AUDIO_VEC:
	ba dummy_handler
SPI_FLASH:
	ba dummy_handler
VECTORS:
	.times 22 dw 0x0000

dummy_handler:
	mov r1, 'I'
	out [r0, 0x6001], r1
	mov r1, 'N'
	out [r0, 0x6001], r1
	mov r1, 'T'
	out [r0, 0x6001], r1
	mov r1, 0x0d
	out [r0, 0x6001], r1
	mov r1, 0x0a
	out [r0, 0x6001], r1
	//iret // TODO - fix this
	mov r1, 0x0f
	out [r0, 0x7001], r1
	dw 0x0101

	.end
