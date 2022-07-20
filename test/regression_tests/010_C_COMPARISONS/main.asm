.global print_hex_num
.text
.text
print_hex_num:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r6
	st [r13, 22], r7
	st [r13, 24], r8
	st [r13, 26], r9
	st [r13, 32], r4
	mov r9, r13
	add r9, (0) + 32
	ld r4,[r9]
	bl trace_hex
L.1:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r6, [r13, 20]
	ld r7, [r13, 22]
	ld r8, [r13, 24]
	ld r9, [r13, 26]
	add r13,32
	ret
.global print_dec_num
.text
print_dec_num:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r6
	st [r13, 22], r7
	st [r13, 24], r8
	st [r13, 26], r9
	st [r13, 32], r4
	mov r9, r13
	add r9, (0) + 32
	ld r4,[r9]
	bl trace_dec
L.2:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r6, [r13, 20]
	ld r7, [r13, 22]
	ld r8, [r13, 24]
	ld r9, [r13, 26]
	add r13,32
	ret
.global my_printf
.text
my_printf:
	sub r13,48
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r6
	st [r13, 22], r7
	st [r13, 24], r8
	st [r13, 26], r9
	st [r13, 28], r11
	st [r13, 30], r12
	st [r13, 48], r4
	st [r13, 50], r5
	st [r13, 52], r6
	st [r13, 54], r7
	mov r11, r13
	add r11, (2) + 48
	ba L.7
L.6:
	mov r9,r12
	cmp r9,37
	bne L.9
	mov r9, r13
	add r9, (0) + 48
	ld r9,[r9]
	mov r8, r13
	add r8, (0) + 48
// Nodes weren't the same: 7 9
	mov r7, r9
	add r7,1
	st [r8], r7
	ldb r12,[r9]
	mov r9,r12
	cmp r9,37
	bne L.11
	mov r4,r0
	add r4, 37
	bl trace_char
	ba L.10
L.11:
	mov r9,r12
	cmp r9,120
	bne L.13
// Nodes weren't the same: 9 11
	mov r9, r11
	add r9,2
	mov r11,r9
	add r9,-2
	ld r9,[r9]
	st [r13, (-2) + 48], r9 // dodgy
	mov r9, r13
	add r9, (-2) + 48
	ld r4,[r9]
	bl print_hex_num
	ba L.10
L.13:
	mov r9,r12
	cmp r9,100
	bne L.15
// Nodes weren't the same: 9 11
	mov r9, r11
	add r9,2
	mov r11,r9
	add r9,-2
	ld r4,[r9]
	bl print_dec_num
	ba L.10
L.15:
	mov r4,r0
	add r4, 63
	bl trace_char
	ba L.10
L.9:
	mov r4,r12
	bl trace_char
L.10:
L.7:
	mov r9, r13
	add r9, (0) + 48
	ld r9,[r9]
	mov r8, r13
	add r8, (0) + 48
// Nodes weren't the same: 7 9
	mov r7, r9
	add r7,1
	st [r8], r7
	ldb r9,[r9]
	mov r12,r9
	mov r9,r9
	cmp r9,r0
	bne L.6
L.3:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r6, [r13, 20]
	ld r7, [r13, 22]
	ld r8, [r13, 24]
	ld r9, [r13, 26]
	ld r11, [r13, 28]
	ld r12, [r13, 30]
	add r13,48
	ret
.global is_greater_than
.text
is_greater_than:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	ble L.18
	mov r4,r0
	add r4, L.20
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.19
L.18:
	mov r4,r0
	add r4, L.21
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.19:
L.17:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_less_than
.text
is_less_than:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	bge L.23
	mov r4,r0
	add r4, L.25
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.24
L.23:
	mov r4,r0
	add r4, L.26
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.24:
L.22:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_greater_than_equal
.text
is_greater_than_equal:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	blt L.28
	mov r4,r0
	add r4, L.30
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.29
L.28:
	mov r4,r0
	add r4, L.31
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.29:
L.27:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_less_than_equal
.text
is_less_than_equal:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	bgt L.33
	mov r4,r0
	add r4, L.35
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.34
L.33:
	mov r4,r0
	add r4, L.36
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.34:
L.32:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_greater_than_u
.text
is_greater_than_u:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	bleu L.38
	mov r4,r0
	add r4, L.40
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.39
L.38:
	mov r4,r0
	add r4, L.41
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.39:
L.37:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_less_than_u
.text
is_less_than_u:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	bgeu L.43
	mov r4,r0
	add r4, L.45
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.44
L.43:
	mov r4,r0
	add r4, L.46
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.44:
L.42:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_greater_than_equal_u
.text
is_greater_than_equal_u:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	bltu L.48
	mov r4,r0
	add r4, L.50
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.49
L.48:
	mov r4,r0
	add r4, L.51
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.49:
L.47:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global is_less_than_equal_u
.text
is_less_than_equal_u:
	sub r13,32
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 32], r4
	st [r13, 36], r5
	mov r9, r13
	add r9, (0) + 32
	ld r9,[r9]
	mov r8, r13
	add r8, (4) + 32
	ld r8,[r8]
	cmp r9,r8
	bgtu L.53
	mov r4,r0
	add r4, L.55
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
	ba L.54
