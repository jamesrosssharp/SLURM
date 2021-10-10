        .org 0h

SPI_FLASH_BASE 		equ	0x1400
SPI_FLASH_ADDR_LO 	equ (SPI_FLASH_BASE + 0)
SPI_FLASH_ADDR_HI 	equ (SPI_FLASH_BASE + 1)
SPI_FLASH_CMD		equ (SPI_FLASH_BASE + 2)
SPI_FLASH_DATA		equ (SPI_FLASH_BASE + 3)
SPI_FLASH_STATUS	equ (SPI_FLASH_BASE + 4)

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS 	equ 	0x1001

	nop

	mov r6, 0xffff

	// Wake up flash
	mov r0, 2
	st [SPI_FLASH_CMD], r0

	mov r4, 20
outer:
	mov r3, 0xffff
wait_loop:
	sub r3, 1
	bnz wait_loop
	sub r4, 1
	bnz outer

	mov r11, 0x4000
do_it:
	add r6, 1
	mov r0, r6
	mov r1, 8
	st	[SPI_FLASH_ADDR_LO], r0
	st	[SPI_FLASH_ADDR_HI], r1
	mov r0, 1
	st  [SPI_FLASH_CMD], r0

loop:
	ld r0, [SPI_FLASH_STATUS]
	test r0, 1
	bz loop

	ld r0, [SPI_FLASH_DATA]
	st [r11], r0
	inc r11

	or r11,r11
	bz 0x4000	// Jump to bootloaded code

	ba do_it

	.end
