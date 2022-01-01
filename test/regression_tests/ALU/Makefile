
SRCDIR=../../../src

include ../../common/slurmsrc.mk

PROJECT=alu

all: sim

.PHONY: sim

AS=../../../slurmasm/slurmasm

IVERILOG_RUN=@iverilog -o $(PROJECT)_design -D SIM -Winfloop $(PROJECT)_tb.v $(SOURCE) 2>&1 >sim_wrn.txt &&	\
			 vvp      -n $(PROJECT)_design 2>&1 >>sim_wrn.txt 
	


rom_image.mem: Boot.asm
	$(AS) Boot.asm -o rom_image

mem_init2.mem: App.asm
	$(AS) App.asm -o mem_init2

sim: $(SOURCE) $(PROJECT)_tb.v rom_image.mem mem_init2.mem
	@rm -f simout.txt
	$(IVERILOG_RUN)
	@cat simout.txt
	@diff -q	simout.txt simout.correct || (echo "\n\n==============\nTEST FAILED :(\n==============\n\n"; exit 1)
	@echo "==============\nTEST PASSED!\n==============\n" 
	
dump.vcd: $(SOURCE) $(PROJECT)_tb.v rom_image.mem mem_init2.mem
	$(IVERILOG_RUN)

view: dump.vcd config.gtkw
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm rom_image
	rm rom_image.mem
	rm mem_init2
	rm mem_init2.mem
	rm simout.txt
	rm sim_wrn.txt
