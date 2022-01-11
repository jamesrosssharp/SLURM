
all: sim

.PHONY: sim

AS=../../../slurmasm/slurmasm

IVERILOG_RUN=@iverilog -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE) 2>&1 >sim_wrn.txt &&	\
			 vvp      -n $(PROJECT)_design 2>&1 >>sim_wrn.txt 
	
MEM_INIT=mem_init1.mem mem_init2.mem mem_init3.mem mem_init4.mem

rom_image.mem: Boot.asm
	$(AS) Boot.asm -o rom_image

%.mem: %.asm
	$(AS) $^ -o $(basename $@)


sim: $(SOURCE) tb.v rom_image.mem $(MEM_INIT)
	@rm -f simout.txt
	$(IVERILOG_RUN)
	@cat simout.txt
	@diff -q	simout.txt simout.correct || (echo "\n\n==============\nTEST FAILED :(\n==============\n\n"; exit 1)
	@echo "==============\nTEST PASSED!\n==============\n" 
	
dump.vcd: $(SOURCE) tb.v rom_image.mem $(MEM_INIT)
	$(IVERILOG_RUN)

view: dump.vcd config.gtkw
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
	rm rom_image
	rm rom_image.mem
	rm mem_init1
	rm mem_init1.mem
	rm mem_init2
	rm mem_init2.mem
	rm mem_init3
	rm mem_init3.mem
	rm mem_init4
	rm mem_init4.mem
	rm simout.txt
	rm sim_wrn.txt
