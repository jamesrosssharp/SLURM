/*
 * slurm16.ld - default linker script for C/C++ programs (slurmlink syntax)
 *
 * The first 0x200 bytes hold the boot loader / vector table. Code, data and
 * the stack follow.
 */

BOOTLOADER_SIZE = 0x200;
STACK_SIZE      = 0x1000;

MEMORY {
	bootloader (wx) : ORIGIN = 0x0000, LENGTH = BOOTLOADER_SIZE
	ram (wx) : LENGTH = 0x10000 - BOOTLOADER_SIZE, ORIGIN = BOOTLOADER_SIZE
}

SECTIONS
{
	.text : {
		KEEP(*(.vectors .vectors.*))
		*( .text .text.* )
	} > ram

	.data : {
		. = ALIGN(2);
		*( .data )
		. = ALIGN(2);
		__init_array_start = .;
		KEEP(*( .init_array ))
		__init_array_end = .;
	} > ram

	.bss (NOLOAD): {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		. = ALIGN(2);
		_ezero = .;
	} > ram

	.stack (NOLOAD):
	{
		. = ALIGN(2);
		_sstack = .;
		. = . + STACK_SIZE;
		. = ALIGN(2);
		_estack = .;
	} > ram

	. = ALIGN(2);
	_heap_start = .;
	_end = . ;
}
