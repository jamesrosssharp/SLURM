        .org 0h

SPI_FLASH_BASE 		equ	0x1400
SPI_FLASH_ADDR_LO 	equ (SPI_FLASH_BASE + 0)
SPI_FLASH_ADDR_HI 	equ (SPI_FLASH_BASE + 1)
SPI_FLASH_CMD		equ (SPI_FLASH_BASE + 2)
SPI_FLASH_DATA		equ (SPI_FLASH_BASE + 3)
SPI_FLASH_STATUS	equ (SPI_FLASH_BASE + 4)

UART_TX_REG 	equ 	0x1000

	nop
	mov r0, 0xaa55
	mov r1, 8	// 0x8000 = 1 MiB
	st	[SPI_FLASH_ADDR_LO], r0
	st	[SPI_FLASH_ADDR_HI], r1
	mov r0, 1
	st  [SPI_FLASH_CMD], r0

loop:
	ld r0, [SPI_FLASH_STATUS]
	test r0, 1
	bz loop

	mov r0, 'A'
	st [UART_TX_REG], r0

die:
	ba die

	.end
