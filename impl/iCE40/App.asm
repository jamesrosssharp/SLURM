		.org 0x4000

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS 	equ 	0x1001

SPRITE0_X equ 0x2000
SPRITE0_Y equ 0x2001
SPRITE0_FLAGS equ 0x2003
SPRITE0_X_END equ 0x2005
SPRITE0_Y_END equ 0x2006

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
		mov r0, 320
		mov r1, 200
		mov r2, 1
		mov r3, r0
		mov r4, r1
		add r3, 320
		add r4, 32
	
		st [SPRITE0_X], r0
		st [SPRITE0_Y], r1
		st [SPRITE0_FLAGS], r2
		st [SPRITE0_X_END], r3
		st [SPRITE0_Y_END], r4


die2:
		ba die2

the_string:
	dw "Hello World from Boot Loaded program!\n"

	.end
