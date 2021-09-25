        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001
PWM_LED			equ 	0x1200

HIRAM			equ 	0x2000
UPPER_HIRAM		equ		0x8000

GFX_SPRITE_FRAME	equ 0x2012
GFX_SPRITE_X		equ 0x2010
GFX_SPRITE_Y		equ 0x2011
GFX_FRAME			equ 0x2000

		nop
		
run:

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
		// r0 = sprite frame
		// r1 = sprite x
		// r2 = sprite y

		mov r0, 0
		mov r1, 320
		mov r2, 240
		ld r3, [GFX_FRAME]		

gfx_loop:
		mov r4, r0
		lsr r4
		lsr r4
		st [GFX_SPRITE_FRAME], r4
		st [GFX_SPRITE_X], r1
		st [GFX_SPRITE_Y], r2

		// Wait for retrace

#wait_frame:
#		ld r4, [GFX_FRAME]
#		cmp r4, r3
#		bz wait_frame
#		mov r3, r4

		add r0, 1
		cmp r0, 12
		bnz no_trunc
		//mov r0, 0
no_trunc:
		ba gfx_loop		

		dw 0
the_string:
		dw "SLURM16 Sprite test\r\n"
		dw 0

		.end


