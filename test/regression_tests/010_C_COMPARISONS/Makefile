
SRCDIR=../../../src

include ../../common/slurmsrc.mk

PROJECT=ansi_c

include ../../common/test.mk

CC=../../../slurmcc/lcc/lcc/build/rcc

mem_init1.asm: main.c top.asm
	cpp main.c -o main.cc
	$(CC) -target=slurm16 -c main.cc -o main.asm
	cat top.asm main.asm > mem_init1.asm
	echo "\t.end\n" >> mem_init1.asm


