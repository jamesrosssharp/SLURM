
STACK_SIZE 	= 0x400;

MEMORY {
	ram (wx) : LENGTH = 0x8000, ORIGIN = 0x8000
}

SECTIONS
{

	.text : {
		/* keep will be a noop, since slurmlink won't gc sections */
		KEEP(*(.vectors .vectors.*))
		*( .text .text.* )
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

