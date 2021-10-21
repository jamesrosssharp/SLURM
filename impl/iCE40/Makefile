PROJ 	= slurm16_ice40
PIN_DEF = slurm16_ice40.pcf
DEVICE 	= up5k

SRCDIR=../../src

AS=../../slurmasm/slurmasm

SOURCE = $(SRCDIR)/pipeline16.v $(SRCDIR)/slurm16.v $(SRCDIR)/alu.v $(SRCDIR)/register_file.v $(SRCDIR)/memory_controller.v \
		 $(SRCDIR)/uart.v $(SRCDIR)/uart_tx.v $(SRCDIR)/baudgen.v $(SRCDIR)/gpio.v pwm_led.v $(SRCDIR)/gfx.v  memory.v rom.v slurm16_ice40.v	\
		 $(SRCDIR)/pacman_sprite.v $(SRCDIR)/pacman_sprite_rom.v $(SRCDIR)/audio.v $(SRCDIR)/spi_flash.v \
		 $(SRCDIR)/sprite_controller.v $(SRCDIR)/bram.v $(SRCDIR)/gfx_memory_arbiter.v $(SRCDIR)/background_controller.v 

ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: $(PROJ).h

rom_image.mem: Bootloader.asm
	$(AS) Bootloader.asm -o rom_image

app_image: App.asm
	$(AS) App.asm -o app_image
	

rom.v: rom_image.mem
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
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).h rom_image* app_image*

.SECONDARY:
.PHONY: all prog clean
