
	.section vectors
my_vector_table:
RESET_VEC:
	ba start
HSYNC_VEC:
	ba start
VSYNC_VEC:
	ba start
AUDIO_VEC:
	ba start
SPI_FLASH:
	ba start
GPIO_VEC:
	ba start
TIMER_VEC:
	ba start
VECTORS:
	.times 20 ba start

	.section text
	.function start
	.global start
start:
	mov r1, 'A'
	out [r0, 0], r1
	mov r2, 5
outer:
	mov r1, 0xffff
loop:
	sub r1, 1
	bnz loop
	
	sub r2, 1
	bnz outer

	ba start

	.endfunc

	.end
