	.section data

frame:
	dw 0

plasma_sin:
	db 0x20
	db 0x21
	db 0x22
	db 0x22
	db 0x23
	db 0x24
	db 0x25
	db 0x25
	db 0x26
	db 0x27
	db 0x28
	db 0x28
	db 0x29
	db 0x2a
	db 0x2a
	db 0x2b
	db 0x2c
	db 0x2d
	db 0x2d
	db 0x2e
	db 0x2f
	db 0x2f
	db 0x30
	db 0x31
	db 0x31
	db 0x32
	db 0x32
	db 0x33
	db 0x34
	db 0x34
	db 0x35
	db 0x35
	db 0x36
	db 0x36
	db 0x37
	db 0x37
	db 0x38
	db 0x38
	db 0x39
	db 0x39
	db 0x3a
	db 0x3a
	db 0x3b
	db 0x3b
	db 0x3b
	db 0x3c
	db 0x3c
	db 0x3c
	db 0x3d
	db 0x3d
	db 0x3d
	db 0x3d
	db 0x3e
	db 0x3e
	db 0x3e
	db 0x3e
	db 0x3e
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3f
	db 0x3e
	db 0x3e
	db 0x3e
	db 0x3e
	db 0x3e
	db 0x3d
	db 0x3d
	db 0x3d
	db 0x3d
	db 0x3c
	db 0x3c
	db 0x3c
	db 0x3b
	db 0x3b
	db 0x3b
	db 0x3a
	db 0x3a
	db 0x39
	db 0x39
	db 0x38
	db 0x38
	db 0x37
	db 0x37
	db 0x36
	db 0x36
	db 0x35
	db 0x35
	db 0x34
	db 0x34
	db 0x33
	db 0x32
	db 0x32
	db 0x31
	db 0x31
	db 0x30
	db 0x2f
	db 0x2f
	db 0x2e
	db 0x2d
	db 0x2d
	db 0x2c
	db 0x2b
	db 0x2a
	db 0x2a
	db 0x29
	db 0x28
	db 0x28
	db 0x27
	db 0x26
	db 0x25
	db 0x25
	db 0x24
	db 0x23
	db 0x22
	db 0x22
	db 0x21
	db 0x20
	db 0x1f
	db 0x1f
	db 0x1e
	db 0x1d
	db 0x1c
	db 0x1c
	db 0x1b
	db 0x1a
	db 0x19
	db 0x19
	db 0x18
	db 0x17
	db 0x16
	db 0x16
	db 0x15
	db 0x14
	db 0x13
	db 0x13
	db 0x12
	db 0x11
	db 0x11
	db 0x10
	db 0xf
	db 0xf
	db 0xe
	db 0xe
	db 0xd
	db 0xc
	db 0xc
	db 0xb
	db 0xb
	db 0xa
	db 0xa
	db 0x9
	db 0x9
	db 0x8
	db 0x8
	db 0x7
	db 0x7
	db 0x6
	db 0x6
	db 0x5
	db 0x5
	db 0x5
	db 0x4
	db 0x4
	db 0x4
	db 0x3
	db 0x3
	db 0x3
	db 0x3
	db 0x2
	db 0x2
	db 0x2
	db 0x2
	db 0x2
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x1
	db 0x2
	db 0x2
	db 0x2
	db 0x2
	db 0x2
	db 0x3
	db 0x3
	db 0x3
	db 0x3
	db 0x4
	db 0x4
	db 0x4
	db 0x5
	db 0x5
	db 0x5
	db 0x6
	db 0x6
	db 0x7
	db 0x7
	db 0x8
	db 0x8
	db 0x8
	db 0x9
	db 0x9
	db 0xa
	db 0xb
	db 0xb
	db 0xc
	db 0xc
	db 0xd
	db 0xd
	db 0xe
	db 0xf
	db 0xf
	db 0x10
	db 0x11
	db 0x11
	db 0x12
	db 0x13
	db 0x13
	db 0x14
	db 0x15
	db 0x15
	db 0x16
	db 0x17
	db 0x18
	db 0x18
	db 0x19
	db 0x1a
	db 0x1b
	db 0x1b
	db 0x1c
	db 0x1d
	db 0x1e
	db 0x1e
	db 0x1f

	.section text
	.function asm_plasma
	.global asm_plasma

asm_plasma:

	sub r13, 64

	// Preserve registers
	st [r13, 0], r2
	st [r13, 2], r3
	st [r13, 4], r4
	st [r13, 6], r5
	st [r13, 8], r6
	st [r13, 10], r7
	st [r13, 12], r8
	st [r13, 14], r9
	st [r13, 16], r10
	st [r13, 18], r11
	st [r13, 20], r12
	st [r13, 22], r1
	st [r13, 24], r15 

	mov r6, 32	
	
	ld r7, [r0, frame]
	mov r12, r7

	mov r1, r7
	mov r2, r7

plasma_outer_loop:
	mov r5, 42
	mov r11, r7
	mov r1, r7
plasma_inner_loop:
	mov r9, r11
	and r9, 0xff
	ldb  r8, [r9, plasma_sin]
	mov r9, r12
	and r9, 0xff
	ldb  r10, [r9, plasma_sin]
	add r8, r10
	mov r9, r1
	and r9, 0xff
	ldb  r10, [r9, plasma_sin]
	add r8, r10
	mov r9, r2
	and r9, 0xff
	ldb  r10, [r9, plasma_sin]
	add r8, r10
	add r11, 15
	add r1, 7
	stb [r4], r8
	add r4, 1
	sub r5, 1
	bnz plasma_inner_loop
	add r4, 22
	add r12, 9
	add r2, 13
	sub r6, 1
	bnz plasma_outer_loop
	
	add r7, 3

	st [r0, frame], r7

	ld r2, [r13, 0]
	ld r3, [r13, 2]
	ld r4, [r13, 4]
	ld r5, [r13, 6]
	ld r6, [r13, 8]
	ld r7, [r13, 10]
	ld r8, [r13, 12]
	ld r9, [r13, 14]
	ld r10, [r13, 16]
	ld r11, [r13, 18]
	ld r12, [r13, 20]
	ld r1, [r13, 22]
	ld r15, [r13, 24]

	add r13, 64

	// Restore old stack pointer
	ret

	.endfunc

	.end
