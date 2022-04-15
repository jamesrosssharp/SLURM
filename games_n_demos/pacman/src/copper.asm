
/* r4 = Copper list address
 * r5 = Copper list length */
load_copper_list:
	mov r2, r0
load_copper_list.loop:
	ld r1, [r4, 0]
	out [r2, 0x5400], r1 // Copper list memory
	add r2, 1
	add r4, 1
	sub r5, 1
	bnz load_copper_list.loop
	ret



