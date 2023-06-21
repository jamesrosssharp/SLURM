/*

link.ld: Main linker script

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


BOOTLOADER_SIZE = 0x200;
STACK_SIZE 	= 0x400;
AUDIO_STACK_SIZE = 0x300;
STORAGE_STACK_SIZE = 0x200;
IDLE_STACK_SIZE = 0x200;

MEMORY {
	bootloader (wx) : ORIGIN = 0x0000, LENGTH = BOOTLOADER_SIZE
	ram1 (wx) : LENGTH = 0xc000 - BOOTLOADER_SIZE, ORIGIN = BOOTLOADER_SIZE 
}

SECTIONS
{

	.text : {
		KEEP(*(.vectors .vectors.*))
		KEEP(*(.dummy))
		*( .text .text.* )
	} > ram1


	.text_mixer : {
		. = ALIGN(0x100);
		*( .mixer3.text )
	} > ram1

	.data : {
		. = ALIGN(32);
		*( .data )
	} > ram1

	.data_mixer : {
		. = ALIGN(0x100);
		*( .mixer3.data )
	} > ram1

	.bss (NOLOAD): {
		. = ALIGN(2);
		_szero = .;
		*( .bss .bss.* )
		_ezero = .;
	} > ram1

	/* stacks */

	.stack (NOLOAD):
   	{
      		. = ALIGN(2);
      		_sstack = .;
      		. = . + STACK_SIZE;
      		. = ALIGN(2);
      		_estack = .;
		_saudiostack = .;
		. = . + AUDIO_STACK_SIZE;
		. = ALIGN(2);
		_eaudiostack = .;
		_sstoragestack = .;
		. = . + STORAGE_STACK_SIZE;
		. = ALIGN(2);
		_estoragestack = .;
		_sidlestack = .;
		. = . + IDLE_STACK_SIZE;
		. = ALIGN(2);
		_eidlestack = .;
		_sstartstack = .;
		. = . + 128;
		_estartstack = .;
   	} > ram1

	/* heap */

	. = ALIGN(2);
	_heap_start = .;	
	. = ALIGN(0xc000);
	_heap_end = .;

}
