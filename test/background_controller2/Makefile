
SRCDIR=../../src

SOURCE=$(SRCDIR)/background_controller2.v $(SRCDIR)/bram.v 

PROJECT=background_controller2

all: sim

.PHONY: sim

sim: $(SOURCE) $(PROJECT)_tb.v
	iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   $(PROJECT).vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm $(PROJECT).vcd
	rm rom_image
	rm rom_image.mem
