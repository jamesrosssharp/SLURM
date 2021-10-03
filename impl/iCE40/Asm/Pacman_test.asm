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

GPIO_IN				equ 0x1101

UP_BUTTON			equ 1<<0
DOWN_BUTTON			equ 1<<1
LEFT_BUTTON			equ 1<<2
RIGHT_BUTTON		equ 1<<3
A_BUTTON			equ 1<<4
B_BUTTON			equ 1<<5

SPRITE_NORMAL		equ 0
SPRITE_90_DEG		equ 2
SPRITE_180_DEG		equ 1
SPRITE_270_DEG		equ 3

AUDIO_PHASE			equ 0x1300
AUDIO_AMPL			equ 0x1301

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
		// r7 = audio freq

		mov r5, 0
		mov r0, 0
		mov r1, 320 + 48
		mov r2, 240 + 33
		ld r3, [GFX_FRAME]		

		mov r7, 0x7fff
		st [AUDIO_AMPL], r7

gfx_loop:
		// Check buttons
	
		ld r6, [GPIO_IN]
		cmp r6, UP_BUTTON
		bnz  not_up
		
		// Up pressed

		mov r5, SPRITE_270_DEG
		sub r2, 1
		add r0, 1

		or r7, r7
		bnz done_button		

		mov r7, 1000

		ba done_button

not_up:
		cmp r6, DOWN_BUTTON
		bnz not_down	

		// Down pressed
		
		mov r5, SPRITE_90_DEG
		add r2, 1
		add r0, 1

		or r7, r7
		bnz done_button		

		mov r7, 1000

		ba done_button

not_down:

		cmp r6, LEFT_BUTTON
		bnz not_left

		// Left pressed
		
		mov r5, SPRITE_180_DEG
		sub r1, 1
		add r0, 1

		or r7, r7
		bnz done_button		

		mov r7, 1000

		ba done_button
		
not_left:

		cmp r6, RIGHT_BUTTON
		bnz not_right

		// Right pressed
		
		mov r5, SPRITE_NORMAL
		add r1, 1
		add r0, 1

		or r7, r7
		bnz done_button		

		mov r7, 1000

		ba done_button
	
not_right:
		mov r0, 0
		mov r7, 0


done_button:
		nop

		cmp r0, 12
		bnz no_trunc
		mov r0, 0
no_trunc:

		st  [GFX_SPRITE_FLIP], r5

		mov r4, r0
		lsr r4
		lsr r4
		st [GFX_SPRITE_FRAME], r4
		st [GFX_SPRITE_X], r1
		st [GFX_SPRITE_Y], r2

	    st [AUDIO_PHASE], r7
		or r7,r7
		bz wait_frame
		
		sub r7, 100

		// Wait for retrace

wait_frame:
		ld r4, [GFX_FRAME]
		cmp r4, r3
		bz wait_frame
		mov r3, r4

done_state_3:
		ba gfx_loop

		dw 0
the_string:
		dw "SLURM16 Sprite test\r\n"
		dw 0

		.end


