
SRCDIR=../../../src

include ../../common/slurmsrc.mk

PROJECT=sieve

include ../../common/test.mk

CC=../../../slurmcc/lcc/lcc/build/rcc

mem_init1.asm: main.c top.asm bottom.asm
	cpp main.c -o main.c1
	$(CC) -target=slurm16 -c main.c1 -o main.asm
	cat top.asm main.asm bottom.asm > mem_init1.asm

clean:
	rm $(PROJECT)_design
	rm main.c1
	rm main.asm
	rm mem_init1.asm
	rm mem_init1.mem
	rm mem_init1
	rm mem_init2.mem
	rm mem_init2
	rm mem_init3.mem
	rm mem_init3
	rm mem_init4.mem
	rm mem_init4
	rm dump.vcd
	rm rom_image.meminit
