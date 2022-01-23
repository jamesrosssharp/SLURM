	.org 0x100

UART_TX_REG 	equ 	0x0000
UART_TX_STATUS 	equ 	0x0001

GFX_BASE equ 0x5000
	
GFX_CPR_LIST  		 equ GFX_BASE + 0x0400
GFX_FB_PAL 			 equ GFX_BASE + 0x0600

GFX_CPR_ENABLE 		 equ GFX_BASE + 0x0d20
GFX_CPR_Y_FLIP  	 equ GFX_BASE + 0x0d21
GFX_CPR_BGCOL 		 equ GFX_BASE + 0x0d22
GFX_CPR_ALPHA  		 equ GFX_BASE + 0x0d24

PWM_RED   equ 0x2000
PWM_GREEN equ 0x2001
PWM_BLUE  equ 0x2002

INTERRUPT_ENABLE_PORT equ 0x7000

my_vector_table:
RESET_VEC:
	ba start
HSYNC_VEC:
	ba hs_handler
VSYNC_VEC:
	ba vs_handler
AUDIO_VEC:
	ba dummy_handler
SPI_FLASH:
	ba dummy_handler
GPIO_VEC:
	ba dummy_handler
VECTORS:
	.times 20 dw 0x0000

start:
		// Copy vectors
		mov r1, r0
		mov r2, my_vector_table
		mov r3, 32
copy_loop:
		ld r4,[r2, 0]
		st [r1, 0], r4
		add r1, 1
		add r2, 1
		sub r3, 1
		bnz copy_loop


		mov r4, 3
		out [r0, PWM_RED], r4
		mov r4, 1
		out [r0, PWM_GREEN], r4
		mov r4, 1
		out [r0, PWM_BLUE], r4

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

die:
		mov r1, 1<<4 | 1 | 2
		out [r0, INTERRUPT_ENABLE_PORT], r1

		/* enable interrupts */
		sti

sleep_loop:
		sleep	// sleep
		ba sleep_loop

		ba die
	
banner:
		dw "Hello world! Bootloaded!\r\n"
		dw 0

hs_handler:
		stf r10	// Store flags
		add r7, 1	
		out [r0, GFX_CPR_BGCOL], r7
		mov r9, 0xffff
		out [r0, 0x7001], r9
		rsf r10	// Restore flags
		iret

vs_handler:
		mov r7, r0
		mov r9, 0xffff
		out [r0, 0x7001], r9
		iret

dummy_handler:
		mov r8, '!'	
		out [r0, UART_TX_REG], r8
		mov r9, 0xffff
		out [r0, 0x7001], r9
		iret
		
		.end
