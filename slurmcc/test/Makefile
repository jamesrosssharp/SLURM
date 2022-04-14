CC=../lcc/lcc/build/rcc
AS=../../slurmasm/slurmasm

all: output/test.bin output/test2c.bin output/test3c.bin output/test4c.bin

output/test1.asm: test1.c $(CC)
	$(CC) -target=slurm16 -c test1.c -o output/test1.asm
	cat output/test1.asm	

output/test.asm: output/test1.asm top.asm
	cat top.asm output/test1.asm > output/test.asm

output/test.bin: output/test.asm
	$(AS) -o output/test.bin output/test.asm

output/test2.c: test2.c
	cpp test2.c -o output/test2.c

output/test2.asm: output/test2.c $(CC)
	$(CC) -target=slurm16 -c output/test2.c -o output/test2.asm
	cat output/test2.asm	

output/test2c.asm: output/test2.asm top.asm
	cat top.asm output/test2.asm > output/test2c.asm

output/test2c.bin: output/test2c.asm
	$(AS) -o output/test2c.bin output/test2c.asm

output/test3.c: test3.c
	cpp test3.c -o output/test3.c

output/test3.asm: output/test3.c $(CC)
	$(CC) -target=slurm16 -c output/test3.c -o output/test3.asm
	cat output/test3.asm	

output/test3c.asm: output/test3.asm top.asm
	cat top.asm output/test3.asm > output/test3c.asm

output/test3c.bin: output/test3c.asm
	$(AS) -o output/test3c.bin output/test3c.asm

output/test4.c: test4.c
	cpp test4.c -o output/test4.c

output/test4.asm: output/test4.c $(CC)
	$(CC) -target=slurm16 -c output/test4.c -o output/test4.asm
	cat output/test4.asm	

output/test4c.asm: output/test4.asm top.asm
	cat top.asm output/test4.asm > output/test4c.asm

output/test4c.bin: output/test4c.asm
	$(AS) -o output/test4c.bin output/test4c.asm

