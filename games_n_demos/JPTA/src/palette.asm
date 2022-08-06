
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



