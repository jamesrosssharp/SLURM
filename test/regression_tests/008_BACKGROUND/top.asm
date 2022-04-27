	.padto 200h

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
VECTORS:
	.times 20 dw 0x0000

start:
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
	mov r13, 0x7ffe
	bl main
	bl exit
die:
	ba die

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

trace_dec:
	out [r0, 0x6000], r4
	ret

trace_char:
	out [r0, 0x6001], r4
	ret

trace_hex:
	out [r0, 0x6002], r4
	ret

exit:
	out [r0, 0x6006], r0 
	ret

__out:
	out [r4, 0], r5
	ret

__in: 
	in r2, [r4, 0]
	ret

/* r4 = Copper list address
 * r5 = Copper list length */
load_copper_list:
	mov r2, r0
load_copper_list.loop:
	ld r1, [r4, 0]
	out [r2, 0x5400], r1 // Copper list memory
	add r2, 1
	add r4, 2
	sub r5, 1
	bnz load_copper_list.loop
	ret

//extern void load_sprite_x(short sprite, short x);

load_sprite_x:
	out [r4, 0x5000], r5
	ret

//extern void load_sprite_y(short sprite, short y);
load_sprite_y:
	out [r4, 0x5100], r5
	ret

//extern void load_sprite_h(short sprite, short h);
load_sprite_h:
	out [r4, 0x5200], r5
	ret

//extern void load_sprite_a(short sprite, short a);
load_sprite_a:
	out [r4, 0x5300], r5
	ret


/* r4 = Palette
 * r5 = Offset
 * r6 = Number of entries */
load_palette:
load_palette.loop:
	ld r1, [r4, 0]
	out [r5, 0x5e00], r1 // Palette memory
	add r5, 1
	add r4, 2
	sub r6, 1
	bnz load_palette.loop
	ret

__sleep:
	sleep
	ret	

global_interrupt_enable:
	sti
	ret

global_interrupt_disable:
	cli
	ret

dummy_handler:
	mov r1, 0xffff
	out [r0, 0x7001], r1
	
	iret

