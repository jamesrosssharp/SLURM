
SLURMOS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

$(info SlurmOS is in $(SLURMOS_DIR))

# Build with the clang SLURM16 toolchain.
include $(SLURMOS_DIR)/../clang.mk

SLURMOS_SRC	= $(wildcard $(SLURMOS_DIR)/*.c)
SLURMOS_ASM_SRC	= $(wildcard $(SLURMOS_DIR)/*.asm)
SLURMOS_HEADERS	= $(wildcard $(SLURMOS_DIR)/*.h)

SLURM_OS_C_OBJ    = $(patsubst %.c,$(BUILD_DIR)/%.co,$(notdir $(SLURMOS_SRC)))

SLURMOS_CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm11,$(notdir $(SLURMOS_ASM_SRC)))
SLURMOS_ASM_OBJ = $(patsubst %.asm11,$(BUILD_DIR)/%.asmo1,$(notdir $(SLURMOS_CPP_ASM)))

SLURMOS_OBJ = $(SLURM_OS_C_OBJ) $(SLURMOS_ASM_OBJ)

$(BUILD_DIR)/%.co: $(SLURMOS_DIR)/%.c $(ASSETS_H) $(HEADERS) $(SLURMOS_HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -I$(SLURMOS_DIR)../../include -I$(SLURMOS_DIR) -I$(BUILD_DIR) -c -o $@ $<

$(BUILD_DIR)/%.asm11: $(SLURMOS_DIR)/%.asm $(SLURMOS_HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I$(SLURMOS_DIR)../../include -I$(BUILD_DIR) $<

$(BUILD_DIR)/%.asmo1 : $(BUILD_DIR)/%.asm11
	$(AS) -o $@ $<


