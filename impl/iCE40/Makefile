PROJ 	= slurm16_ice40
PIN_DEF = slurm16_ice40.pcf
DEVICE 	= up5k

SRCDIR=../../src

AS=../../slurmasm/slurmasm
CC=../../slurmcc/lcc/lcc/build/rcc

SOURCE=$(SRCDIR)/alpha.v	\
$(SRCDIR)/alu.v				\
$(SRCDIR)/audio.v			\
$(SRCDIR)/background_controller2.v	\
$(SRCDIR)/background_controller.v	\
$(SRCDIR)/baudgen.v					\
bram_mask.v				\
$(SRCDIR)/bram.v					\
$(SRCDIR)/copper.v					\
$(SRCDIR)/fb_doubler.v				\
$(SRCDIR)/fb_scale.v				\
$(SRCDIR)/gfx.v				\
$(SRCDIR)/gpio.v					\
$(SRCDIR)/memory_arbiter.v			\
$(SRCDIR)/memory_controller.v	\
memory.v				\
mult.v					\
$(SRCDIR)/port_controller.v			\
pwm_led.v					\
boot_memory.v						\
$(SRCDIR)/spi_flash.v				\
$(SRCDIR)/sprite_controller.v		\
trace.v					\
$(SRCDIR)/uart_tx.v					\
$(SRCDIR)/uart.v					\
$(SRCDIR)/cpu_hazard.v				\
$(SRCDIR)/cpu_pipeline.v			\
$(SRCDIR)/cpu_program_counter.v		\
$(SRCDIR)/cpu_top.v					\
$(SRCDIR)/cpu_decode.v				\
$(SRCDIR)/cpu_execute.v				\
$(SRCDIR)/cpu_memory_interface.v	\
$(SRCDIR)/cpu_port_interface.v		\
$(SRCDIR)/cpu_register_file.v		\
$(SRCDIR)/cpu_writeback.v			\
$(SRCDIR)/slurm16_soc.v				\
$(SRCDIR)/interrupt_controller.v	\
slurm16_ice40.v 

ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: $(PROJ).h

rom_image.mem: Bootloader.asm
	$(AS) Bootloader.asm -o rom_image
	python3 ../../scripts/genmem.py rom_image rom_image.mem

App.asm: main.c top.asm bottom.asm
	cpp main.c -o main.c1
	$(CC) -target=slurm16 -c main.c1 -o main.asm
	cat top.asm main.asm bottom.asm > App.asm


app_image: App.asm
	$(AS) App.asm -o app_image
	

boot_memory.v: rom_image.mem
	python3 ../../scripts/genrom.py

%.h: %.bin
	xxd -i $< > $@

$(PROJ).json: $(SOURCE) rom_image.mem
	yosys -p 'debug synth_ice40 -top top -json $@' $(SOURCE)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --freq 25.125 --up5k --json $(PROJ).json --pcf $(PROJ).pcf --asc $@

%.bin: %.asc
	$(ICEPACK) $< $@

%.rpt: %.asc
	$(ICETIME) -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin app_image
	$(ICEPROG) $(PROJ).bin
	$(ICEPROG) -o 1M  app_image 

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) -S $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).h rom_image* app_image* App.asm main.asm

.SECONDARY:
.PHONY: all prog clean
