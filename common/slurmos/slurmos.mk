
SLURMOS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

$(info SlurmOS is in $(SLURMOS_DIR))

SLURMOS_SRC	= $(wildcard $(SLURMOS_DIR)/*.c)
SLURMOS_ASM_SRC	= $(wildcard $(SLURMOS_DIR)/*.asm)
SLURMOS_HEADERS	= $(wildcard $(SLURMOS_DIR)/*.h)

SLURMOS_CPP_SRC   = $(patsubst %.c,$(BUILD_DIR)/%.cc1,$(notdir $(SLURMOS_SRC)))
SLURMOS_C_ASM_SRC = $(patsubst %.cc1,%.casm,$(SLURMOS_CPP_SRC))
SLURM_OS_C_OBJ    = $(patsubst %.casm,%.co,$(SLURMOS_C_ASM_SRC))

SLURMOS_CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm11,$(notdir $(SLURMOS_ASM_SRC)))
SLURMOS_ASM_OBJ = $(patsubst %.asm11,$(BUILD_DIR)/%.asmo1,$(notdir $(SLURMOS_CPP_ASM)))

SLURMOS_OBJ = $(SLURM_OS_C_OBJ) $(SLURMOS_ASM_OBJ)

$(BUILD_DIR)/%.cc1: $(SLURMOS_DIR)/%.c $(ASSETS_H) $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -I$(SLURMOS_DIR) -I$(BUILD_DIR) $<

$(BUILD_DIR)/%.asm11: $(SLURMOS_DIR)/%.asm $(SLURMOS_HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -I$(BUILD_DIR) $<

$(BUILD_DIR)/%.casm: $(BUILD_DIR)/%.cc1
	$(CC) -target=slurm16_ng -c $< -o $@

$(BUILD_DIR)/%.co : $(BUILD_DIR)/%.casm
	$(AS) -o $@ $<

$(BUILD_DIR)/%.asmo1 : $(BUILD_DIR)/%.asm11
	$(AS) -o $@ $<


