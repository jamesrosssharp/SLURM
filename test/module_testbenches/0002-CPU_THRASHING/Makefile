
SRCDIR=../../../src

SOURCE= 	$(SRCDIR)/slurm16_cpu_pipeline.v	\
		$(SRCDIR)/cpu_memory_interface.v	\
		$(SRCDIR)/slurm16_cpu_top.v		\
		$(SRCDIR)/slurm16_cpu_decode.v		\
		$(SRCDIR)/slurm16_cpu_registers.v	\
		$(SRCDIR)/slurm16_cpu_execute.v		\
		$(SRCDIR)/slurm16_cpu_alu.v		\
		$(SRCDIR)/slurm16_cpu_writeback.v	\
		$(SRCDIR)/cpu_port_interface.v		\
		$(SRCDIR)/slurm16_cpu_hazard.v		\
		$(SRCDIR)/cpu_instruction_cache.v	\
		$(SRCDIR)/bram.v			\
		$(SRCDIR)/mult.v			\
		$(SRCDIR)/unsigned_mult.v	

MEMCONV=../../../scripts/genmem.py
 
PROJECT=cpu_thrash3

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
