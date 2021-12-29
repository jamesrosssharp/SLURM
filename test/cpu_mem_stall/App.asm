		.org 0x0000
		
		ld r0, [MUL_A]
		ld r1, [MUL_B]
		bl  peasant_multiply

die:
		ba die


.padto 0x4000
peasant_multiply:
		mov r3, 0
.loop:
		cmp r1,0
		bz  .end_loop
		test r1,1
		bz  .dont_add	
		add r3, r0
.dont_add:
		asr r1
		lsl r0

		ba .loop
.end_loop:
		ret


.padto 0x8000
MUL_A:
	dw 20
MUL_B:
	dw 10
	.end
