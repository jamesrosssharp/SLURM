CC=../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../slurmasm-ng/slurmasm-ng
LD=../../slurmlink/slurmlink
OBJDUMP=../../slurm-objdump/slurm-objdump
OBJCOPY=../../slurm-objcopy/slurm-objcopy

SRC_DIR=src


BUILD_DIR=build

TARGET=$(BUILD_DIR)/slurm_demo.bin
LINKER_SCRIPT=$(SRC_DIR)/link.ld

C_SRC	= $(wildcard $(SRC_DIR)/*.c)
ASM_SRC	= $(wildcard $(SRC_DIR)/*.asm)
HEADERS	= $(wildcard $(SRC_DIR)/*.h)

CPP_SRC = $(patsubst %.c,$(BUILD_DIR)/%.c1,$(notdir $(C_SRC)))
C_ASM_SRC = $(patsubst %.c1,%.asm,$(CPP_SRC))
C_OBJ = $(patsubst %.asm,%.o,$(C_ASM_SRC))

CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm1,$(notdir $(ASM_SRC)))
ASM_OBJ = $(patsubst %.asm1,$(BUILD_DIR)/%.asmo,$(notdir $(CPP_ASM)))

TARGET_ELF=$(patsubst %.bin, %.elf, $(TARGET))


CHIPTUNE = assets/songs/demo.it
CHIPTUNE_SLMSNG = $(BUILD_DIR)/demo.slurmsng
ASSETS_H   = $(BUILD_DIR)/bundle.h
BUNDLE     = $(BUILD_DIR)/bundle.bin

APPLETS_H  = $(BUILD_DIR)/applet_bundle.h
APP_BUNDLE = $(BUILD_DIR)/applet_bundle.bin

include ../../common/slurmos/slurmos.mk

.PRECIOUS: $(SLURMOS_C_ASM_SRC) $(C_ASM_SRC) $(CPP_SRC) $(CPP_ASM)

APPLETS=$(SRC_DIR)/effect1 \
	$(SRC_DIR)/effect2 \
	$(SRC_DIR)/effect3 \
	$(SRC_DIR)/effect4

all: $(TARGET)

.PHONY: $(APPLETS)
$(APPLETS): 
	make -C $@

$(CHIPTUNE_SLMSNG): $(CHIPTUNE) Makefile
	mkdir -p $(BUILD_DIR)
	python3 ../../scripts/it2slurmsng.py $(CHIPTUNE) $(CHIPTUNE_SLMSNG)

$(ASSETS_H): assets/gen-assets.py $(CHIPTUNE_SLMSNG)
	cd assets; python3 gen-assets.py

$(APPLETS_H): $(APPLETS) assets/gen-applets.py
	cd assets; python3 gen-applets.py

$(BUILD_DIR)/%.c1: $(SRC_DIR)/%.c $(ASSETS_H) $(APPLETS_H) $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -I$(SRC_DIR) -I$(BUILD_DIR) -I$(SLURMOS_DIR) $<

$(BUILD_DIR)/%.asm1: $(SRC_DIR)/%.asm $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -I$(BUILD_DIR) $<

$(BUILD_DIR)/%.asm: $(BUILD_DIR)/%.c1
	$(CC) -target=slurm16_ng -c $< -o $@

$(BUILD_DIR)/%.o : $(BUILD_DIR)/%.asm
	$(AS) -o $@ $<

$(BUILD_DIR)/%.asmo : $(BUILD_DIR)/%.asm1
	$(AS) -o $@ $<

$(TARGET_ELF): $(C_OBJ) $(ASM_OBJ) $(SLURMOS_OBJ) $(LINKER_SCRIPT)
	$(LD) -s $(LINKER_SCRIPT) -o $@ $(ASM_OBJ) $(C_OBJ) $(SLURMOS_OBJ)

$(TARGET): $(TARGET_ELF) $(BUNDLE) $(APP_BUNDLE)
	$(OBJCOPY) $< $(BUILD_DIR)/app.bin
	dd if=/dev/zero of=$@ bs=1M count=3
	dd if=$(BUILD_DIR)/app.bin of=$@ 
	cat $(BUNDLE) $(APP_BUNDLE) > $(BUILD_DIR)/all_bundle.bin
	dd if=$(BUILD_DIR)/all_bundle.bin of=$@ bs=65024 seek=1	

clean:
	rm -r build
	for APP in $(APPLETS); do make -C $$APP clean; done

dump:	$(TARGET_ELF)
	$(OBJDUMP) $(TARGET_ELF)
