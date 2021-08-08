
SRCDIR=../../../src/

SOURCE=$(SRCDIR)/pipeline16.v $(SRCDIR)/slurm16.v $(SRCDIR)/alu.v $(SRCDIR)/register_file.v $(SRCDIR)/register.v $(SRCDIR)/memory_controller.v $(SRCDIR)/memory.v $(SRCDIR)/rom.v
PROJECT=slurm16

all: sim

.PHONY: sim

rom_image.mem: Test.asm
	../../../slurmasm/slurmasm Test.asm -o rom_image

sim: $(SOURCE) $(PROJECT)_tb.v rom_image.mem
	iverilog -o $(PROJECT)_design -D SIM $(PROJECT)_tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   $(PROJECT).vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm $(PROJECT).vcd
