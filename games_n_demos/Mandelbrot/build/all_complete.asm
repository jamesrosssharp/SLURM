	.org 200h

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
	mov r13, 0x7ffe
	bl main
	bl exit
die:
	sleep
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

__sleep:
	sleep
	ret	

dummy_handler:
	mov r1, 0xffff
	out [r0, 0x7001], r1
	iret


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

load_bl_copper_list:
	mov r4, bloodlust_copper_list
	mov r5, (end_bl_copper_list - bloodlust_copper_list) >> 1
	mov r2, r0
load_bl_copper_list.loop:
	ld r1, [r4, 0]
	out [r2, 0x5400], r1 // Copper list memory
	add r2, 1
	add r4, 2
	sub r5, 1
	bnz load_bl_copper_list.loop
	ret

update_bl_copper_list:
	sub r13, 4
	st [r13, 2], r15
	ld r4, [r0, wave_phase]
	mov r5, start_wave
	mov r6,16

update_bl_copper_list.loop:
	ld r7, [r4, wave]
	st [r5, 0], r7
	add r5, 2
	add r4, 2
	sub r6, 1
	bnz update_bl_copper_list.loop
	
	ld r4, [r0, wave_phase]
	add r4, 2
	and r4, 31
	st [r0, wave_phase], r4

	bl load_bl_copper_list

	ld r15, [r13, 2]
	add r13,4
	ret


wave:
	dw 0xb001
	dw 0xb001
	dw 0xb002
	dw 0xb002
	dw 0xb002
	dw 0xb002
	dw 0xb002
	dw 0xb001
	dw 0xb001
	dw 0xb001
	dw 0xb000
	dw 0xb000
	dw 0xb000
	dw 0xb000
	dw 0xb000
	dw 0xb001
	dw 0xb001
	dw 0xb001
	dw 0xb002
	dw 0xb002
	dw 0xb002
	dw 0xb002
	dw 0xb002
	dw 0xb001
	dw 0xb001
	dw 0xb001
	dw 0xb000
	dw 0xb000
	dw 0xb000
	dw 0xb000
	dw 0xb000
	dw 0xb001
	

wave_phase: 
	dw 0




bloodlust_copper_list:
		dw 0xb001
		dw 0x6000
		dw 0x7008
		dw 0x6100
		dw 0x7008
		dw 0x6200
		dw 0x7008
		dw 0x6300
		dw 0x7008
		dw 0x6400
		dw 0x7008
		dw 0x6500
		dw 0x7008
		dw 0x6600
		dw 0x7008
		dw 0x6700
		dw 0x7008
		dw 0x6800
		dw 0x7008
		dw 0x6900
		dw 0x7008
		dw 0x6a00
		dw 0x7008
		dw 0x6b00
		dw 0x7008
		dw 0x6c00
		dw 0x7008
		dw 0x6d00
		dw 0x7008
		dw 0x6e00
		dw 0x7008
		dw 0x6f00
		dw 0x7008
		dw 0x2096
		
start_mirror:
		dw 0xc055
		dw 0x40f0 // skip if v > 240
		dw 0xc655
		dw 0x40e8 // skip if v > 232 
		dw 0xc755
		dw 0x40e0 
		dw 0xc855
		dw 0x40d8 
		dw 0xc955
		dw 0x40d0 
		dw 0xca55
		dw 0x40c8 
		dw 0xcb55
		dw 0x40c0 
		dw 0xcc55
		dw 0x40b8 
		dw 0xcd55
		dw 0x40b0 // skip if v > 160 
		dw 0xce55
start_wave:
		.times 16 dw 0xb000
		dw 0x1000 | ((start_mirror - bloodlust_copper_list)>>1) // jump to start mirror
		dw 0x2fff // wait forever
end_bl_copper_list:


global_interrupt_enable:
	sti
	ret

global_interrupt_disable:
	cli
	ret
//
//	mandelbrot inner loop
//
//

// r4 = Re{c}, r5 = Im{c} in 1:7 fixed point 
mandel_loop:
	sub r13, 32	

	st [r13, 16], r6
	st [r13, 18], r7
	st [r13, 20], r8
	st [r13, 22], r9
	st [r13, 24], r10
	st [r13, 26], r11
	st [r13, 28], r12

	// r2: iteration count
	mov r2, 63

	// r6 : Re{z}, r7 : Im{z}
	mov r6, r4
	mov r7, r5

