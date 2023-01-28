
BOOTLOADER_SIZE = 0x200;
STACK_SIZE 	= 0x400;

MEMORY
{
	bootloader (rwx) : ORIGIN = 0x0000, LENGTH = BOOTLOADER_SIZE
	ram (rwx) : ORIGIN = BOOTLOADER_SIZE, LENGTH = 0x10000 - BOOTLOADER_SIZE
}

SECTIONS
{

	.text : {
		/* keep will be a noop, since slurmlink won't gc sections */
		KEEP(*(.vectors .vectors.*))
		*( .text )
	} > ram

	.data : {
		. = ALIGN(2);
		*( .data )
	} > ram

	.bss (NOLOAD): {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		_ezero = .;
	} > ram

	/* stack */

	.stack (NOLOAD):
   	{
      		. = ALIGN(2);
      		_sstack = .;
      		. = . + STACK_SIZE;
      		. = ALIGN(2);
      		_estack = .;
   	} > ram

	/* heap */

	. = ALIGN(4);
   	PROVIDE(_heap_start = .);
   	_end = . ;
}

