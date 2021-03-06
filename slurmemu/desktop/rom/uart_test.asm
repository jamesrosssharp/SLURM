		.org 0x0000
//		.padto 0x100

UART_TX_REG 	equ 	0x0000
UART_TX_STATUS 	equ 	0x0001

		//mov r1, 'A'
		//out [r0, UART_TX_REG], r1

		// Print a banner


		mov r2, banner
loop:
		ldb r1, [r2, 0]
		add r2, 1
		or r1, r1
		bz die 
		out [r0, UART_TX_REG], r1
test_loop:
		in r3, [r0, UART_TX_STATUS]
		test r3, 1
		bz test_loop

		ba loop


die:
		out [r0, 0x6006], r0 // Exit emulator

		ba die

banner:
	db "Hello world!\n"
	.align 2
	dw 0

	.end
