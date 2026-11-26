# game.mk: common rules for building a game or demo that does not use SlurmOS
# with the clang SLURM16 toolchain (see clang/README.md).
#
# A project Makefile sets NAME (and optionally LEGACY_ASM, BUNDLE, EXTRA_DEPS)
# then includes this file:
#
#   NAME         output name: build/$(NAME).bin is the flash image
#   LEGACY_ASM   generated assembly in the old slurmasm format (e.g.
#                assets/assets.asm), converted for slurmasm-ng at build time
#                by legacy-asm.py; LEGACY_FLAGS_<file name> gives extra
#                converter options for a file (e.g. --hidata)
#   BUNDLE       asset bundle placed in flash after the program (optional)
#   EXTRA_DEPS   files the C sources depend on (generated headers, ...)
#   C_SRC        C sources to compile (default: src/*.c)

GAMES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

include $(GAMES_DIR)../common/clang.mk

BUILD_DIR     = build
LINKER_SCRIPT = $(GAMES_DIR)game.ld

C_SRC  ?= $(wildcard src/*.c)
ASM_SRC = $(wildcard src/*.asm)
HEADERS = $(wildcard src/*.h src/*.cc)

C_OBJ   = $(patsubst %.c,$(BUILD_DIR)/%.o,$(notdir $(C_SRC)))
ASM_OBJ = $(patsubst %.asm,$(BUILD_DIR)/%.asmo,$(notdir $(ASM_SRC)))
LEGACY_OBJ = $(patsubst %.asm,$(BUILD_DIR)/%.lasmo,$(notdir $(LEGACY_ASM)))

CFLAGS += -I$(GAMES_DIR)../include -I$(GAMES_DIR)include -Isrc -Iassets

APP_ELF = $(BUILD_DIR)/$(NAME).elf
APP_BIN = $(BUILD_DIR)/$(NAME)_app.bin
TARGET  = $(BUILD_DIR)/$(NAME).bin

vpath %.asm $(sort $(dir $(ASM_SRC) $(LEGACY_ASM)))

all: $(TARGET)

$(BUILD_DIR)/%.o: src/%.c $(HEADERS) $(EXTRA_DEPS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.asmo: %.asm
	mkdir -p $(BUILD_DIR)
	$(AS) -o $@ $< > $@.log || { cat $@.log; exit 1; }

$(BUILD_DIR)/%.lasm: %.asm $(GAMES_DIR)legacy-asm.py
	mkdir -p $(BUILD_DIR)
	python3 $(GAMES_DIR)legacy-asm.py $(LEGACY_FLAGS_$*) $< $@

$(BUILD_DIR)/%.lasmo: $(BUILD_DIR)/%.lasm
	$(AS) -o $@ $< > $@.log || { cat $@.log; exit 1; }

$(APP_ELF): $(C_OBJ) $(ASM_OBJ) $(LEGACY_OBJ) $(LINKER_SCRIPT)
	$(LD) -s $(LINKER_SCRIPT) -o $@ $(ASM_OBJ) $(LEGACY_OBJ) $(C_OBJ) $(CLANG_RT_OBJS) > $(BUILD_DIR)/link.log

$(APP_BIN): $(APP_ELF)
	$(OBJCOPY) $< $@

# Flash image: the program at offset 0 (the boot loader copies it to 0x200),
# then the asset bundle (if any) at 65024 bytes.
$(TARGET): $(APP_BIN) $(BUNDLE)
	dd if=/dev/zero of=$@ bs=1M count=3 status=none
	dd if=$(APP_BIN) of=$@ status=none
	$(if $(BUNDLE),dd if=$(BUNDLE) of=$@ bs=65024 seek=1 status=none)

clean:
	rm -rf $(BUILD_DIR)

dump: $(APP_ELF)
	$(OBJDUMP) $(APP_ELF)

.PHONY: all clean dump
