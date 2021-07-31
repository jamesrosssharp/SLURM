
SOURCE=../../src/pipeline16.v ../../src/slurm16.v ../../src/alu.v ../../src/register_file.v ../../src/register.v ../../src/memory_controller.v ../../src/memory.v ../../src/rom.v
PROJECT=slurm16

all: sim

.PHONY: sim

sim: $(SOURCE) $(PROJECT)_tb.v
	iverilog -o $(PROJECT)_design -D SIM $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   $(PROJECT).vcd config.gtkw 
