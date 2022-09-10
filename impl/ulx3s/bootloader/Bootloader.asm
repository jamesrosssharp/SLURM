        .org 0h

UART_TX_REG 	equ 	0x0000
UART_TX_STATUS 	equ 	0x0001

INTERRUPT_ENABLE_PORT equ 0x7000

RESET_VEC:
	ba start
HSYNC_VEC:
	ba dummy_handler
VSYNC_VEC:
	ba dummy_handler
AUDIO_VEC:
	ba dummy_handler
SPI_FLASH:
	ba dummy_handler
GPIO_VEC:
	ba dummy_handler
VECTORS:
	.times 20 dw 0x0000

start:

my_loop:
	mov r1, 0x42
	out [r0, 0], r1
	ba my_loop


dummy_handler:
//	mov r8, '!'	
//	out [r0, UART_TX_REG], r8
	mov r9, 0xffff
	out [r0, 0x7001], r9
	iret

	.end
