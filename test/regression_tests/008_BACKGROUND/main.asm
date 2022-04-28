.global str
.data
str:
	dw L.1
.global puts
.text
.text
puts:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r6
	st [r13, 22], r7
	st [r13, 24], r8
	st [r13, 26], r9
	st [r13, 28], r11
	st [r13, 30], r12
	mov r12,r4
	ba L.4
L.3:
	mov r4,r11
	bl putc
L.4:
	mov r9,r12
	mov r12, r9
	add r12,1
	ldb r9,[r9]
	mov r11,r9
	mov r9,r9
	cmp r9,r0
	bne L.3
L.2:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r6, [r13, 20]
	ld r7, [r13, 22]
	ld r8, [r13, 24]
	ld r9, [r13, 26]
	ld r11, [r13, 28]
	ld r12, [r13, 30]
	add r13,32
	ret
.global copperList
.data
copperList:
dw 0x6000
dw 0x2fff
.global pocman_start
.data
pocman_start:
dw 0x1
dw 0x1
dw 0xa0
dw 0x78
dw 0x10
dw 0x10
dw 0x0
dw 0x0
dw 0x0
dw 0x1
dw 0x1a
dw 0x800
dw 0x804
dw 0x8
dw 0x804
dw 0xc00
dw 0xc04
dw 0x8
dw 0xc04
dw 0x400
dw 0x404
dw 0x8
dw 0x404
dw 0x0
dw 0x4
dw 0x8
dw 0x4
dw 0x8
dw 0xc
dw 0x10
dw 0x14
dw 0x18
dw 0x1c
dw 0x20
dw 0x24
dw 0x28
dw 0x2c
dw 0x30
dw 0x34
dw 0x38
dw 0x0
.times 6 db 0
dw 0x0
.times 2 db 0
.global update_sprite
.text
.text
update_sprite:
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
	mov r12,r4
	mov r9,r0
	add r9, 1023
	mov r8, r12
	add r8,4
	ld r8,[r8]
	and r8,r9
	ld r7,[r12]
	and r7,1
	.times 10 lsl r7 
	or r8,r7
	or r8,32768
	st [r13, (-4) + 48], r8 // dodgy
	mov r8, r12
	add r8,6
	ld r7,[r8]
	and r7,r9
	mov r6, r12
	add r6,8
	ld r6,[r6]
	and r6,63
	.times 10 lsl r6 
	or r7,r6
	st [r13, (-6) + 48], r7 // dodgy
	ld r8,[r8]
	mov r7, r12
	add r7,10
	ld r7,[r7]
	add r8,r7
	and r8,r9
	st [r13, (-8) + 48], r8 // dodgy
	mov r9, r12
	add r9,16
	ld r8,[r9]
	st [r13, (-2) + 48], r8 // dodgy
	ld r9,[r9]
	and r9,15
	st [r13, (-2) + 48], r9 // dodgy
	mov r9, r12
	add r9,18
	ld r11,[r9]
	mov r9,r0
	add r9, 16
	cmp r11,r9
	beq L.17
	cmp r11,r9
	bgt L.21
L.20:
	mov r9,r0
	add r9, 1
	cmp r11,r9
	blt L.7
	cmp r11,8
	bgt L.7
	mov r9, r11
	.times 1 lsl r9 
	mov r8,r0
	add r8, L.22-2
	add r9,r8
	ld r9,[r9]
	ba [r9]
.data
L.22:
	dw L.10
	dw L.11
	dw L.7
	dw L.12
	dw L.7
	dw L.7
	dw L.7
	dw L.13
.text
L.21:
	cmp r11,32
	beq L.14
	ba L.7
L.10:
	mov r9,r0
	add r9, pacman_sprite_sheet
	.times 1 lsr r9 
	mov r8, r13
	add r8, (-2) + 48
	ld r8,[r8]
	.times 2 lsr r8 
	.times 1 lsl r8 
	mov r7, r12
	add r7,22
	add r8,r7
	ld r8,[r8]
	add r9,r8
	st [r13, (-10) + 48], r9 // dodgy
	ba L.8
L.11:
	mov r9,r0
	add r9, pacman_sprite_sheet
	.times 1 lsr r9 
	mov r8, r13
	add r8, (-2) + 48
	ld r8,[r8]
	.times 2 lsr r8 
	.times 1 lsl r8 
	mov r7, r12
	add r7,30
	add r8,r7
	ld r8,[r8]
	add r9,r8
	st [r13, (-10) + 48], r9 // dodgy
	ba L.8
L.12:
	mov r9,r0
	add r9, pacman_sprite_sheet
	.times 1 lsr r9 
	mov r8, r13
	add r8, (-2) + 48
	ld r8,[r8]
	.times 2 lsr r8 
	.times 1 lsl r8 
	mov r7, r12
	add r7,38
	add r8,r7
	ld r8,[r8]
	add r9,r8
	st [r13, (-10) + 48], r9 // dodgy
	ba L.8
L.13:
	mov r9,r0
	add r9, pacman_sprite_sheet
	.times 1 lsr r9 
	mov r8, r13
	add r8, (-2) + 48
	ld r8,[r8]
	.times 2 lsr r8 
	.times 1 lsl r8 
	mov r7, r12
	add r7,46
	add r8,r7
	ld r8,[r8]
	add r9,r8
	st [r13, (-10) + 48], r9 // dodgy
	ba L.8
L.14:
	mov r9, r12
	add r9,16
	ld r9,[r9]
	cmp r9,26
	ble L.15
	mov r9, r12
	add r9,16
	mov r8,r0
	add r8, 26
	st [r9], r8
