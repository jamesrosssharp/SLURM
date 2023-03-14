SOME_EQU equ (-2 + 1024 + 512 - (3 << 2)) / 2

ANOTHER_EQU equ SOME_EQU + 5 + 7

LABEL_EQU equ loop + (2<<3) - 5*3 + 7/3

//BAD_EQU equ (loop + 2) * 3 - 1

//ANOTHER_BAD_EQU equ (1 << loop) + 4

//THIS_IS_ALSO_BAD equ (1 >> (1 - loop))

//YET_ANOTHER_BAD equ ANOTHER_BAD_EQU + 1

	.section text

start:
	mov r1, 4
	add r1, 1
	mov r2, 65535
	mov r3, -7
	mov r4, ANOTHER_EQU
	add r4, 341
	add.z r7, r4, r3
	bl  my_func
	mov r2, my_func2
	bl [r2]
loop:
	add r4, SOME_EQU
	ba loop

	.global my_func
	.function my_func
my_func:
	add r2, r4
	or  r2, 1
	and r2, 0xf
	xor r2, 0xa
	add r2, 5
	adc r2, r0
	sub r2, 3
	sbb r2, r0
	mul r2, 15
	mulu r4, r2
	rrn r2, r4
	rln r4, r2
	cmp r4, 5
	test r2, 3
	umulu r4, r2
	bswap r4, r2
	.times 6*3 asr r4
	mov r3, 0x666
	mov.gtu r2, r3
	mov x127, r3
	add r4, x127

	ret
	.endfunc

	.global my_func2
	.function my_func2
my_func2:
	ld r4, [r0, 0x8000]
	out [r0], r4
	in r2, [r0, 1]
	st [r0, 0x8002], r2
	ret
	.endfunc

	.weak sleep_func
	.function sleep_func
	.extern after_sleep_func
sleep_func:
	sti
	sleep
	nop
	cli
	bl after_sleep_func
	ret
	.endfunc

	.section data
some_var:
	.times 5 + 1 dw 0x666
	.align 8
	dw my_func2
	dw sleep_func

.end
