SOME_EQU equ (-2 + 1024 + 512 - (3 << 2)) / 2

ANOTHER_EQU equ 5 + 7

LABEL_EQU equ loop + 2 - 5*3 + 7

BAD_EQU equ (loop + 2) * 3 - 1

ANOTHER_BAD_EQU equ (1 << loop) + 4

THIS_IS_ALSO_BAD equ (1 >> (1 - loop))

start:
	mov r1, 4
	add r1, 1
loop:
	ba loop



.end
