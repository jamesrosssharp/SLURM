        .org 0h

		mov r4, 0xffff	// Stack pointer; top of mem

		// Push arguments
		mov r0, 20
		st  [r4-], r0 // push
		mov r0, 10
		st  [r4-], r0 // push 

		mov r3,0xa3a3
		mov r1,0xa1a1

		bl  peasant_multiply 
die:
		ba die

peasant_multiply:
		st [r4-], r1 // push r1
		st [r4-], r3 // push r3

		ld r3, [r4,3] // arg 1
		ld r1, [r4,4] // arg 2

		mov r0, 0 // return value in r0
.loop:
		cmp r1,0
		bz  .end_loop
		test r1,1
		bz  .dont_add	
		add r0, r3
.dont_add:
		asr r1
		lsl r3

		ba .loop
.end_loop:
		add r4,1
		ld r3, [r4+] // pop r3
		ld r1, [r4+] // pop r1 
		add r4,1
		ret



		.end
