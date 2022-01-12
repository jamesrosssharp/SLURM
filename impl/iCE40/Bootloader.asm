        .org 0h

UART_TX  equ	0x0000

		nop
		nop
		nop
loop:
		mov r1, 'A'
		out [r0, UART_TX], r1
		ba loop


		.end
