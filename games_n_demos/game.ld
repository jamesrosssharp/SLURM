/*
 * game.ld: linker script for the games and demos that do not use SlurmOS.
 *
 * The boot loader copies the program from flash to 0x200 and jumps to it.
 * Code and data live below 0x8000 (the stack starts at 0x7ffe, see top.asm);
 * graphics, sample and pattern buffers (section 'hidata') live at 0x8000.
 */

MEMORY {
	bootloader (wx) : ORIGIN = 0x0000, LENGTH = 0x200
	ram (wx) : ORIGIN = 0x200, LENGTH = 0x7e00
	hiram (wx) : ORIGIN = 0x8000, LENGTH = 0x8000
}

SECTIONS
{
	.text : {
		KEEP(*(.vectors))
		*( .text .text.* )
		. = ALIGN(0x100);
		*( .aligned )
	} > ram

	.data : {
		. = ALIGN(2);
		*( .data )
	} > ram

	.bss (NOLOAD) : {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		. = ALIGN(2);
		_ezero = .;
	} > ram

	.hidata : {
		*( .hidata )
	} > hiram

	_end = .;
}
