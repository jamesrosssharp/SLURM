
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
		dw 0xd00f
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
		dw 0xd007
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

