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

CPP_SRC = $(patsubst %.c,$(BUILD_DIR)/%.c1,$(notdir $(C_SRC)))
C_ASM_SRC = $(patsubst %.c1,%.asm,$(CPP_SRC))
C_OBJ = $(patsubst %.asm,%.o,$(C_ASM_SRC))

CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm1,$(notdir $(ASM_SRC)))
ASM_OBJ = $(patsubst %.asm1,$(BUILD_DIR)/%.asmo,$(notdir $(CPP_ASM)))

TARGET_ELF=$(patsubst %.bin, %.elf, $(TARGET))

.PRECIOUS: $(C_ASM_SRC) $(CPP_SRC) $(CPP_ASM)

ASSETS_SRC = assets/demo.slurmsng
ASSETS_H   = assets/bundle.h
BUNDLE     = assets/bundle.bin

$(info $(ASM_OBJ))

all: $(TARGET)

assets/demo.slurmsng: assets/demo.it
	python3 ../../scripts/it2slurmsng.py assets/demo.it assets/demo.slurmsng

$(ASSETS_H): $(ASSETS_SRC) assets/gen-assets.py
	cd assets; python3 gen-assets.py

$(BUILD_DIR)/%.c1: $(SRC_DIR)/%.c $(ASSETS_H)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -Iassets $<

$(BUILD_DIR)/%.asm1: $(SRC_DIR)/%.asm
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -Iassets $<

$(BUILD_DIR)/%.asm: $(BUILD_DIR)/%.c1
	$(CC) -target=slurm16_ng -c $< -o $@

$(BUILD_DIR)/%.o : $(BUILD_DIR)/%.asm
	$(AS) -o $@ $<

$(BUILD_DIR)/%.asmo : $(BUILD_DIR)/%.asm1
	$(AS) -o $@ $<

$(TARGET_ELF): $(C_OBJ) $(ASM_OBJ) $(LINKER_SCRIPT)
	$(LD) -s $(LINKER_SCRIPT) -o $@ $(ASM_OBJ) $(C_OBJ)

$(TARGET): $(TARGET_ELF) $(BUNDLE)
	$(OBJCOPY) $< $(BUILD_DIR)/app.bin
	dd if=/dev/zero of=$@ bs=1M count=3
	dd if=$(BUILD_DIR)/app.bin of=$@ 
	dd if=$(BUNDLE) of=$@ bs=65024 seek=1	

clean:
	rm -r build

dump:	$(TARGET_ELF)
	$(OBJDUMP) $(TARGET_ELF)
