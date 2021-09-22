        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001
PWM_LED			equ 	0x1200

HIRAM			equ 	0x2000
UPPER_HIRAM		equ		0x8000

		mov r3, HIRAM
		mov r1, the_string
		
the_loop:
		ld r0, [r1]
		inc r1
		or r0, r0
		bz end_loop
		st [r3], r0
		inc r3
		ba the_loop
end_loop:
		mov r0, 0
		st [r3], r0
		inc r3

		mov r3, UPPER_HIRAM
		mov r0, 0xffff
		mov r1, 0
		st  [r3], r0
		inc r3
		st  [r3], r1
		inc r3
		st  [r3], r1
		inc r3
		st  [r3], r1
		inc r3
		st  [r3], r0
		inc r3
		st  [r3], r1
		inc r3
		st  [r3], r1
		inc r3
		st  [r3], r1
		inc r3
		st  [r3], r0
		inc r3
		st  [r3], r0
		inc r3
		st  [r3], r0
		inc r3
		st  [r3], r0
		inc r3

run:

		mov r0, HIRAM
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

		mov r3, 0x4
		
		mov r2, UPPER_HIRAM
outer:
		ld r4, [r2]
		inc r2
		st [PWM_LED], r4
		ld r5, [r2]
		inc r2
		st [PWM_LED+1], r5
		ld r6, [r2]
		inc r2
		st [PWM_LED+2], r6

		mov r0, 20
delay:
		mov r1, 0xffff
delay_1:
		or r4,r4
		bz noinc1
		sub r4, 1
		st [PWM_LED], r4
noinc1:
		or r5,r5
		bz noinc2
		sub r5, 1
		st [PWM_LED+1], r5
noinc2:
		or r6,r6
		bz noinc3
		sub r6, 1
		st [PWM_LED+2], r6
noinc3:



		sub r1, 1
		bnz delay_1
	
		sub r0, 1
		bnz delay

		sub r3, 1
		bnz outer
		
		ba run

		dw 0
the_string:
		dw "Hello world!\r\nHello from SLURM16, 5 stage pipeline\r\n"
		dw 0

		.end


