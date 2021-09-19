        .org 0h

UART_TX_REG 	equ 	0x1000

		nop
top:
		mov r0, 10
		mov r1, 20
		mov r2, 'A'
		add r0, r1
		nop 
		nop
		st [UART_TX_REG], r2
		ba top

		.end


