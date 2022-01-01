		.org 0x0000
		
		mov r0, 0
		mov r2, string
	
loop:
		ld r1, [r2]
		or r1, r1
		bz die
		inc r2
		dw  0x1600 // imm 0x600
		dw  0xe111 // out [0x6000 + r0], r1 
		ba loop

die:
		ba die


string:
	dw "\n\nHello world\n\n"

		.end
