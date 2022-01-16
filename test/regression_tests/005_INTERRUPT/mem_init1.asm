	.org 0x0000
	.padto 0x100

HBLANK_INT_VECTOR equ 0x2
VBLANK_INT_VECTOR equ 0x4

INTERRUPT_ENABLE_PORT equ 0x7000

entry:
	/* install our interrupt handler in vector table */
	mov r1, (interrupt_handler >> 4) | 0x1000
	st [r0, HBLANK_INT_VECTOR], r1
	mov r1, (interrupt_handler & 0xf) | 0x4600
	st [r0, HBLANK_INT_VECTOR + 1], r1	

	/* enable hblank interrupt in interrupt controller */
	mov r1, 1
	out [r0, INTERRUPT_ENABLE_PORT], r1

	/* enable interrupts */
	dw 0x0601

	/* sleep forever */

sleep_loop:
	dw 0x0700	// sleep
	ba sleep_loop

interrupt_handler:


	.end
