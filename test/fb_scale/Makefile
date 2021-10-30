
SRCDIR=../../src

SOURCE=$(SRCDIR)/fb_scale.v $(SRCDIR)/bram.v 

PROJECT=fb_scale

all: sim

.PHONY: sim

ram_image.mem: App.asm
	../../slurmasm/slurmasm App.asm -o ram_image

sim: $(SOURCE) $(PROJECT)_tb.v ram_image.mem
	iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   $(PROJECT).vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
