	.org 0x0000
	.padto 0x200

HBLANK_INT_VECTOR equ 0x4
VBLANK_INT_VECTOR equ 0x8

INTERRUPT_ENABLE_PORT equ 0x7000

entry:
	/* install our interrupt handler in vector table */
	mov r1, (interrupt_handler >> 4) | 0x1000
	st [r0, HBLANK_INT_VECTOR], r1
	mov r1, (interrupt_handler & 0xf) | 0x4600
	st [r0, HBLANK_INT_VECTOR + 2], r1	

	/* enable hblank interrupt in interrupt controller */
	mov r1, 1
	out [r0, INTERRUPT_ENABLE_PORT], r1

	/* enable interrupts */
	sti

	/* sleep forever */

sleep_loop:
	nop
	sleep	// sleep
	ba sleep_loop

interrupt_handler:
	mov r1, 0x666
	out [r0, 0x6002], r1
	mov r1, 0x1f
	out [r0, 0x7001], r1

	iret

	.end
