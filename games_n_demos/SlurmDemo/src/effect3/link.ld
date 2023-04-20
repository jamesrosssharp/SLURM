
APPLET_SIZE = 0x4000;

MEMORY 
{
	applet_mem (wx) : ORIGIN = 0xc000, LENGTH = APPLET_SIZE   
}

SECTIONS 
{

	.text : {
		KEEP(*(.vectors .vectors.*))
		*( .text .text.* )
	} > applet_mem

	.data : {
		. = ALIGN(32);
		*( .data )
	} > applet_mem

	.bss (NOLOAD): {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		_ezero = .;
	} > applet_mem 

}
