CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/chiptunemem.bin

all: $(TARGET)

SRCS = $(wildcard src/*.c)
PREPROCESSED = $(patsubst %.c,build/%.c1,$(SRCS))
ASM_SRCS = $(wildcard src/*.asm)

ASSETS_SRC = assets/chiptune.slurmsng
ASSETS_ASM = assets/assets.asm
ASSETS_BIN = assets/bundle.bin
C_INC = $(wildcard src/*.cc)


assets/chiptune.slurmsng: assets/chiptune.it
	python3 assets/it2slurmsng.py assets/chiptune.it assets/chiptune.slurmsng

$(ASSETS_ASM): $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py

$(TARGET): $(PREPROCESSED) $(ASM_SRCS) $(ASSETS_ASM) $(ASSETS_BIN) src/top.s src/bottom.s $(C_INC)
	cat $(PREPROCESSED) > build/all.c1
	$(CC) -target=slurm16 -c build/all.c1 -o build/all.asm
	cat src/top.s $(ASM_SRCS) build/all.asm $(ASSETS_ASM) src/bottom.s  > build/all_complete.asm
	echo "\n\n\t.end" >> build/all_complete.asm
	$(AS) -o build/all_complete.bin build/all_complete.asm
	# Generate bundle
	dd if=/dev/zero of=$@ bs=1M count=3
	dd if=build/all_complete.bin of=$@ 
	dd if=$(ASSETS_BIN) of=$@ bs=65024 seek=1	


build/%.c1: %.c $(C_INC) assets/bundle.h
	mkdir -p build/src
	$(CPP) -I../../include -Iassets $< -o $@

clean:
	rm -r build
