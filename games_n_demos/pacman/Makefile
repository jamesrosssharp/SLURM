CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/pacman.bin

all: $(TARGET)

SRCS = $(wildcard src/*.c)
PREPROCESSED = $(patsubst %.c,build/%.c1,$(SRCS))
ASM_SRCS = $(wildcard src/*.asm)


$(TARGET): $(PREPROCESSED) $(ASM_SRCS)
	cat $(PREPROCESSED) > build/all.c1
	$(CC) -target=slurm16 -c build/all.c1 -o build/all.asm
	cat src/top.s $(ASM_SRCS) build/all.asm > build/all_complete.asm
	$(AS) -o $@ build/all_complete.asm

build/%.c1: %.c
	mkdir -p build/src
	$(CPP) $^ -o $@

clean:
	rm -r build
