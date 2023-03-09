PROJ 	= slurm16_ice40
PIN_DEF = slurm16_ice40.pcf
DEVICE 	= up5k

SRCDIR=../../src

AS=../../slurmasm/slurmasm
CC=../../slurmcc/lcc/lcc/build/rcc

SOURCE=$(SRCDIR)/alpha.v		\
$(SRCDIR)/slurm16_cpu_alu.v				\
$(SRCDIR)/audio.v			\
$(SRCDIR)/background_controller2.v	\
$(SRCDIR)/baudgen.v			\
bram_mask.v				\
$(SRCDIR)/bram.v			\
$(SRCDIR)/copper.v			\
$(SRCDIR)/gfx.v				\
$(SRCDIR)/gpio.v			\
$(SRCDIR)/slurm16_memory_arbiter.v		\
$(SRCDIR)/slurm16_peripheral_memory_arbiter.v		\
$(SRCDIR)/slurm16_memory_controller.v		\
memory.v				\
mult.v					\
unsigned_mult.v				\
pwm_led.v				\
boot_memory.v				\
$(SRCDIR)/spi_flash.v			\
$(SRCDIR)/sprite_controller.v		\
trace.v					\
$(SRCDIR)/uart_tx.v			\
$(SRCDIR)/uart.v			\
$(SRCDIR)/slurm16_cpu_hazard.v			\
$(SRCDIR)/slurm16_cpu_pipeline.v		\
$(SRCDIR)/slurm16_cpu_top.v			\
$(SRCDIR)/slurm16_cpu_decode.v			\
$(SRCDIR)/slurm16_cpu_execute.v			\
$(SRCDIR)/slurm16_cpu_memory_interface.v	\
$(SRCDIR)/cpu_port_interface.v		\
$(SRCDIR)/slurm16_cpu_registers.v		\
$(SRCDIR)/slurm16_cpu_writeback.v		\
$(SRCDIR)/slurm16_soc.v			\
$(SRCDIR)/interrupt_controller.v	\
$(SRCDIR)/slurm16_cpu_instruction_cache.v	\
$(SRCDIR)/port_controller.v		\
$(SRCDIR)/cpu_debug_core.v		\
slurm16_ice40.v 





ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: $(PROJ).h

BLOODLUST_BIN=../../games_n_demos/BloodLust/build/bloodlust.bin
POCMAN_BIN=../../games_n_demos/PoCman/build/pocman.bin
SIEVE_BIN=../../games_n_demos/Sieve/build/sieve.bin
MANDEL_BIN=../../games_n_demos/Mandelbrot/build/mandelbrot.bin
CAPTOR_BIN=../../games_n_demos/Captor/build/captor.bin
CHIPTUNE_BIN=../../games_n_demos/ChipTune/build/chiptune.bin
CHIPTUNEMEM_BIN=../../games_n_demos/ChipTuneMem/build/chiptunemem.bin
DRUM_BIN=../../games_n_demos/DrumMachine/build/drummachine.bin
JPTA_BIN=../../games_n_demos/JPTA/build/jpta.bin
DEMO_BIN=../../games_n_demos/SlurmDemo/build/slurm_demo.bin

GAME_BIN=$(DEMO_BIN)

#BOOTLOADER_ASM=../../games_n_demos/bootloader/src/Bootloader.asm
BOOTLOADER_ASM=Bootloader.asm

rom_image.mem: $(BOOTLOADER_ASM) 
	$(AS) $(BOOTLOADER_ASM) -o rom_image
	python3 ../../scripts/genmem.py rom_image rom_image.mem

App.asm: main.c top.asm bottom.asm
	cpp main.c -o main.c1
	$(CC) -target=slurm16 -c main.c1 -o main.asm
	cat top.asm main.asm bottom.asm > App.asm


#app_image: App.asm
#	$(AS) App.asm -o app_image

app_image: $(GAME_BIN)
	cp $(GAME_BIN) app_image


boot_memory.v: rom_image.mem
	python3 ../../scripts/genrom.py

%.h: %.bin
	xxd -i $< > $@

$(PROJ).json: $(SOURCE) rom_image.mem
	yosys -p 'debug synth_ice40 -top top -json $@' $(SOURCE)

#.PHONY: SCC
#SCC:	$(SOURCE) rom_image.mem
#	yosys -p 'synth_ice40 -top top -json $(PROJ).json; scc' $(SOURCE)



%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --randomize-seed --freq 25.125 --up5k --json $(PROJ).json --pcf $(PROJ).pcf --asc $@

%.bin: %.asc
	$(ICEPACK) $< $@

%.rpt: %.asc
	$(ICETIME) -d $(DEVICE) -mtr $@ $<

.PHONY: bloodlust
bloodlust: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(BLOODLUST_BIN) 

.PHONY: pocman
pocman: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(POCMAN_BIN) 

.PHONY: sieve
sieve: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(SIEVE_BIN) 

.PHONY: mandel
mandel: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(MANDEL_BIN) 

.PHONY: captor
captor: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(CAPTOR_BIN) 

.PHONY: chiptune
chiptune: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(CHIPTUNE_BIN) 

.PHONY: chiptunemem
chiptunemem: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(CHIPTUNEMEM_BIN) 

.PHONY: drum
drum: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(DRUM_BIN) 

.PHONY: jpta
jpta: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(JPTA_BIN) 

.PHONY: demo
demo: $(PROJ).bin
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  $(DEMO_BIN) 



prog: $(PROJ).bin app_image
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  app_image 

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) -S $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).h rom_image* app_image* App.asm main.asm main.c1

.SECONDARY:
.PHONY: all prog clean
