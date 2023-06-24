
MEMORY 
{
	applet_code (wx) : ORIGIN = 0x5000, LENGTH = 0x3000
	applet_data (w) : ORIGIN = 0xe000, LENGTH = 0x2000
}

SECTIONS 
{

	.text : {
		KEEP(*(.vectors .vectors.*))
		*( .text .text.* )
	} > applet_code

	.data : {
		. = ALIGN(32);
		*( .data )
	} > applet_code

	.bss (NOLOAD): {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		_ezero = .;
	} > applet_data

}
