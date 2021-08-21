        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001
GPIO_OUT_REG    equ     0x1100

top:
		mov r0, 'A'
		
run:
		st [UART_TX_REG], r0
		nop
		add r0, 1

		mov r1, 0x1f
		//mov r2, 1
		//st [GPIO_OUT_REG], r2
loopy:
		ld r3, [UART_TX_STATUS]
		or r3,r3
		bz loopy
		//st [GPIO_OUT_REG], r3
	
		sub r1, 1
		bnz loopy

		//mov r2, 0
		//st [GPIO_OUT_REG], r2

done:
		ba run

dat:
		dw 1

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
		dw "Hello world! Hello Anna, my lovely!\r\n"
		dw 0

		.end


