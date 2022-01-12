        .org 0h

UART_TX  equ	0x0000

		nop
		nop
		nop
loop:
		mov r1, 'A'
		nop
		nop
		nop
		nop
		out [r0, UART_TX], r1
		nop
		nop
		nop
		nop
		ba loop


		.end
