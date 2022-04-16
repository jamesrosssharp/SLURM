CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/pacman.bin

all: $(TARGET)

SRCS = $(wildcard src/*.c)
PREPROCESSED = $(patsubst %.c,build/%.c1,$(SRCS))
ASM_SRCS = $(wildcard src/*.asm)

ASSETS_SRC = assets/sprites.png
ASSETS_ASM = assets/assets.asm

$(ASSETS_ASM): $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py

$(TARGET): $(PREPROCESSED) $(ASM_SRCS) $(ASSETS_ASM) src/top.s
	cat $(PREPROCESSED) > build/all.c1
	$(CC) -target=slurm16 -c build/all.c1 -o build/all.asm
	cat src/top.s $(ASM_SRCS) build/all.asm $(ASSETS_ASM) > build/all_complete.asm
	echo "\n\n\t.end" >> build/all_complete.asm
	$(AS) -o $@ build/all_complete.asm

build/%.c1: %.c
	mkdir -p build/src
	$(CPP) $^ -o $@

clean:
	rm -r build
