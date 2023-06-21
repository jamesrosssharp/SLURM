        .org 0h

SPI_FLASH_BASE 		equ	0x4000
SPI_FLASH_ADDR_LO 	equ (SPI_FLASH_BASE + 0)
SPI_FLASH_ADDR_HI 	equ (SPI_FLASH_BASE + 1)
SPI_FLASH_CMD		equ (SPI_FLASH_BASE + 2)
SPI_FLASH_DATA		equ (SPI_FLASH_BASE + 3)
SPI_FLASH_STATUS	equ (SPI_FLASH_BASE + 4)
SPI_FLASH_DMA_ADDR  equ (SPI_FLASH_BASE + 5)
SPI_FLASH_DMA_COUNT  equ (SPI_FLASH_BASE + 6)

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
	mov r1, '!'
	out [r0, 0], r1

	// Wake up spi flash
	mov r1, 2
	out [r0, SPI_FLASH_CMD], r1

	// Wait
	mov r4, 40
outer:
	mov r3, 0xffff
wait_loop:
	sub r3, 1
	bnz wait_loop
	sub r4, 1
	bnz outer

do_it:
	mov r1, 8
	out	[r0, SPI_FLASH_ADDR_LO], r0
	out	[r0, SPI_FLASH_ADDR_HI], r1
	mov r3, 0x100
	out [r0, SPI_FLASH_DMA_ADDR], r3
	mov r3, 0xff00
	out	[r0, SPI_FLASH_DMA_COUNT], r3 

//	mov r3, 0x4000
//	out [r0, SPI_FLASH_DMA_ADDR], r3
//	mov r3, 0x100
//	out [r0, SPI_FLASH_DMA_COUNT], r3

	// Enable interrupts
	mov r1, 1<<3
	out [r0, INTERRUPT_ENABLE_PORT], r1

	// Clear any pending interrupts (e.g. from flash wake up)
	mov r9, 0xffff
	out [r0, 0x7001], r9

	nop
	nop
	nop
	
	/* enable interrupts */
	sti

	// Start flash DMA
	mov r3, 1
	out [r0, SPI_FLASH_CMD], r3
	
	sleep
	nop
	nop
	nop
	nop
	cli	// Clear interrupts

spi_loop:
	mov r1, '?'
	out [r0, 0], r1
	//mov r1, 0x16
	//bl print_hex_byte

	mov r4, 40
outer_spi:
	mov r3, 0x40
wait_loop_spi:
	sub r3, 1
	bnz wait_loop_spi
	sub r4, 1
	bnz outer_spi

	in r1, [r0, SPI_FLASH_STATUS]
	or r1, r1
	bz spi_loop

	mov r1, '#'
	out [r0, 0], r1


	// Print loop

	mov r3, 0x200
	mov r4, 0x200
print_loop:
	ldb r1, [r3, 0]
	bl print_hex_byte
	add r3, 1
	sub r4, 1
	bnz print_loop 		

//loopy:
//	sleep
//	ba loopy


	out [r0, INTERRUPT_ENABLE_PORT], r0

	ba 0x200	// Jump to app


dummy_handler:
	//mov r8, '!'	
	in r8, [r0, SPI_FLASH_STATUS]
	add r8, 0x41
	out [r0, UART_TX_REG], r8
	mov r9, 0xffff
	out [r0, 0x7001], r9
	iret


print_hex_byte:
	mov r7, r15
	mov r4, r1
	lsr r1
	lsr r1
	lsr r1
	lsr r1
	and r1, 0xf
	bl print_hex_nibble
	nop
	mov r1, r4
	and r1, 0xf
	bl print_hex_nibble

	mov r15, r7
	ret

print_hex_nibble:
	cmp r1, 0xa
	bs not_gt_9
	add r1, 'a' - 0xa
	ba done_nibble
not_gt_9:
	add r1, '0'
done_nibble:
	out [r0, UART_TX_REG], r1
test_loop:
    	in r2, [r0, UART_TX_STATUS]
    	test r2, 1
    	bz test_loop
	ret	

	.end
