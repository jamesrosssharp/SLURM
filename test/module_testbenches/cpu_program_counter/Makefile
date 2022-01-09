
SRCDIR=../../../src

SOURCE=$(SRCDIR)/cpu_program_counter.v
 
PROJECT=cpu_pc

all: sim

.PHONY: sim


sim: $(SOURCE) tb.v
	iverilog -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
