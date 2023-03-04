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
ASM_SRC	= $(SRC_DIR)/top.s

CPP_SRC = $(patsubst %.c,$(BUILD_DIR)/%.c1,$(notdir $(C_SRC)))
C_ASM_SRC = $(patsubst %.c1,%.asm,$(CPP_SRC))
C_OBJ = $(patsubst %.asm,%.o,$(C_ASM_SRC))

ASM_OBJ = $(patsubst %.s,$(BUILD_DIR)/%.asmo,$(notdir $(ASM_SRC)))

TARGET_ELF=$(patsubst %.bin, %.elf, $(TARGET))

.PRECIOUS: $(C_ASM_SRC) $(CPP_SRC)

all: $(TARGET)

$(BUILD_DIR)/%.c1: $(SRC_DIR)/%.c
	mkdir -p $(BUILD_DIR)
	$(CPP) $< -o $@

$(BUILD_DIR)/%.asm: $(BUILD_DIR)/%.c1
	$(CC) -target=slurm16_ng -c $< -o $@

$(BUILD_DIR)/%.o : $(BUILD_DIR)/%.asm
	$(AS) -o $@ $<

$(BUILD_DIR)/%.asmo : $(SRC_DIR)/%.s
	$(AS) -o $@ $<

$(TARGET_ELF): $(C_OBJ) $(ASM_OBJ) $(LINKER_SCRIPT)
	$(LD) -s $(LINKER_SCRIPT) -o $@ $(ASM_OBJ) $(C_OBJ)

$(TARGET): $(TARGET_ELF)
	$(OBJCOPY) $< $@

clean:
	rm -r build

dump:	$(TARGET_ELF)
	$(OBJDUMP) $(TARGET_ELF)
