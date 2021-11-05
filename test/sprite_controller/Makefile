
SRCDIR=../../src

SOURCE=$(SRCDIR)/sprite_controller.v $(SRCDIR)/bram.v $(SRCDIR)/bram_mask.v 
 

PROJECT=sprite_test

all: sim

.PHONY: sim

sim: $(SOURCE) $(PROJECT)_tb.v
	iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm rom_image
	rm rom_image.mem
