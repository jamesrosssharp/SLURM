
	#include <slurminterrupt.h>

	.section vectors
my_vector_table:
RESET_VEC:
	ba start
HSYNC_VEC:
	ba dummy_handler
VSYNC_VEC:
	ba dummy_handler
AUDIO_VEC:
	ba dummy_handler
SPI_FLASH:
	ba dummy_handler
GPIO_VEC:
	ba dummy_handler
TIMER_VEC:
	ba dummy_handler
VECTORS:
	.times 20 ba dummy_handler

	.section text
	.function start
	.global start
start:
//	mov r1, 0x41
//	out [r0, 0], r1

	// Zero regs (makes it easier to debug waveforms)
	mov r1, r0
	mov r2, r0
	mov r3, r0
	mov r4, r0
	mov r5, r0
	mov r6, r0
	mov r7, r0
	mov r8, r0
	mov r9, r0
	mov r10, r0
	mov r11, r0
	mov r12, r0

	// Copy vectors
	mov r1, r0
	mov r2, my_vector_table
	mov r3, 32
copy_loop:
	ld r4,[r2, 0]
	st [r1, 0], r4
	add r1, 2
	add r2, 2
	sub r3, 1
	bnz copy_loop

	// Set up stack
	
	.extern _eintstack
	mov r13, _eintstack
	
	.extern rtos_init
	bl main
	ba exit
	.endfunc

	.function putc
	.global putc
putc:
	out [r0, 0], r4
	nop
	nop
	nop
putc.loop:
	in r4, [r0, 1]
	or r4,r4
	bz putc.loop
	ret
	.endfunc

	.function trace_dec
	.global trace_dec
trace_dec:
	out [r0, 0x6000], r4
	ret
	.endfunc

	.function trace_char
	.global trace_char
trace_char:
	out [r0, 0x6001], r4
	ret
	.endfunc

	.function trace_hex
	.global trace_hex
trace_hex:
	out [r0, 0x6002], r4
	ret
	.endfunc

	.function exit
	.global exit
exit:
	out [r0, 0x6006], r0 
die:
	sleep
	ba die

	.endfunc

	.function __out
	.global __out
__out:
	out [r4, 0], r5
	ret
	.endfunc

	.function __in
	.global __in
__in: 
	in r2, [r4, 0]
	ret
	.endfunc

	.function __sleep
	.global __sleep
__sleep:
	sleep
	nop
	nop	
	nop
	nop
	ret	
	.endfunc

	//.function dummy_handler
	.section dummy
dummy_handler:
	st [r13, -2], r1
	
	mov r1, 0xffff
	out [r0, 0x7001], r1

	.global my_death	
my_death:
	ba my_death


	//.endfunc

	.section data
g_audio:
	dw 0
g_vsync:
	dw 0
	

	.end
