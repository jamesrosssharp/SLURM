CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/pocman.bin

all: $(TARGET)

INCLUDES=src/pocman_sound.c
SRCS = src/main.c
#$(wildcard src/*.c)
PREPROCESSED = $(patsubst %.c,build/%.c1,$(SRCS))
ASM_SRCS = $(wildcard src/*.asm)

ASSETS_SRC = assets/sprites.png assets/bg_tiles.png assets/background.tmx
ASSETS_ASM = assets/assets.asm

$(ASSETS_ASM): $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py

$(TARGET): $(PREPROCESSED) $(ASM_SRCS) $(ASSETS_ASM) $(INCLUDES) src/top.s
	cat $(PREPROCESSED) > build/all.c1
	$(CC) -target=slurm16 -c build/all.c1 -o build/all.asm
	cat src/top.s $(ASM_SRCS) build/all.asm $(ASSETS_ASM) > build/all_complete.asm
	echo "\n\n\t.end" >> build/all_complete.asm
	$(AS) -o $@ build/all_complete.asm

build/src/main.c1: src/main.c $(INCLUDES)
	mkdir -p build/src
	$(CPP) src/main.c -o build/src/main.c1

clean:
	rm -r build