L.53:
	mov r4,r0
	add r4, L.56
	mov r9, r13
	add r9, (0) + 32
	ld r5,[r9]
	mov r9, r13
	add r9, (4) + 32
	ld r6,[r9]
	bl my_printf
L.54:
L.52:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	add r13,32
	ret
.global main
.text
main:
	sub r13,48
	st [r13, 16], r15
	st [r13, 18], r4
	st [r13, 20], r5
	st [r13, 22], r6
	st [r13, 24], r7
	st [r13, 26], r8
	st [r13, 28], r9
	st [r13, 30], r10
	st [r13, 32], r11
	st [r13, 34], r12
	mov r12,r0
	add r12, 3
	mov r11,r0
	add r11, 5
	mov r10,r0
	add r10, 3
	mov r9,r0
	add r9, 5
	st [r13, (-2) + 48], r9 // dodgy
	mov r4,r12
	mov r5,r11
	bl is_greater_than
	mov r4,r12
	mov r5,r11
	bl is_less_than
	mov r4,r12
	mov r5,r11
	bl is_greater_than_equal
	mov r4,r12
	mov r5,r11
	bl is_less_than_equal
	mov r12,r0
	add r12, 32767
	mov r11,r0
	add r11, -32768
	mov r4,r12
	mov r5,r11
	bl is_greater_than
	mov r4,r12
	mov r5,r11
	bl is_less_than
	mov r4,r12
	mov r5,r11
	bl is_greater_than_equal
	mov r4,r12
	mov r5,r11
	bl is_less_than_equal
	mov r9,r0
	add r9, 768
	mov r12,r9
	mov r11,r9
	mov r4,r12
	mov r5,r11
	bl is_greater_than
	mov r4,r12
	mov r5,r11
	bl is_less_than
	mov r4,r12
	mov r5,r11
	bl is_greater_than_equal
	mov r4,r12
	mov r5,r11
	bl is_less_than_equal
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_greater_than_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_less_than_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_greater_than_equal_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_less_than_equal_u
	mov r10,r0
	add r10, 0xffff
	mov r9,r0
	add r9, 1
	st [r13, (-2) + 48], r9 // dodgy
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_greater_than_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_less_than_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_greater_than_equal_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_less_than_equal_u
	mov r9,r0
	add r9, 768
	mov r10,r9
	st [r13, (-2) + 48], r9 // dodgy
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_greater_than_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_less_than_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_greater_than_equal_u
	mov r4,r10
	mov r9, r13
	add r9, (-2) + 48
	ld r5,[r9]
	bl is_less_than_equal_u
L.58:
L.59:
	ba L.58
	mov r2,r0
L.57:
	ld r15, [r13, 16]
	ld r4, [r13, 18]
	ld r5, [r13, 20]
	ld r6, [r13, 22]
	ld r7, [r13, 24]
	ld r8, [r13, 26]
	ld r9, [r13, 28]
	ld r10, [r13, 30]
	ld r11, [r13, 32]
	ld r12, [r13, 34]
	add r13,48
	ret
__va_arg_tmp:
	dw 0
	dw 0
.data
L.56:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.55:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.51:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.50:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.46:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.45:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.41:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x78
	db 0x20
	db 0xa
	db 0x0
.align 2
L.40:
	db 0x25
	db 0x78
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x78
	db 0xa
	db 0x0
.align 2
L.36:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.35:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.31:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.30:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x69
	db 0x20
	db 0x6f
	db 0x72
	db 0x20
	db 0x65
	db 0x71
	db 0x75
	db 0x61
	db 0x6c
	db 0x20
	db 0x74
	db 0x6f
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.26:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.25:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6c
	db 0x65
	db 0x73
	db 0x73
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.21:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x6e
	db 0x6f
	db 0x74
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
L.20:
	db 0x25
	db 0x64
	db 0x20
	db 0x69
	db 0x73
	db 0x20
	db 0x67
	db 0x72
	db 0x65
	db 0x61
	db 0x74
	db 0x65
	db 0x72
	db 0x20
	db 0x74
	db 0x68
	db 0x61
	db 0x6e
	db 0x20
	db 0x25
	db 0x64
	db 0xa
	db 0x0
.align 2
