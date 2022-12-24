
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

all: sim

.PHONY: sim

sim: $(SOURCE) tb.sv 
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
