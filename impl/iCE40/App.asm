		.org 0x4000

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS 	equ 	0x1001

SPRITE0_X equ 0x2000
SPRITE0_Y equ 0x2100
SPRITE0_H equ 0x2200
SPRITE0_A equ 0x2300

GFX_FRAME equ 0x2f00
GFX_PAL   equ 0x2e00

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

		mov r0, 0x0f00
		st [GFX_PAL], r0
		mov r0, 0x00f0
		st [GFX_PAL + 1], r0
		mov r0, 0x000f
		st [GFX_PAL + 2], r0
		mov r0, 0x0fff
		st [GFX_PAL + 3], r0
		mov r0, 0x0000
		st [GFX_PAL + 4], r0
		mov r0, 0x00f0
		st [GFX_PAL + 5], r0
		mov r0, 0x000f
		st [GFX_PAL + 6], r0
		mov r0, 0x0fff
		st [GFX_PAL + 7], r0
		mov r0, 0x0000
		st [GFX_PAL + 8], r0




		mov r0, 200
		mov r1, 400
		mov r8, 0

		mov r11, 200
		mov r12, 400

		mov r13, 200
		mov r14, 400

		mov r10, 0x8000

sprite_loop:
	
		mov r2, r0
		and r2, 0x3ff
		or  r2, 0x0400
		mov r3, r1
		or  r3, 8<<10
		mov r4, r1
		add r4, 8

		st [SPRITE0_X], r2
		st [SPRITE0_Y], r3
		st [SPRITE0_H], r4
		st [SPRITE0_A], r10	

		mov r2, r11
		and r2, 0x3ff
		or  r2, 0x0400
		mov r3, r12
		and r3, 0x3ff
		or  r3, 32<<10
		mov r4, r12
		add r4, 32

		st [SPRITE0_X + 1], r2
		st [SPRITE0_Y + 1], r3
		st [SPRITE0_H + 1], r4
		st [SPRITE0_A + 1], r10	
		
		mov r2, r13
		and r2, 0x3ff
		or  r2, 0x0400
		mov r3, r14
		and r3, 0x3ff
		or  r3, 63<<10
		mov r4, r14
		add r4, 32

		st [SPRITE0_X + 2], r2
		st [SPRITE0_Y + 2], r3
		st [SPRITE0_H + 2], r4
		st [SPRITE0_A + 2], r10	

		add r0, 1
		sub r12, 1
		add r13, 4
		add r14, 2

wait_frame:
		ld r7, [GFX_FRAME]
		cmp r8, r7
		bz wait_frame
		mov r8, r7

		ba sprite_loop

die2:
		ba die2

the_string:
	dw "Hello World from Boot Loaded program!\n"

	.padto 0x8000	
		
	.times 1024 dw 0x4321


	.end
