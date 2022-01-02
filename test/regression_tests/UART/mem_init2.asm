	.org 0x4000

UART_TX_REG 	equ 	0x0000
UART_TX_STATUS 	equ 	0x0001

		mov r6, 0
		mov r0, banner
loop:
		ld r1, [r0]
		inc r0
		or r1, r1
		bz die 
		out [r6, UART_TX_REG], r1
test_loop:
		in r2, [r6, UART_TX_STATUS]
		test r2, 1
		bz test_loop

		ba loop

die:
		ba die

banner:
	dw "Hello world!\n"
	dw 0

	.end
