CC=../lcc/lcc/build/rcc
AS=../../slurmasm/slurmasm

all: output/test.bin output/test2.bin

output/test1.asm: test1.c $(CC)
	$(CC) -target=slurm16 -c test1.c -o output/test1.asm
	cat output/test1.asm	

output/test.asm: output/test1.asm top.asm
	cat top.asm output/test1.asm > output/test.asm

output/test.bin: output/test.asm
	$(AS) -o output/test.bin output/test.asm

output/test2.asm: test2.c $(CC)
	$(CC) -target=slurm16 -c test2.c -o output/test2.asm
	cat output/test2.asm	

output/test2c.asm: output/test2.asm top.asm
	cat top.asm output/test2.asm > output/test2c.asm

output/test2.bin: output/test2c.asm
	$(AS) -o output/test2c.bin output/test2c.asm

