CC=../lcc/lcc/build/rcc
AS=../../slurmasm/slurmasm

all: output/test.bin

output/test1.asm: test1.c $(CC)
	$(CC) -target=slurm16 -c test1.c -o output/test1.asm
	cat output/test1.asm	

output/test.asm: output/test1.asm top.asm
	cat top.asm output/test1.asm > output/test.asm

output/test.bin: output/test.asm
	$(AS) -o output/test.bin output/test.asm
