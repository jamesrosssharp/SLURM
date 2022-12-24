
SRCDIR=../../../src

SOURCE= $(SRCDIR)/mult.v			\
 $(SRCDIR)/slurm16_cpu_alu.v			\
 $(SRCDIR)/slurm16_cpu_decode.v			\
 $(SRCDIR)/slurm16_cpu_execute.v		\
 $(SRCDIR)/slurm16_cpu_hazard.v			\
 $(SRCDIR)/slurm16_cpu_pipeline.v		\
 $(SRCDIR)/slurm16_cpu_registers.v		\
 $(SRCDIR)/slurm16_cpu_writeback.v		\
 $(SRCDIR)/unsigned_mult.v
 
PROJECT=cpu_internals

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
