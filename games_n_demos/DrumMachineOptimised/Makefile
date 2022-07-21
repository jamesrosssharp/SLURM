CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/drummachine.bin

all: $(TARGET)

SRCS = $(wildcard src/*.c)
PREPROCESSED = $(patsubst %.c,build/%.c1,$(SRCS))
ASM_SRCS = $(wildcard src/*.asm)

C_INC = $(wildcard src/*.cc)


$(TARGET): $(PREPROCESSED) $(ASM_SRCS) src/top.s src/bottom.s assets/samples.asm $(C_INC)
	cat $(PREPROCESSED) > build/all.c1
	$(CC) -target=slurm16 -c build/all.c1 -o build/all.asm
	cat src/top.s $(ASM_SRCS) build/all.asm src/bottom.s assets/samples.asm  > build/all_complete.asm
	echo "\n\n\t.end" >> build/all_complete.asm
	$(AS) -o build/all_complete.bin build/all_complete.asm
	# Generate bundle
	dd if=/dev/zero of=$@ bs=1M count=3
	dd if=build/all_complete.bin of=$@ 


build/%.c1: %.c $(C_INC)
	mkdir -p build/src
	$(CPP) -I../../include -Iassets $< -o $@

clean:
	rm -r build
