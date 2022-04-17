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
	// Set up stack
	mov r13, 0x7ffe
	bl main
	bl exit
die:
	ba die

putc:
	out [r0, 0], r4
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

