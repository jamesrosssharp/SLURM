
include ../../../../common/slurmos/slurmos.mk

# The toolchain (clang, slurmasm-ng, slurmlink) is set up by
# common/clang.mk, included from slurmos.mk above.


SRC_DIR = ./
C_SRC	= $(wildcard $(SRC_DIR)/*.c)
ASM_SRC	= $(wildcard $(SRC_DIR)/*.asm)
HEADERS	= $(wildcard $(SRC_DIR)/*.h)

C_OBJ = $(patsubst %.c,$(BUILD_DIR)/%.o,$(notdir $(C_SRC)))

CPP_ASM = $(patsubst %.asm,$(BUILD_DIR)/%.asm1,$(notdir $(ASM_SRC)))
ASM_OBJ = $(patsubst %.asm1,$(BUILD_DIR)/%.asmo,$(notdir $(CPP_ASM)))

BUILD_DIR=build

TARGET=$(BUILD_DIR)/effect5.bin
LINKER_SCRIPT=$(SRC_DIR)/link.ld

TARGET_ELF=$(patsubst %.bin, %.elf, $(TARGET))

.PRECIOUS: $(CPP_ASM)

all: $(TARGET)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(ASSETS_H) $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -I../../../../include -I$(SRC_DIR) -I../ -I$(BUILD_DIR) -I../../build -I$(SLURMOS_DIR) -c -o $@ $<

$(BUILD_DIR)/%.asm1: $(SRC_DIR)/%.asm $(HEADERS)
	mkdir -p $(BUILD_DIR)
	$(CPP) -o $@ -I../../../../include -I$(BUILD_DIR) -I$(SLURMOS_DIR) $<

$(BUILD_DIR)/%.asmo : $(BUILD_DIR)/%.asm1
	$(AS) -o $@ $<

$(TARGET_ELF): $(C_OBJ) $(ASM_OBJ) $(LINKER_SCRIPT)
	$(LD) -s $(LINKER_SCRIPT) -o $@ $(ASM_OBJ) $(C_OBJ) $(CLANG_RT_OBJS)

$(TARGET): $(TARGET_ELF) $(BUNDLE)
	$(OBJCOPY) $< $@

clean:
	rm -r build

