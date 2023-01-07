
SRCDIR=../../../src

SOURCE= $(SRCDIR)/slurm16_memory_arbiter.v		\
 $(SRCDIR)/slurm16_peripheral_memory_arbiter.v
 
PROJECT=memory_arbiter

MEMCONV=../../../scripts/genmem.py

all: sim

.PHONY: sim

ram_image.mem: App.asm
	../../../slurmasm/slurmasm App.asm -o ram_image
	python3 $(MEMCONV) ram_image ram_image.mem

sim: $(SOURCE) tb.sv ram_image.mem 
	iverilog  -g2012 -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.sv $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

sim-no-assert: $(SOURCE) tb.sv 
	iverilog -gno-assertions -g2012 -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.sv $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 



clean: 
	rm $(PROJECT)_design
	rm dump.vcd
