        .org 0h

		mov r0, 20
		mov r1, 10
		bl  multiply
		mov r0, 20
		mov r1, 10
		bl  peasant_multiply
die:
		ba die


multiply:
		mov r3,0
loop:
		add r3, r1
		sub r0, 1
		bnz loop
		ret

peasant_multiply:
		mov r3, r0
loop:
		asr r1
		lsl r0
		bnz 


		ret


		.end
