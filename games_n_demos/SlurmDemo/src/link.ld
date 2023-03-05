
BOOTLOADER_SIZE = 0x200;
STACK_SIZE 	= 0x800;

MEMORY {
	bootloader (wx) : ORIGIN = 0x0000, LENGTH = BOOTLOADER_SIZE
	ram1 (wx) : LENGTH = 0x8000 - BOOTLOADER_SIZE, ORIGIN = BOOTLOADER_SIZE 
	ram2 (wx) : LENGTH = 0x8000, ORIGIN = 0x8000
}

SECTIONS
{

	.text : {
		/* keep will be a noop, since slurmlink won't gc sections */
		KEEP(*(.vectors .vectors.*))
		*( .text .text.* )
	} > ram1

	.data : {
		. = ALIGN(32);
		*( .data )
	} > ram1

	.bss (NOLOAD): {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		_ezero = .;
	} > ram1

	/* stack */

	.stack (NOLOAD):
   	{
      		. = ALIGN(0x100);
      		_sstack = .;
      		. = . + STACK_SIZE;
      		. = ALIGN(2);
      		_estack = .;
   	} > ram1

	/* heap */

	. = ALIGN(4);

	/* PROVIDE provides the symbol only if it is referenced, but not defined */
   	PROVIDE(_heap_start = .);
   	_end = . ;

	.data_mixer : {
		*( .mixer.data )
	} > ram2

	.text_mixer : {
		*( .mixer.text )
	} > ram2

}
