        .org 0h

		mov r4, 0xffff	// Stack pointer; top of mem

		mov r0, the_label
		ba	[r0]
		

		nop
		nop
		nop
		nop
		nop

before_die:
		mov r0, the_label2
		bl  [r0,1]

		ba.r after_die

die:
		ba.r die
after_die:
		ba.r die

the_label:	
		mov r1, the_subroutine
		bl [r1]
		ba before_die


the_subroutine:
		ret

the_label2:
		nop
		mov r0, 10
		ret

		.end
