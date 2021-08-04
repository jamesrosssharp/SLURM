        .org 0h

		mov r0, 3
		mov r1, 2
		add r0, r1
die:
		ba die


        .align 100h
TheString:
        dw "Hello World!\r\n"


        .align 100h
StackStart:
        .times 100h dw 0x0
StackEnd:

        .end

