        .org 0h

UART_TX_REG 	equ 	0x0000
UART_TX_STATUS 	equ 	0x0001

GFX_BASE equ 0x5000
	
GFX_CPR_LIST  		 equ GFX_BASE + 0x0400
GFX_FB_PAL 			 equ GFX_BASE + 0x0600

GFX_CPR_ENABLE 		 equ GFX_BASE + 0x0d20
GFX_CPR_Y_FLIP  	 equ GFX_BASE + 0x0d21
GFX_CPR_BGCOL 		 equ GFX_BASE + 0x0d22
GFX_CPR_ALPHA  		 equ GFX_BASE + 0x0d24


GFX_COLLISION_LIST equ GFX_BASE + 0x0700

PWM_RED   equ 0x2000
PWM_GREEN equ 0x2001
PWM_BLUE  equ 0x2002



		nop
		mov r1, cpr_list_1
		mov r2, cpr_list_1_end - cpr_list_1
		mov r6, r0
cpr_loop:
		ld r3, [r1, 0]
		add r1, 1
		out [r6, GFX_CPR_LIST], r3
		add r6, 1
		sub r2, 1
		bnz cpr_loop

		mov r4, 0x1
		out [r0, GFX_CPR_ENABLE], r4

		mov r4, 1
		out [r0, PWM_RED], r4
		mov r4, 1
		out [r0, PWM_GREEN], r4
		mov r4, 3
		out [r0, PWM_BLUE], r4

//		mov r4, 0x00f
//		out [r0, GFX_CPR_BGCOL], r4


		ba cpr_list_1_end

cpr_list_1:
		dw 0x7021
		dw 0x6f00
		dw 0x7064
		dw 0x60f0
		dw 0x7064
		dw 0x600f
		dw 0x7064
		dw 0x1001
cpr_list_1_end:

		mov r2, banner
loop:
		ld r1, [r2, 0]
		add r2, 1
		or r1, r1
		bz die 
		out [r0, UART_TX_REG], r1
test_loop:
		in r3, [r0, UART_TX_STATUS]
		test r3, 1
		bz test_loop

		ba loop

		// Write copper list



die:
		ba die

banner:
		dw "Hello world!\r\n"
		dw 0

		.end
