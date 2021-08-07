        .org 0h

		mov r0, 20
		mov r1, 10
		bl  multiply
die:
		ba die


multiply:
		mov r3,0
loop:
		add r3, r1
		sub r0, 1
		bnz loop
		ret

		.end
