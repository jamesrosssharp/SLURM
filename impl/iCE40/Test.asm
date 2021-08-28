        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001
PWM_LED			equ 	0x1200

HIRAM			equ 	0x8100
UPPER_HIRAM		equ		0xc000

		mov r3, HIRAM
		mov r1, the_string
		
the_loop:
		ld r0, [r1+]
		or r0, r0
		bz.r end_loop
		st [r3+], r0
		ba.r the_loop
end_loop:
		mov r0, 0
		st [r3+], r0

		mov r3, UPPER_HIRAM
		mov r0, 0xffff
		mov r1, 0
		st  [r3+], r0
		st  [r3+], r1
		st  [r3+], r1

		st  [r3+], r1
		st  [r3+], r0
		st  [r3+], r1

		st  [r3+], r1
		st  [r3+], r1
		st  [r3+], r0

		st  [r3+], r0
		st  [r3+], r0
		st  [r3+], r0

run:

		mov r0, HIRAM
loop:
		ld r1, [r0+]
		or r1, r1
		bz.r die 
		st [UART_TX_REG], r1
test_loop:
		ld r2, [UART_TX_STATUS]
		test r2, 1
		bz.r test_loop

		ba.r loop
die:
		mov r3, 0x4
		
		mov r2, UPPER_HIRAM
outer:
		ld r0, [r2+]
		st [PWM_LED], r0
		ld r0, [r2+]
		st [PWM_LED+1], r0
		ld r0, [r2+]
		st [PWM_LED+2], r0

		mov r0, 0x20
delay:
		mov r1, 0xffff
delay_1:

		sub r1, 1
		bnz delay_1
	
		sub r0, 1
		bnz delay

		sub r3, 1
		bnz outer
		
		ba.r run

		dw 0
the_string:
		dw "Hello world!\r\n"
		dw 0

		.end


