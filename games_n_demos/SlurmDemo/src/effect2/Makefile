
include ../../../../common/slurmos/slurmos.mk

CC=../../../../slurmcc/lcc/lcc/build/rcc
CPP=cpp
AS=../../../../slurmasm-ng/slurmasm-ng
LD=../../../../slurmlink/slurmlink
OBJDUMP=../../../../slurm-objdump/slurm-objdump
OBJCOPY=../../../../slurm-objcopy/slurm-objcopy


SRC_DIR = ./
C_SRC	= $(wildcard $(SRC_DIR)/*.c)
ASM_SRC	= $(wildcard $(SRC_DIR)/*.asm)
HEADERS	= $(wildcard $(SRC_DIR)/*.h)

CPP_SRC = $(patsubst %.c,$(BUILD_DIR)/%.c1,$(notdir $(C_SRC)))
C_ASM_SRC = $(patsubst %.c1,%.asm,$(CPP_SRC))
C_OBJ = $(patsubst %.asm,%.o,$(C_ASM_SRC))

CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm1,$(notdir $(ASM_SRC)))
ASM_OBJ = $(patsubst %.asm1,$(BUILD_DIR)/%.asmo,$(notdir $(CPP_ASM)))

BUILD_DIR=build

TARGET=$(BUILD_DIR)/effect2.bin
LINKER_SCRIPT=$(SRC_DIR)/link.ld

TARGET_ELF=$(patsubst %.bin, %.elf, $(TARGET))

all: $(TARGET)

$(BUILD_DIR)/%.c1: $(SRC_DIR)/%.c $(ASSETS_H) $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../../../include -I$(SRC_DIR) -I$(BUILD_DIR) -I../../build -I$(SLURMOS_DIR) $<

$(BUILD_DIR)/%.asm1: $(SRC_DIR)/%.asm $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../../../include -I$(BUILD_DIR) -I$(SLURMOS_DIR) $<

$(BUILD_DIR)/%.asm: $(BUILD_DIR)/%.c1
	$(CC) -target=slurm16_ng -c $< -o $@

$(BUILD_DIR)/%.o : $(BUILD_DIR)/%.asm
	$(AS) -o $@ $<

$(BUILD_DIR)/%.asmo : $(BUILD_DIR)/%.asm1
	$(AS) -o $@ $<

$(TARGET_ELF): $(C_OBJ) $(ASM_OBJ) $(LINKER_SCRIPT)
	$(LD) -s $(LINKER_SCRIPT) -o $@ $(ASM_OBJ) $(C_OBJ)

$(TARGET): $(TARGET_ELF) $(BUNDLE)
	$(OBJCOPY) $< $@

clean:
	rm -r build

