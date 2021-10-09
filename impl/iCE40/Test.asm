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

	mov r0, 2
	st [SPI_FLASH_CMD], r0

do_it:
	mov r4, 20
outer:
	mov r3, 0xffff
wait_loop:
	sub r3, 1
	bnz wait_loop
	sub r4, 1
	bnz outer

	add r6, 1
	mov r0, r6
	mov r1, 0
	st	[SPI_FLASH_ADDR_LO], r0
	st	[SPI_FLASH_ADDR_HI], r1
	mov r0, 1
	st  [SPI_FLASH_CMD], r0

loop:
	ld r0, [SPI_FLASH_STATUS]
	test r0, 1
	bz loop

	ld r0, [SPI_FLASH_DATA]

/*	lsr r0
	lsr r0
	lsr r0
	lsr r0
	lsr r0
	lsr r0
	lsr r0
	lsr r0
*/

	bl print_hex_byte

	ba do_it
die:
	ba die


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

	.end
