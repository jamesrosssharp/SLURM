
SRCDIR=../../src

SOURCE=$(SRCDIR)/pipeline16.v $(SRCDIR)/slurm16.v $(SRCDIR)/alu.v $(SRCDIR)/register_file.v $(SRCDIR)/memory_controller.v $(SRCDIR)/rom.v \
		$(SRCDIR)/uart.v $(SRCDIR)/uart_tx.v $(SRCDIR)/baudgen.v $(SRCDIR)/pwm_led.v $(SRCDIR)/gpio.v $(SRCDIR)/memory.v $(SRCDIR)/gfx.v

PROJECT=slurm16

all: sim

.PHONY: sim

rom_image.mem: Test.asm
	../../slurmasm/slurmasm Test.asm -o rom_image

sim: $(SOURCE) $(PROJECT)_tb.v rom_image.mem
	iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm rom_image
	rm rom_image.mem
