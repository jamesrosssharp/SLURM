        .org 0h

SPI_FLASH_BASE 		equ	0x1400
SPI_FLASH_ADDR 		equ (SPI_FLASH_BASE + 0)
SPI_FLASH_DATA_OUT 	equ (SPI_FLASH_BASE + 1)
SPI_FLASH_DATA_IN	equ (SPI_FLASH_BASE + 2)
SPI_FLASH_CMD		equ (SPI_FLASH_BASE + 3)
SPI_FLASH_STATUS	equ (SPI_FLASH_BASE + 4)

UART_TX_REG 	equ 	0x1000

// Registers for SPI core

SPICR0 equ 0x8  //1000 
SPICR1 equ 0x9  //1001 
SPICR2 equ 0xa  //1010 
SPIBR  equ 0xb  //1011 
SPITXDR equ 0xd //1101 
SPIRXDR equ 0xe //1110 
SPICSR equ 0xf  //1111 
SPISR  equ 0xc  //1100 
SPIIRQ equ 0x6  //0110 

	nop
	
	mov r0, SPICR0
	st [SPI_FLASH_ADDR], r0
	mov r0, 2
	st [SPI_FLASH_DATA_IN], r0
	mov r0, 1
	st [SPI_FLASH_CMD], r0
wait:	
 	ld r0, [SPI_FLASH_STATUS]
	test r0, 1
	bz wait

	mov r0, 2
	st [SPI_FLASH_CMD], r0

wait2:	
 	ld r0, [SPI_FLASH_STATUS]
	test r0, 2
	bz wait2

	ld r0, [SPI_FLASH_DATA_OUT]
	add r0, 'A'
	st [UART_TX_REG], r0

die:
	ba die


	.end
