
pacman_palette2:
	dw 0
	dw 0xff0
	dw 0x0ff
	dw 0x0f0
	dw 0xedf
	dw 0xfb5
	dw 0xfb9
	dw 0x8ce
	dw 0xfbf
	dw 0xfb5
	dw 0x4be
	dw 0xd95
	dw 0x22f
	dw 0xf00
	dw 0xf00
	dw 0x0
	dw 0x0	

/* r4 = Palette
 * r5 = Number of entries */
load_palette:
	mov r2, r0
load_palette.loop:
	ld r1, [r4, 0]
	out [r2, 0x5e00], r1 // Palette memory
	add r2, 1
	add r4, 2
	sub r5, 1
	bnz load_palette.loop
	ret



