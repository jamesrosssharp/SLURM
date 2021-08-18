        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001


		mov r1, 'A'
run:
		st [UART_TX_REG], r1
		add r1,1

		mov r2, 1
		cmp r2, 0
		//bz  is_zero

		mov r1, 'N'
		st [UART_TX_REG], r1

die_1:
		ba die_1

is_zero:


		ba run


		mov r4, 0xffff	// Stack pointer; top of mem

		mov r0, the_string
loop:
		ld r1, [r0+]
		st [UART_TX_REG], r1
		//cmp r1, 0
		//bz die 
test_loop:
		ld r2, [UART_TX_STATUS]
		test r2, 1
		bz test_loop

		ba loop

		mov r0, 0xffff
delay:
		mov r1, 0x20
delay_1:
		sub r1, 1
		bnz delay_1
	
		sub r0, 1
		bnz delay


die:
		ba run


the_string:
		dw "Hello world!\n"
		dw 0

		.end


