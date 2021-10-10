		.org 0x4000

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS 	equ 	0x1001


		mov r0, the_string
loop:
		ld r1, [r0]
		inc r0
		or r1, r1
		bz die 
		st [UART_TX_REG], r1
test_loop:
		ld r2, [UART_TX_STATUS]
		test r2, 1
		bz test_loop

		ba loop

die:
		ba die

the_string:
	dw "Hello World from Boot Loaded program!\n"

	.end