mandel_loop.loop:
	// compute Z^2
	// Re{Z^2} = Re{Z}^2 - Im{z}^2
	// Im{Z^2} = 2Re{Z}Im{Z}
	mov r8,r6
	mov r9,r7
	mov r10, r6
	mul r8,r8	
	mul r9,r9
	mul r10, r7
	nop
	sub r8,r9
	nop
	// r8: Re{Z^2} r9: Im{Z^2}, 2:14 fixed point
	// convert to 1:7 fixed point
	
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8
	asr r10
	nop
	asr r8

	// Z <- Z^2 + C 
	add r10, r5
	nop	
	add r8, r4
	nop

	// Store Z
	mov r7, r10
	mov r6, r8

	// Compute length
	asr r8
	asr r10
	nop
	mul r8, r8
	mul r10, r10
	nop
	nop
	add r8, r10
	nop
	nop

	// > 2?
	cmp r8, (1<<13)
	bgt mandel_loop.done 

	sub r2, 1
	bnz mandel_loop.loop
mandel_loop.done:

	lsr r2
	nop
	nop
	nop
	lsr r2



	ld r6, [r13,16]
	ld r7, [r13,18]
	ld r8, [r13,20]
	ld r9, [r13,22]
	ld r10, [r13,24]
	ld r11, [r13,26]
	ld r12, [r13,28]

	add r13, 32
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


.global set_up_sprites
.text
.text
set_up_sprites:
	sub r13,48
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 30], r10
	st [r13, 32], r11
	st [r13, 34], r12
	mov r12,r0
	add r12, 33848
	mov r9,r0
	add r9, 63
	.times 10 lsl r9 
	mov r10,r9
	or r10,16
	mov r9,r0
	add r9, 273
	st [r13, (-2) + 48], r9 // dodgy
	mov r11,r0
	add r11, 16384
	mov r4,r0
	mov r5,r12
	bl load_sprite_x
	mov r4,r0
	mov r5,r10
	bl load_sprite_y
	mov r4,r0
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl load_sprite_h
	mov r4,r0
	mov r5,r11
	bl load_sprite_a
	mov r12,r0
	add r12, 33912
	mov r11,r0
	add r11, 16400
	mov r4,r0
	add r4, 1
	mov r5,r12
	bl load_sprite_x
	mov r4,r0
	add r4, 1
	mov r5,r10
	bl load_sprite_y
	mov r4,r0
	add r4, 1
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl load_sprite_h
	mov r4,r0
	add r4, 1
	mov r5,r11
	bl load_sprite_a
	mov r12,r0
	add r12, 33976
	mov r11,r0
	add r11, 16416
	mov r4,r0
	add r4, 2
	mov r5,r12
	bl load_sprite_x
	mov r4,r0
	add r4, 2
	mov r5,r10
	bl load_sprite_y
	mov r4,r0
	add r4, 2
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl load_sprite_h
	mov r4,r0
	add r4, 2
	mov r5,r11
	bl load_sprite_a
	mov r12,r0
	add r12, 34040
	mov r11,r0
	add r11, 16432
	mov r4,r0
	add r4, 3
	mov r5,r12
	bl load_sprite_x
	mov r4,r0
	add r4, 3
	mov r5,r10
	bl load_sprite_y
	mov r4,r0
	add r4, 3
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl load_sprite_h
	mov r4,r0
	add r4, 3
	mov r5,r11
	bl load_sprite_a
L.1:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	ld r10, [r13, 30]
	ld r11, [r13, 32]
	ld r12, [r13, 34]
	add r13,48
	ret
.global col
.data
col:
dw 0x12
.global clear_screen
.text
.text
clear_screen:
	sub r13,16
	st [r13, 0], r15
	st [r13, 2], r7
	st [r13, 4], r8
	st [r13, 6], r9
	st [r13, 8], r11
	st [r13, 10], r12
	mov r11,r0
	add r11, 0x8000
	mov r12,r0
L.3:
	mov r9,r11
	mov r11, r9
	add r11,1
	ld r8,[col]
	mov r7, r8
	add r7,1
	st [col], r7
	stb [r9], r8
L.4:
	add r12,1
	cmp r12,30720
	blt L.3
	ld r9,[col]
	add r9,1
	st [col], r9
L.2:
	ld r15, [r13, 0]
	ld r7, [r13, 2]
	ld r8, [r13, 4]
	ld r9, [r13, 6]
	ld r11, [r13, 8]
	ld r12, [r13, 10]
	add r13,16
	ret
.global render_mandelbrot
.text
render_mandelbrot:
	sub r13,64
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 30], r10
	st [r13, 32], r11
	st [r13, 34], r12
	mov r9,r0
	add r9, -192
	st [r13, (-4) + 64], r9 // dodgy
	mov r12,r0
	add r12, -128
	mov r11,r0
	add r11, 1
	mov r9,r0
	add r9, 1
	st [r13, (-6) + 64], r9 // dodgy
	mov r10,r0
	add r10, 0x8000
	st [r13, (-2) + 64], r0 // dodgy
L.8:
	mov r9, r13
	add r9, (-4) + 64
	ld r9,[r9]
	st [r13, (-8) + 64], r9 // dodgy
	st [r13, (-10) + 64], r0 // dodgy
