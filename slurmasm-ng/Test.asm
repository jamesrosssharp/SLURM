SOME_EQU equ (-2 + 1024 + 512 - (3 << 2)) / 2

ANOTHER_EQU equ SOME_EQU + 5 + 7

LABEL_EQU equ loop + (2<<3) - 5*3 + 7/3

//BAD_EQU equ (loop + 2) * 3 - 1

//ANOTHER_BAD_EQU equ (1 << loop) + 4

//THIS_IS_ALSO_BAD equ (1 >> (1 - loop))

//YET_ANOTHER_BAD equ ANOTHER_BAD_EQU + 1

start:
	mov r1, 4
	add r1, 1
	mov r2, 65535
	mov r3, 7
	mov r4, 0
	add r4, 341
loop:
	add r4, 3
	ba loop



.end
