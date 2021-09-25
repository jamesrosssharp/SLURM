        .org 0h

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001
PWM_LED			equ 	0x1200

HIRAM			equ 	0x2000
UPPER_HIRAM		equ		0x8000

GFX_SPRITE_FRAME	equ 0x2012
GFX_SPRITE_X		equ 0x2010
GFX_SPRITE_Y		equ 0x2011
GFX_SPRITE_FLIP		equ 0x2013
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
		// r3 = frame number
		// r5 = state

		mov r5, 0
		mov r0, 0
		mov r1, 320 + 48
		mov r2, 240 + 33
		ld r3, [GFX_FRAME]		

gfx_loop:
		st  [GFX_SPRITE_FLIP], r5

		mov r4, r0
		lsr r4
		nop
		lsr r4
		st [GFX_SPRITE_FRAME], r4
		st [GFX_SPRITE_X], r1
		st [GFX_SPRITE_Y], r2

		// Wait for retrace

wait_frame:
		ld r4, [GFX_FRAME]
		cmp r4, r3
		bz wait_frame
		mov r3, r4

		add r0, 1
		cmp r0, 12
		bnz no_trunc
		mov r0, 0
no_trunc:
	
		cmp r5, 0
		bz  state_0

		cmp r5, 1
		bz state_1

		cmp r5, 2
		bz state_2

		ba state_3


state_0:

		add r1, 4
		cmp r1, 700
		bs  done_state_0

		add r5, 1
		and r5, 3

done_state_0:
		ba gfx_loop

state_1:

		sub r1, 4
		cmp r1, 40
		bns  done_state_1

		mov r1, 320 + 48
		mov r2, 0

		add r5, 1
		and r5, 3

done_state_1:
		ba gfx_loop

state_2:

		add r2, 4
		cmp r2, 500
		bs  done_state_2

		add r5, 1
		and r5, 3

done_state_2:
		ba gfx_loop

state_3:

		sub r2, 4
		cmp r2, 40
		bns  done_state_3

		mov r1, 0
		mov r2, 240 + 33

		add r5, 1
		and r5, 3

done_state_3:
		ba gfx_loop

		dw 0
the_string:
		dw "SLURM16 Sprite test\r\n"
		dw 0

		.end


