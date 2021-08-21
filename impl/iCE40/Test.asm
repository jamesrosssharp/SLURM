        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001

top:
		mov r0, the_string

//		mov r3, 'A'
		
run:
		ld  r3, [r0+]
		or  r3, r3
		bz  top
	
		st [UART_TX_REG], r3


/*test_loop:
		ld r2, [UART_TX_STATUS]
		test r2, 1
		bz test_loop
*/

		
		mov r1, 0x1fff
loopy:
		sub r1, 1
		bnz loopy


		ba run

/*
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
		mov r0, 0xffff
delay:
		mov r1, 0x20
delay_1:
		sub r1, 1
		bnz delay_1
	
		sub r0, 1
		bnz delay
		
		ba run
*/

the_string:
		dw "Hello world!\r\n"
		dw 0

		.end


