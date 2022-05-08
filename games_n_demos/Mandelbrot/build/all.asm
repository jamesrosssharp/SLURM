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
