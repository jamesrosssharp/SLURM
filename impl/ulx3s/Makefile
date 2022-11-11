#
#
#	Makefile for SLURM16 on ulx3s board
#
#

VERILOG_FILES = slurm16_top.v

DVI_FILES := $(shell find -L dvi -name '*.v')
PLL_FILES := $(shell find -L pll -name '*.sv')
#UART_FILES := $(shell find -L uart -name '*.v')

SRCDIR=../../src

SOURCE=$(SRCDIR)/alpha.v		\
$(SRCDIR)/alu.v				\
$(SRCDIR)/audio.v			\
$(SRCDIR)/background_controller2.v	\
$(SRCDIR)/baudgen.v			\
$(SRCDIR)/bram_mask.v			\
$(SRCDIR)/bram.v			\
$(SRCDIR)/copper.v			\
$(SRCDIR)/gfx.v				\
$(SRCDIR)/gpio.v			\
$(SRCDIR)/memory_arbiter.v		\
$(SRCDIR)/memory_controller.v		\
$(SRCDIR)/memory.v			\
$(SRCDIR)/mult.v			\
$(SRCDIR)/unsigned_mult.v		\
$(SRCDIR)/port_controller.v		\
$(SRCDIR)/pwm_led.v			\
bootloader/boot_memory.v		\
$(SRCDIR)/spi_flash.v			\
$(SRCDIR)/sprite_controller.v		\
slurm16_support/trace.v			\
$(SRCDIR)/uart_tx.v			\
$(SRCDIR)/uart.v			\
$(SRCDIR)/cpu_hazard.v			\
$(SRCDIR)/cpu_pipeline.v		\
$(SRCDIR)/cpu_top.v			\
$(SRCDIR)/cpu_decode.v			\
$(SRCDIR)/cpu_execute.v			\
$(SRCDIR)/cpu_memory_interface.v	\
$(SRCDIR)/cpu_port_interface.v		\
$(SRCDIR)/cpu_register_file.v		\
$(SRCDIR)/cpu_writeback.v		\
$(SRCDIR)/slurm16_soc.v			\
$(SRCDIR)/interrupt_controller.v	\
$(SRCDIR)/cpu_instruction_cache.v	\
picorv32/picorv32-master/picorv32.v	

SLURM_FILES := $(SOURCE)

VERILOG_FILES += $(DVI_FILES) $(PLL_FILES) $(SLURM_FILES)

TOP_MODULE = slurm16_top

PROJECT = slurm16
BOARD = ulx3s

FPGA_PREFIX =
# 12, 25, 45, 85, um-85, um5g-85
FPGA_SIZE = 85
FPGA_CHIP := lfe5u-$(FPGA_SIZE)f
FPGA_PACKAGE = CABGA381
CONSTRAINTS = ulx3s_v316.lpf

FLASH_READ_MHZ = 62.0

FPGA_K = $(FPGA_PREFIX)$(FPGA_SIZE)
YOSYS = yosys
NEXTPNR-ECP5 = nextpnr-ecp5
ECPPACK = LANG=C ecppack
ECPPLL = LANG=C ecppll

UJPROG = fujprog

NEXTPNR_OPTIONS = 
YOSYS_OPTIONS = 

all: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit

# App

#GAME_BIN=../../games_n_demos/Mandelbrot/build/mandelbrot.bin
#GAME_BIN=../../games_n_demos/BloodLust/build/bloodlust.bin
#GAME_BIN=../../games_n_demos/PoCman/build/pocman.bin
#GAME_BIN=../../games_n_demos/ChipTuneMem/build/chiptune.bin
GAME_BIN=../../games_n_demos/DrumMachine/build/drummachine.bin


mem_init1.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init1 bs=1 count=32256 seek=512
	python3 ../../scripts/genmem.py mem_init1 mem_init1.mem

mem_init2.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init2 bs=1 count=32768 skip=32256
	python3 ../../scripts/genmem.py mem_init2 mem_init2.mem

mem_init3.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init3 bs=1 count=32768 skip=65024
	python3 ../../scripts/genmem.py mem_init3 mem_init3.mem

mem_init4.mem: $(GAME_BIN)
	dd if=$(GAME_BIN) of=mem_init4 bs=1 count=32768 skip=97792
	python3 ../../scripts/genmem.py mem_init4 mem_init4.mem

# Bootloader

bootloader/boot_memory.v: bootloader/Bootloader.asm
	make -C bootloader

# picorv32

picorv32/picorv32-master/picorv32.v: get_picorv32.sh
	./get_picorv32.sh 


# Yosys synth

$(PROJECT).json: $(VERILOG_FILES) mem_init1.mem mem_init2.mem mem_init3.mem mem_init4.mem
	$(YOSYS) \
	-p "read -sv $(VERILOG_FILES)" \
	-p "hierarchy -top $(TOP_MODULE)" \
	-p "synth_ecp5 $(YOSYS_OPTIONS) -json $(PROJECT).json"

# Nextpnr
$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config: $(PROJECT).json
	$(NEXTPNR-ECP5) $(NEXTPNR_OPTIONS) --$(FPGA_K)k --package $(FPGA_PACKAGE) \
		--json $(PROJECT).json --lpf $(CONSTRAINTS) --textcfg $@ 

# Pack bitstream

$(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config
	$(ECPPACK) --compress --freq $(FLASH_READ_MHZ) --input $< --bit $@

# Prog SRAM

prog: program
program: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(UJPROG) $<

# program FLASH over US1 port with ujprog (permanently)
flash: $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
	$(UJPROG) -j flash $<

# Clean

JUNK = *~
JUNK += $(PROJECT).json
JUNK += $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).config
JUNK += $(BOARD)_$(FPGA_SIZE)f_$(PROJECT).bit
JUNK += mem_init* 
JUNK += picorv32

clean:
	rm -rf $(JUNK)
	

