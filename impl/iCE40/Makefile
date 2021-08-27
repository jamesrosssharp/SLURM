PROJ 	= slurm16_ice40
PIN_DEF = slurm16_ice40.pcf
DEVICE 	= up5k

SRCDIR=../../src

SOURCE = $(SRCDIR)/pipeline16.v $(SRCDIR)/slurm16.v $(SRCDIR)/alu.v $(SRCDIR)/register_file.v $(SRCDIR)/register.v $(SRCDIR)/memory_controller.v memory.v rom.v $(SRCDIR)/uart.v $(SRCDIR)/uart_tx.v $(SRCDIR)/baudgen.v $(SRCDIR)/gpio.v $(PROJ).v pwm_led.v 

ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

all: $(PROJ).h

rom_image.mem: Test.asm
	../../slurmasm/slurmasm Test.asm -o rom_image

rom.v: rom_image.mem
	python3 ../../scripts/genrom.py

%.h: %.bin
	xxd -i $< > $@

$(PROJ).json: $(SOURCE) rom_image.mem
	yosys -p 'debug synth_ice40 -top top -json $@' $(SOURCE)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --up5k --json $(PROJ).json --pcf $(PROJ).pcf --asc $@

%.bin: %.asc
	$(ICEPACK) $< $@

%.rpt: %.asc
	$(ICETIME) -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	$(ICEPROG) -S $<
	#$(ICEPROG) $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) -S $<

clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).h

.SECONDARY:
.PHONY: all prog clean
