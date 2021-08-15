        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001

		mov r4, 0xffff	// Stack pointer; top of mem

		mov r0, the_string
loop:
		ld r1, [r0+]
		or r1, r1 
		bz die 
		st [UART_TX_REG], r1
		
test_loop:
		ld r2, [UART_TX_STATUS]
		test r2, 1
		bz test_loop

		ba loop

die:
		ba.r	die



the_string:
		dw "Hello world!\n"
		dw 0
		.end
