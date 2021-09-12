        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001
PWM_LED			equ 	0x1200

		mov r1, 'A'

loop:
		st [UART_TX_REG], r1
test_loop:
		ld r2, [UART_TX_STATUS]
		test r2, 1
		bz test_loop


		mov r2, 0xffff
outer:
		mov r3, 0x10
inner:
		sub r3, 1
		bnz inner

		st [PWM_LED], r2

		sub r2, 1
		bnz outer


		ba loop

		.end
