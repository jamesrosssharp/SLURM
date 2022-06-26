
SRCDIR=../../../src

SOURCE= $(SRCDIR)/cpu_instruction_cache.v	\
        $(SRCDIR)/bram.v	

 
PROJECT=cpu_top

all: sim

.PHONY: sim

ram_image.mem: App.asm
	../../../slurmasm/slurmasm App.asm -o ram_image

sim: $(SOURCE) tb.v ram_image.mem
	iverilog -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm ram_image
	rm ram_image.mem
