
SLURMOS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

$(info SlurmOS is in $(SLURMOS_DIR))

SLURMOS_SRC	= $(wildcard $(SLURMOS_DIR)/*.c)
SLURMOS_ASM_SRC	= $(wildcard $(SLURMOS_DIR)/*.asm)
SLURMOS_HEADERS	= $(wildcard $(SLURMOS_DIR)/*.h)

SLURMOS_CPP_SRC   = $(patsubst %.c,$(BUILD_DIR)/%.c1,$(notdir $(SLURMOS_SRC)))
SLURMOS_C_ASM_SRC = $(patsubst %.c1,%.asm,$(SLURMOS_CPP_SRC))
SLURM_OS_C_OBJ    = $(patsubst %.asm,%.o,$(SLURMOS_C_ASM_SRC))

SLURMOS_CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm1,$(notdir $(SLURMOS_ASM_SRC)))
SLURMOS_ASM_OBJ = $(patsubst %.asm1,$(BUILD_DIR)/%.asmo,$(notdir $(SLURMOS_CPP_ASM)))

SLURMOS_OBJ = $(SLURM_OS_C_OBJ) $(SLURMOS_ASM_OBJ)

$(BUILD_DIR)/%.c1: $(SLURMOS_DIR)/%.c $(ASSETS_H) $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -I$(SLURMOS_DIR) -I$(BUILD_DIR) $<

$(BUILD_DIR)/%.asm1: $(SLURMOS_DIR)/%.asm $(SLURMOS_HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../include -I$(BUILD_DIR) $<

$(BUILD_DIR)/%.asm: $(BUILD_DIR)/%.c1
	$(CC) -target=slurm16_ng -c $< -o $@


