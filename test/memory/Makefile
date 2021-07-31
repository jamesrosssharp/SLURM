
SOURCE=../../src/memory_controller.v ../../src/memory.v ../../src/rom.v
PROJECT=memory

all: sim

.PHONY: sim

sim: $(SOURCE) $(PROJECT)_tb.v
	iverilog -o $(PROJECT)_design -D SIM $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   $(PROJECT).vcd config.gtkw 
