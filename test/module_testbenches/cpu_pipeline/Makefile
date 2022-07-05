
SRCDIR=../../../src

SOURCE=	$(SRCDIR)/cpu_memory_interface.v	\
       	$(SRCDIR)/cpu_instruction_cache.v	\
       	$(SRCDIR)/cpu_pipeline.v		\
	$(SRCDIR)/bram.v

MEMCONV=../../../scripts/genmem.py

PROJECT=cpu_mem_interface

all: sim

.PHONY: sim

ram_image.mem: App.asm
	../../../slurmasm/slurmasm App.asm -o ram_image
	python3 $(MEMCONV) ram_image ram_image.mem


sim: $(SOURCE) tb.v ram_image.mem
	iverilog -grelative-include -pfileline=1 -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
