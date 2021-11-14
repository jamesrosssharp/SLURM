        .org 0h

SPI_FLASH_BASE 		equ	0x0140
SPI_FLASH_ADDR_LO 	equ (SPI_FLASH_BASE + 0)
SPI_FLASH_ADDR_HI 	equ (SPI_FLASH_BASE + 1)
SPI_FLASH_CMD		equ (SPI_FLASH_BASE + 2)
SPI_FLASH_DATA		equ (SPI_FLASH_BASE + 3)
SPI_FLASH_STATUS	equ (SPI_FLASH_BASE + 4)
SPI_FLASH_DMA_ADDR  equ (SPI_FLASH_BASE + 5)
SPI_FLASH_DMA_COUNT  equ (SPI_FLASH_BASE + 6)



UART_TX_REG 	equ 	0x0100
UART_TX_STATUS 	equ 	0x0101

	nop

	mov r6, 0xffff

	// Wake up flash
	mov r0, 2
	st [SPI_FLASH_CMD], r0

	mov r4, 40
outer:
	mov r3, 0xffff
wait_loop:
	sub r3, 1
	bnz wait_loop
	sub r4, 1
	bnz outer

	mov r3, 0x2000
	mov r4, 100
clear_loop:
	mov r0, 0
	st [r3], r0
	inc r3
	sub r4, 1
	bnz clear_loop

	//mov r0, 'A'
	//st  [UART_TX_REG], r0

do_it:
	mov r0, 0
	mov r1, 8
	st	[SPI_FLASH_ADDR_LO], r0
	st	[SPI_FLASH_ADDR_HI], r1
	mov r0, 0x2000
	st  [SPI_FLASH_DMA_ADDR], r0
	mov r0, 0xe000
	st	[SPI_FLASH_DMA_COUNT], r0 
	mov r0, 1
	st  [SPI_FLASH_CMD], r0

loop:
	ld r0, [SPI_FLASH_STATUS]
	test r0, 1
	bz loop

	ba 0x2000

//	mov r0, 'B'
//	st  [UART_TX_REG], r0

/*	mov r4, 0x2000
	mov r3, 100
print_loop:
	ld r0, [r4]
	bl print_hex_byte
	inc r4
	sub r3, 1
	bnz print_loop

die:
	ba die
*/

print_hex_byte:
	mov r7, r15
	mov r1, r0
	lsr r1
	lsr r1
	lsr r1
	lsr r1
	and r1, 0xf
	bl print_hex_nibble
	nop
	mov r1, r0
	and r1, 0xf
	bl print_hex_nibble

	mov r15, r7
	ret
	nop
	nop
	nop

print_hex_nibble:
	cmp r1, 0xa
	bs not_gt_9
	add r1, 'a' - 0xa
	ba done_nibble
not_gt_9:
	add r1, '0'
done_nibble:
	st [UART_TX_REG], r1
test_loop:
    ld r2, [UART_TX_STATUS]
    test r2, 1
    bz test_loop
	ret
	nop
	nop
	nop


	//ba 0x2000	// Jump to bootloaded code


	.end
