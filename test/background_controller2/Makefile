
SRCDIR=../../src

SOURCE=$(SRCDIR)/background_controller2.v $(SRCDIR)/bram.v 

PROJECT=background_controller2

all: sim

.PHONY: sim

ram_image.mem: App.asm
	../../slurmasm/slurmasm App.asm -o ram_image

sim: $(SOURCE) $(PROJECT)_tb.v ram_image.mem
	iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
