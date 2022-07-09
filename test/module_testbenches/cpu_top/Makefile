
SRCDIR=../../../src

SOURCE= $(SRCDIR)/cpu_program_counter.v 	\
		$(SRCDIR)/cpu_pipeline.v	\
		$(SRCDIR)/cpu_memory_interface.v\
		$(SRCDIR)/cpu_top.v		\
		$(SRCDIR)/cpu_decode.v		\
		$(SRCDIR)/cpu_register_file.v	\
		$(SRCDIR)/cpu_execute.v		\
		$(SRCDIR)/alu.v			\
		$(SRCDIR)/cpu_writeback.v	\
		$(SRCDIR)/cpu_port_interface.v	\
		$(SRCDIR)/cpu_hazard.v		\
		$(SRCDIR)/cpu_instruction_cache.v	\
		$(SRCDIR)/bram.v			\
		$(SRCDIR)/mult.v	

MEMCONV=../../../scripts/genmem.py
 
PROJECT=cpu_top

all: sim

.PHONY: sim

ram_image.mem: App.asm
	../../../slurmasm/slurmasm App.asm -o ram_image
	python3 $(MEMCONV) ram_image ram_image.mem

sim: $(SOURCE) tb.v ram_image.mem
	iverilog -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm ram_image
	rm ram_image.mem
