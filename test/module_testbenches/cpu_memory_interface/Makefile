
SRCDIR=../../../src

SOURCE=$(SRCDIR)/cpu_memory_interface.v
 
PROJECT=cpu_mem_interface

all: sim

.PHONY: sim


sim: $(SOURCE) tb.v
	iverilog -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
