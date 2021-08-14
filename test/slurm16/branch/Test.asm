        .org 0h

		mov r4, 0xffff	// Stack pointer; top of mem

		mov r0, the_label
		ba	[r0]

		nop
		nop
		nop
		nop
		nop

die:
		ba die


the_label:	
		mov r1, the_subroutine
		bl [r1]
		ba die


the_subroutine:
		ret

		.end