L.12:
	mov r9, r13
	add r9, (-8) + 64
	ld r4,[r9]
	mov r5,r12
	bl mandel_loop
	st [r13, (-12) + 64], r2 // dodgy
	mov r9, r13
	add r9, (-8) + 64
	ld r9,[r9]
	add r9,r11
	st [r13, (-8) + 64], r9 // dodgy
	mov r9, r13
	add r9, (-8) + 64
	ld r4,[r9]
	mov r5,r12
	bl mandel_loop
	st [r13, (-14) + 64], r2 // dodgy
	mov r9, r13
	add r9, (-12) + 64
	ld r9,[r9]
	mov r8, r13
	add r8, (-14) + 64
	ld r8,[r8]
	.times 4 lsl r8 
	or r9,r8
	stb [r13, (-15) + 64], r9 // dodgy
	mov r9,r10
	mov r10, r9
	add r10,1
	mov r8, r13
	add r8, (-15) + 64
	ldb r8,[r8]
	stb [r9], r8
	mov r9, r13
	add r9, (-8) + 64
	ld r9,[r9]
	add r9,r11
	st [r13, (-8) + 64], r9 // dodgy
L.13:
	mov r9, r13
	add r9, (-10) + 64
	ld r9,[r9]
	add r9,1
	st [r13, (-10) + 64], r9 // dodgy
	mov r9, r13
	add r9, (-10) + 64
	ld r9,[r9]
	cmp r9,128
	blt L.12
	mov r9, r13
	add r9, (-6) + 64
	ld r9,[r9]
	add r12,r9
L.9:
	mov r9, r13
	add r9, (-2) + 64
	ld r9,[r9]
	add r9,1
	st [r13, (-2) + 64], r9 // dodgy
	mov r9, r13
	add r9, (-2) + 64
	ld r9,[r9]
	cmp r9,256
	blt L.8
L.7:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	ld r10, [r13, 30]
	ld r11, [r13, 32]
	ld r12, [r13, 34]
	add r13,64
	ret
.global enable_interrupts
.text
enable_interrupts:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	mov r4,r0
	add r4, 28672
	mov r5,r0
	add r5, 2
	bl __out
	bl global_interrupt_enable
L.16:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global ticks
.data
ticks:
dw 0x0
.global cycle_palette
.text
.text
cycle_palette:
	sub r13,48
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 30], r11
	st [r13, 32], r12
	mov r11,r0
	add r11, mandelbrot_palette
	mov r9, r11
	add r9,30
	ld r9,[r9]
	st [r13, (-2) + 48], r9 // dodgy
	ld r9,[ticks]
	add r9,1
	st [ticks], r9
	ld r9,[ticks]
	cmp r9,4
	bne L.17
	st [ticks], r0
L.19:
	mov r12,r0
	add r12, 14
L.20:
	mov r9, r12
	.times 1 lsl r9 
	add r9,r11
	ld r4,[r9]
	bl trace_hex
	mov r9, r12
	.times 1 lsl r9 
	mov r8, r9
	add r8,2
	add r8,r11
	add r9,r11
	ld r9,[r9]
	st [r8], r9
L.21:
	sub r12,1
	cmp r12,r0
	bgt L.20
	mov r9, r11
	add r9,2
	mov r8, r13
	add r8, (-2) + 48
	ld r8,[r8]
	st [r9], r8
	mov r4,r0
	add r4, mandelbrot_palette
	mov r5,r0
	mov r6,r0
	add r6, 16
	bl load_palette
L.17:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	ld r11, [r13, 30]
	ld r12, [r13, 32]
	add r13,48
	ret
.global main
.text
main:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	mov r4,r0
	add r4, 24322
	mov r5,r0
	add r5, 1
	bl __out
	mov r4,r0
	add r4, 23842
	mov r5,r0
	bl __out
	mov r4,r0
	add r4, mandelbrot_palette
	mov r5,r0
	mov r6,r0
	add r6, 16
	bl load_palette
	bl set_up_sprites
	bl render_mandelbrot
	bl enable_interrupts
	ba L.26
L.25:
	bl cycle_palette
	bl __sleep
L.26:
	ba L.25
	mov r4,r0
	add r4, 33
	bl putc
	bl exit
	mov r2,r0
L.24:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
mandelbrot_palette:
	dw 0x000
	dw 0x600
	dw 0x900
	dw 0xa00
	dw 0xe00
	dw 0xf00
	dw 0xf60
	dw 0xf60
	dw 0xfa0
	dw 0xfc0
	dw 0xff0
	dw 0xdff
	dw 0x8ff
	dw 0x09f
	dw 0x76d
	dw 0x30c
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x111
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x222
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x333
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x444
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x555
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x666
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x777
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x888
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0x999
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xaaa
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xbbb
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xccc
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xddd
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xeee
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff
	dw 0xfff


	.end
