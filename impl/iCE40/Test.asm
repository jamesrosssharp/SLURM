        .org 0h

SPI_FLASH_BASE 		equ	0x1400
SPI_FLASH_ADDR 		equ (SPI_FLASH_BASE + 0)
SPI_FLASH_DATA_OUT 	equ (SPI_FLASH_BASE + 1)
SPI_FLASH_DATA_IN	equ (SPI_FLASH_BASE + 2)
SPI_FLASH_CMD		equ (SPI_FLASH_BASE + 3)
SPI_FLASH_STATUS	equ (SPI_FLASH_BASE + 4)

UART_TX_REG 	equ 	0x1000
UART_TX_STATUS  equ		0x1001

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

SPISR_TIP  equ 1 << 7
SPISR_BUSY equ 1 << 6
SPISR_TRDY equ 1 << 4 
SPISR_RRDY equ 1 << 3
SPISR_TOE  equ 1 << 2
SPISR_ROE  equ 1 << 1
SPISR_MDF  equ 1 << 0

	nop

	mov r8, 0

do_tx:
	bl wait_tx_ready
	
	mov r0, SPICR0
	mov r1, 0xff
	bl write_spi_reg

	bl wait_tx_ready
	
	mov r0, SPICR1
	mov r1, 0x80
	bl write_spi_reg

	bl wait_tx_ready
	
	mov r0, SPIBR
	mov r1, 0x3f
	bl write_spi_reg

	bl wait_tx_ready

	mov r0, SPICR2
	mov r1, 0x80
	bl write_spi_reg

	bl wait_tx_ready

	//mov r0, SPICSR
	//mov r1, 0xd
	//bl write_spi_reg

	mov r0, SPICR2
	mov r1, 0xC0
	bl write_spi_reg

	bl wait_tx_ready
	
	mov r9, 3
do_tx_loop:

	
	mov r0, SPITXDR
	mov r1, r8
	add r8, 1
	bl write_spi_reg

wait_rx_ready:
	mov r0, SPISR
	bl read_spi_reg
	test r0, SPISR_RRDY
	bz wait_rx_ready

	//mov r0, SPIRXDR
	//bl read_spi_reg

	sub r9, 1
	bnz do_tx_loop

	mov r0, SPITXDR
	mov r1, r8
	add r8, 1
	bl write_spi_reg

wait_rx_ready2:
	mov r0, SPISR
	bl read_spi_reg
	test r0, SPISR_RRDY
	bz wait_rx_ready2

	mov r0, SPICR2
	mov r1, 0x80
	bl write_spi_reg

wait_no_tip:
	mov r0, SPISR
	bl read_spi_reg
	test r0, SPISR_TIP
	bnz wait_no_tip

	//mov r0, SPICR2
	//mov r1, 0x00
	//bl write_spi_reg

do_wait:
	mov r3, 0x20
wait_outer:
	mov r2, 0xffff
wait_loop:
	sub r2, 1
	bnz wait_loop
	sub r3, 1
	bnz wait_outer

	mov r0, SPISR
	bl read_spi_reg

	bl print_hex_byte

	ba do_tx

die:
	ba die

//
//	r0: address
//	r1: data
//

write_spi_reg:
	st [SPI_FLASH_ADDR], r0
	st [SPI_FLASH_DATA_IN], r1
	mov r0, 1
	st [SPI_FLASH_CMD], r0
write_spi_reg.wait:	
 	ld r0, [SPI_FLASH_STATUS]
	test r0, 1
	bz write_spi_reg.wait
	ret

//
//
//
read_spi_reg:
	st [SPI_FLASH_ADDR], r0
	mov r0, 2
	st [SPI_FLASH_CMD], r0
read_spi_reg.wait:	
 	ld r0, [SPI_FLASH_STATUS]
	test r0, 2
	bz read_spi_reg.wait
	ld r0, [SPI_FLASH_DATA_OUT]
	ret
	nop
	nop
	nop	

wait_tx_ready:
	
	mov r7, r15
rdy_loop:
	mov r0, SPISR
	bl read_spi_reg
	test r0, SPISR_TRDY
	bz rdy_loop
	mov r15, r7
	ret
	nop
	nop
	nop


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
