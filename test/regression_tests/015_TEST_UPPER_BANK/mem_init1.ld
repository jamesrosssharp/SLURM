
BOOTLOADER_SIZE = 0x200;
STACK_SIZE 	= 0x400;

MEMORY {
	bootloader (wx) : ORIGIN = 0x0000, LENGTH = BOOTLOADER_SIZE
	ram (wx) : LENGTH = 0x8000 - BOOTLOADER_SIZE, ORIGIN = BOOTLOADER_SIZE 
}

SECTIONS
{

	.boot : {
		. = . + BOOTLOADER_SIZE;
	} > bootloader

	.text : {
		/* keep will be a noop, since slurmlink won't gc sections */
		KEEP(*(.vectors .vectors.*))
		KEEP(*( .text .text.* ))
	} > ram

	.data : {
		. = ALIGN(32);
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

}

