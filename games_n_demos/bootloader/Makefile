CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm/slurmasm

SRC_DIR=src

TARGET=build/bootloader.bin

all: $(TARGET)

ASM_SRCS = $(wildcard src/*.asm)

ASSETS_SRC = assets/sprites.png assets/bg_tiles.png assets/background.tmx


$(TARGET): $(PREPROCESSED) $(ASM_SRCS) 
	mkdir -p build
	cat $(ASM_SRCS) > build/all_complete.asm
	$(AS) -o $@ build/all_complete.asm

clean:
	rm -r build
