        .org 0h

		mov r0, 45
		mov r1, 19
		add r0, r1
		mov r2, 16

loop:
		add r2, r1
		sub r0, 1
		bnz loop

die:
		ba die		


		.end