L.15:
	mov r9,r0
	add r9, pacman_sprite_sheet
	.times 1 lsr r9 
	mov r8, r12
	add r8,16
	ld r8,[r8]
	.times 1 asr r8 
	.times 1 lsl r8 
	mov r7, r12
	add r7,54
	add r8,r7
	ld r8,[r8]
	add r9,r8
	st [r13, (-10) + 48], r9 // dodgy
	ba L.8
L.17:
	mov r9, r12
	add r9,16
	ld r9,[r9]
	cmp r9,26
	ble L.18
	mov r9, r12
	add r9,16
	mov r8,r0
	add r8, 26
	st [r9], r8
L.18:
	mov r9,r0
	add r9, pacman_sprite_sheet
	.times 1 lsr r9 
	mov r8, r12
	add r8,42
	ld r8,[r8]
	add r9,r8
	st [r13, (-10) + 48], r9 // dodgy
L.7:
L.8:
	mov r9, r12
	add r9,2
	ld r4,[r9]
	mov r9, r13
	add r9, (-4) + 48
	ld r5,[r9]
	bl load_sprite_x
	mov r9, r12
	add r9,2
	ld r4,[r9]
	mov r9, r13
	add r9, (-6) + 48
	ld r5,[r9]
	bl load_sprite_y
	mov r9, r12
	add r9,2
	ld r4,[r9]
	mov r9, r13
	add r9, (-8) + 48
	ld r5,[r9]
	bl load_sprite_h
	mov r9, r12
	add r9,2
	ld r4,[r9]
	mov r9, r13
	add r9, (-10) + 48
	ld r5,[r9]
	bl load_sprite_a
	mov r9, r12
	add r9,20
	ld r9,[r9]
	cmp r9,r0
	beq L.24
	mov r9, r12
	add r9,4
	ld r8,[r9]
	mov r7, r12
	add r7,12
	ld r7,[r7]
	add r8,r7
	st [r9], r8
	mov r9, r12
	add r9,6
	ld r8,[r9]
	mov r7, r12
	add r7,14
	ld r7,[r7]
	add r8,r7
	st [r9], r8
	mov r9, r12
	add r9,20
	ld r8,[r9]
	sub r8,1
	st [r9], r8
	mov r9, r12
	add r9,4
	ld r9,[r9]
	cmp r9,380
	ble L.26
	mov r9, r12
	add r9,4
	mov r8,r0
	add r8, 8
	st [r9], r8
L.26:
	mov r9, r12
	add r9,4
	ld r9,[r9]
	cmp r9,8
	bge L.28
	mov r9, r12
	add r9,4
	mov r8,r0
	add r8, 380
	st [r9], r8
L.28:
	mov r9, r12
	add r9,16
	ld r8,[r9]
	add r8,1
	st [r9], r8
	ba L.25
L.24:
	mov r9, r12
	add r9,12
	st [r9], r0
	mov r9, r12
	add r9,14
	st [r9], r0
	mov r9, r12
	add r9,16
	st [r9], r0
L.25:
L.6:
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
L.30:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global bg_x
.data
bg_x:
dw 0x59
.global bg_y
.data
bg_y:
dw 0x0
.global vx
.data
vx:
dw 0x0
.global vy
.data
vy:
dw 0x0
.global update_background
.text
.text
update_background:
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
	add r4, 23808
	mov r5,r0
	add r5, 33297
	bl __out
	mov r4,r0
	add r4, 23809
	ld r5,[bg_x]
	bl __out
	mov r4,r0
	add r4, 23810
	ld r5,[bg_y]
	bl __out
	mov r4,r0
	add r4, 23811
	mov r9,r0
	add r9, pacman_tilemap
	mov r5, r9
	.times 1 lsr r5 
	bl __out
	mov r4,r0
	add r4, 23812
	mov r9,r0
	add r9, pacman_tileset
	mov r5, r9
	.times 1 lsr r5 
	bl __out
	ld r9,[bg_x]
	ld r8,[vx]
	add r9,r8
	st [bg_x], r9
	ld r9,[bg_y]
	ld r8,[vy]
	add r9,r8
	st [bg_y], r9
	ld r9,[bg_x]
	cmp r9,150
	ble L.32
	mov r9,r0
	add r9, 149
	st [bg_x], r9
	ld r8,[vx]
	mov r7,r0
	sub r7,r8
	st [vx], r7
	ld r8,[vy]
	mov r9,r0
	sub r9,r8
	st [vy], r9
	ba L.33
L.32:
	ld r9,[bg_x]
	cmp r9,r0
	bge L.34
	ld r8,[vx]
	mov r7,r0
	sub r7,r8
	st [vx], r7
	ld r8,[vy]
	mov r9,r0
	sub r9,r8
	st [vy], r9
	st [bg_x], r0
L.34:
L.33:
L.31:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global frame
.data
frame:
dw 0x0
.global main
.text
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
	add r4, copperList
	mov r5,r0
	add r5, 2
	bl load_copper_list
	mov r4,r0
	add r4, 23840
	mov r5,r0
	add r5, 1
	bl __out
	mov r4,r0
	add r4, pacman_spritesheet_palette
	mov r5,r0
	mov r6,r0
	add r6, 16
	bl load_palette
	mov r4,r0
	add r4, pacman_tileset_palette
	mov r9,r0
	add r9, 16
	mov r5,r9
	mov r6,r9
	bl load_palette
	bl enable_interrupts
	ba L.38
L.37:
	mov r4,r0
	add r4, pocman_start
	bl update_sprite
	bl update_background
	bl __sleep
L.38:
	ba L.37
	mov r2,r0
L.36:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.data
L.1:
	db 0x48
	db 0x65
	db 0x6c
	db 0x6c
	db 0x6f
	db 0x20
	db 0x77
	db 0x6f
	db 0x72
	db 0x6c
	db 0x64
	db 0x21
	db 0xa
	db 0x0
.align 2
