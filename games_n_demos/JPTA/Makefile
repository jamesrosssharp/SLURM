CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/jpta.bin

all: $(TARGET)

SRCS = $(wildcard src/*.c)
PREPROCESSED = $(patsubst %.c,build/%.c1,$(SRCS))
ASM_SRCS = $(wildcard src/*.asm)

ASSETS_SRC = assets/JohnSprites.png
ASSETS_ASM = assets/assets.asm
ASSETS_BIN = assets/bundle.bin

$(ASSETS_ASM): $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py

$(TARGET): $(PREPROCESSED) $(ASM_SRCS) $(ASSETS_ASM) $(ASSETS_BIN) src/top.s
	cat $(PREPROCESSED) > build/all.c1
	$(CC) -target=slurm16 -c build/all.c1 -o build/all.asm
	cat src/top.s $(ASM_SRCS) build/all.asm $(ASSETS_ASM)  > build/all_complete.asm
	echo "\n\n\t.end" >> build/all_complete.asm
	$(AS) -o build/all_complete.bin build/all_complete.asm
	# Generate bundle
	dd if=/dev/zero of=$@ bs=1M count=3
	dd if=build/all_complete.bin of=$@ 
	dd if=$(ASSETS_BIN) of=$@ bs=65024 seek=1	


build/%.c1: %.c
	mkdir -p build/src
	$(CPP) $^ -o $@

clean:
	rm -r build
