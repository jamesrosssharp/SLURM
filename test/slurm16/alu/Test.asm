        .org 0h

		mov r4, 0xffff	// Stack pointer; top of mem

		mov r0, 1
		mov r1, 13
		add r2, r1, r0

		incm r0 | r1 | r2
		decm r3 | r4
		incm r0

		.end
