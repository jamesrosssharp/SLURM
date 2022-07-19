
SRCDIR=../../../src

SOURCE= $(SRCDIR)/alu.v	\
	$(SRCDIR)/mult.v

 
PROJECT=alu

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
